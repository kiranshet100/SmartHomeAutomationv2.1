import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/database_service.dart';
import '../firebase_options.dart';
import '../models/scene_model.dart' as app_scene;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // AUTH FIX: Ensure we are authenticated in the background isolate
    // Otherwise Database rules might block us
    try {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null) {
            print('Background Service: Signing in anonymously...');
            await auth.signInAnonymously();
        }
        print('Background Service: User is ${auth.currentUser?.uid}');
    } catch (e) {
        print('Background Service Auth Error: $e');
    }
  } catch (e) {
    print('Firebase initialization error in background service: $e');
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Initialize Notifications
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // CRITICAL FIX: Create the Notification Channel explicitly for Foreground Service
  // This prevents "Bad notification for startForeground" crash
  final platform = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await platform?.createNotificationChannel(const AndroidNotificationChannel(
    'my_foreground',
    'Smart Home Service',
    importance: Importance.low, 
  ));

  // Start the actual automation monitoring
  startWebAutomationService();
}


/// Call this method from main.dart if running on Web to enable automations
void startWebAutomationService() {
  print('Starting Automation Service...');
  final databaseService = DatabaseService();
  final dbRef = FirebaseDatabase.instance.ref();

  // State to hold active automations
  List<app_scene.Scene> activeScenes = [];
  List<StreamSubscription> sensorSubscriptions = [];

  // State to hold activity
  final Map<String, DateTime> _lastSceneTriggerTime = {};
  final Map<String, bool> _lastSensorState = {};

  // 1. periodic Timer for TIME-based automations
  Timer.periodic(const Duration(seconds: 10), (timer) {
    print('--- BG Service Heartbeat ---');
    print('Active Scenes: ${activeScenes.length}');
    for (var s in activeScenes) {
      if (s.trigger != null && s.trigger!['type'] == 'sensor') {
        print('  [Sensor Scene] "${s.name}" Trigger: ${s.trigger} | Actions: ${s.actions.keys}');
      }
    }
    print('----------------------------');

    final now = DateTime.now();
    for (final scene in activeScenes) {
      if (scene.trigger != null && scene.trigger!['type'] == 'time') {
        try {
          final timeParts = scene.trigger!['time'].split(':');
          final scheduleTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );

          if (scheduleTime.hour == now.hour &&
              scheduleTime.minute == now.minute) {
             
             // Check if already triggered this minute
             final lastTrigger = _lastSceneTriggerTime[scene.id];
             if (lastTrigger != null && 
                 lastTrigger.year == now.year &&
                 lastTrigger.month == now.month &&
                 lastTrigger.day == now.day &&
                 lastTrigger.hour == now.hour &&
                 lastTrigger.minute == now.minute) {
               // Already triggered this minute, skip
               continue;
             }

             // Mark as triggered and execute
             _lastSceneTriggerTime[scene.id] = now;
             _activateScene(scene, dbRef);
          }
        } catch (e) {
          print('Error parsing time for scene ${scene.name}: $e');
        }
      }
    }
  });

  // 2. Listen for Scene Changes (Dynamic Updates)
  databaseService.getScenes().listen((scenes) {
    print('Automation Service: Updated scenes list. Count: ${scenes.length}');
    activeScenes = scenes;
    for (var s in scenes) {
        if (s.trigger != null) {
            print('Scene: ${s.name}, Trigger: ${s.trigger}');
        }
    }

    // Cleanup old sensor subscriptions
    for (final sub in sensorSubscriptions) {
      sub.cancel();
    }
    sensorSubscriptions.clear();

    // Setup new sensor subscriptions
    for (final scene in scenes) {
      if (scene.trigger != null && scene.trigger!['type'] == 'sensor') {
        _setupSensorTrigger(scene, dbRef, sensorSubscriptions, _lastSensorState);
      }
    }
  });
}

void _setupSensorTrigger(
    app_scene.Scene scene,
    DatabaseReference dbRef,
    List<StreamSubscription> subscriptions,
    Map<String, bool> lastSensorState,
) {
  try {
    final sensorId = scene.trigger!['sensorId'];
    final condition = scene.trigger!['condition'];
    final thresholdValue = double.tryParse(scene.trigger!['value'].toString()) ?? 0.0;

    // Extract sensor key
    String sensorKey = sensorId.toString();
    if (sensorKey.contains('-')) {
      sensorKey = sensorKey.split('-').last;
    }
    
    // FIX: Remap legacy/incorrect keys
    if (sensorKey.toLowerCase() == 'gaslevel') sensorKey = 'gas';
    if (sensorKey.toLowerCase() == 'motiondetected') sensorKey = 'motion';
    if (sensorKey.toLowerCase() == 'temp') sensorKey = 'temperature';

    // Listen to the specific sensor
    print('DEBUG: Setup Listener. Scene: "${scene.name}". FullID: "$sensorId" -> Key: "$sensorKey". Condition: $condition $thresholdValue');
    final sensorRef = dbRef.child('devices/esp32_device_01/sensors/$sensorKey');
    
    final subscription = sensorRef.onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        final sensorValue = double.tryParse(value.toString()) ?? 0.0;
        bool conditionMet = false;

        if (condition == '>') {
          conditionMet = sensorValue > thresholdValue;
        } else if (condition == '<') {
          conditionMet = sensorValue < thresholdValue;
        } else if (condition == '=') {
          conditionMet = sensorValue == thresholdValue;
        } else if (condition == '>=') {
           conditionMet = sensorValue >= thresholdValue;
        } else if (condition == '<=') {
           conditionMet = sensorValue <= thresholdValue;
        }
        
        final previousState = lastSensorState[scene.id];
        
        print('DEBUG: ${scene.name} [$sensorKey=$sensorValue]. Met: $conditionMet. Prev: $previousState');

         if (conditionMet) {
           // Fire if:
           // 1. Uninitialized (startup) -> Fire if it's a notification (User wants to know immediate danger)
           // 2. Transition from FALSE -> TRUE (Edge trigger)
           // 3. User explicit "notify" action -> We bias towards showing it.

           final isStartup = previousState == null;
           final isEdge = previousState == false;
           
           if (isStartup || isEdge) {
              if (isStartup) {
                 // Startup: ONLY Notify. Do NOT toggle devices.
                 if (scene.actions.containsKey('notify')) {
                     print('TRIGGER FIRE (Startup): ${scene.name} - Notifications Only');
                     _activateScene(scene, dbRef, onlyNotify: true);
                 } else {
                     print('Suppressing startup control for: ${scene.name}');
                 }
              } else {
                 // Edge (Normal): Do everything
                 print('TRIGGER FIRE (Edge): ${scene.name}');
                 _activateScene(scene, dbRef, onlyNotify: false);
              }
           }
         }
         
         lastSensorState[scene.id] = conditionMet;
      }
    });

    subscriptions.add(subscription);
  } catch (e) {
    print('Error setting up sensor trigger for ${scene.name}: $e');
  }
}

void _activateScene(app_scene.Scene scene, DatabaseReference dbRef, {bool onlyNotify = false}) async {
  print('Activating scene: ${scene.name} (onlyNotify: $onlyNotify)');
  
  // Execute device actions ONLY if not in "onlyNotify" mode (Startup)
  if (!onlyNotify) {
    for (final fullDeviceId in scene.devices) {
      // Extract relay ID from full device ID (e.g., "esp32_device_01-relay1" -> "relay1")
      String relayId = fullDeviceId.contains('-') ? fullDeviceId.split('-').last : fullDeviceId;
      relayId = relayId.trim(); // Ensure no whitespace

      print('DEBUG: FullID: "$fullDeviceId" -> Extracted RelayID: "$relayId"');
      
      if (scene.actions['turn_on'] == true) {
        print('DEBUG: Setting relays/$relayId to 1');
        await dbRef.child('devices/esp32_device_01/relays/$relayId').set(1);
      } else if (scene.actions['turn_off'] == true) {
        print('DEBUG: Setting relays/$relayId to 0');
        await dbRef.child('devices/esp32_device_01/relays/$relayId').set(0);
      }
    }
  } else {
    print('Skipping Device Control actions due to Startup/onlyNotify mode.');
  }

  // Handle Notification Action - ALWAYS do this
  if (scene.actions.containsKey('notify')) {
    final message = scene.actions['notify'];
    print('DEBUG: ACTUALLY SHOWING NOTIFICATION for ${scene.name}: $message');
    
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smart_home_alerts', 
      'Emergency & Custom Alerts',
      channelDescription: 'Important notifications for gas, fire, and custom triggers',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true, // Attempt to be very intrusive as requested
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Alert: ${scene.name}',
      message.toString(),
      platformChannelSpecifics,
    );
  } else {
    print('DEBUG: No "notify" action found in ${scene.name}');
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  
  // CRITICAL FIX: Create Channel BEFORE service starts
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
  );
  
  final platform = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await platform?.createNotificationChannel(const AndroidNotificationChannel(
    'my_foreground',
    'Smart Home Service',
    description: 'Smart Home Background Service', 
    importance: Importance.low, 
  ));

  await platform?.createNotificationChannel(const AndroidNotificationChannel(
    'smart_home_alerts',
    'Emergency & Custom Alerts',
    description: 'Important notifications for gas, fire, and custom triggers',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  ));

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'my_foreground', // Must match above
      initialNotificationTitle: 'Smart Home Service',
      initialNotificationContent: 'Monitoring automations...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
      autoStart: true,
    ),
  );
  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
