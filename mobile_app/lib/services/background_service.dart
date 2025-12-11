import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/scene_model.dart' as app_scene;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await Firebase.initializeApp();

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

  final databaseService = DatabaseService();
  final scenes = await databaseService.getScenes().first;

  for (final scene in scenes) {
    if (scene.trigger != null) {
      if (scene.trigger!['type'] == 'time') {
        Timer.periodic(const Duration(minutes: 1), (timer) async {
          final now = DateTime.now();
          final scheduleTime = TimeOfDay(
            hour: int.parse(scene.trigger!['time'].split(':')[0]),
            minute: int.parse(scene.trigger!['time'].split(':')[1]),
          );

          if (scheduleTime.hour == now.hour && scheduleTime.minute == now.minute) {
            _activateScene(scene);
          }
        });
      } else if (scene.trigger!['type'] == 'sensor') {
        final sensorId = scene.trigger!['sensorId'];
        final condition = scene.trigger!['condition'];
        final value = scene.trigger!['value'];

        final sensorRef = FirebaseDatabase.instance.ref('devices/esp32_device_01/sensors/$sensorId');
        sensorRef.onValue.listen((event) {
          final sensorValue = (event.snapshot.value as num).toDouble();
          bool conditionMet = false;
          if (condition == '>') {
            conditionMet = sensorValue > value;
          } else if (condition == '<') {
            conditionMet = sensorValue < value;
          }
          else if (condition == '=') {
            conditionMet = sensorValue == value;
          }

          if (conditionMet) {
            _activateScene(scene);
          }
        });
      }
    }
  }
  // Hardcoded Automation Rules
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final dbRef = FirebaseDatabase.instance.ref();
  
  // State tracking to prevent redundant writes and glitches
  int? _lastFanState;
  int? _lastLightState;
  DateTime _lastGasAlertTime = DateTime.fromMillisecondsSinceEpoch(0);

  // 1. Gas Leak Alert (Gas >= 30)
  dbRef.child('devices/esp32_device_01/sensors/gas').onValue.listen((event) {
    final value = event.snapshot.value;
    if (value != null) {
      final gasLevel = double.tryParse(value.toString()) ?? 0.0;
      if (gasLevel >= 30) {
        // Cooldown check (reduced to 5 seconds for testing)
        if (DateTime.now().difference(_lastGasAlertTime).inSeconds >= 5) {
          _lastGasAlertTime = DateTime.now();
          flutterLocalNotificationsPlugin.show(
            888,
            '🚨 Gas Leak Alert!',
            'Gas level is high: $gasLevel. Please check immediately!',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'gas_alert_channel',
                'Gas Alerts',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
            ),
          );
        }
      }
    }
  });

  // 2. Temperature -> Fan (Temp >= 2) -> relay2
  dbRef.child('devices/esp32_device_01/sensors/temperature').onValue.listen((event) {
    final value = event.snapshot.value;
    if (value != null) {
      final temp = double.tryParse(value.toString()) ?? 0.0;
      
      int targetState = _lastFanState ?? 0;
      // User requested: >= 2 turns ON fan
      if (temp >= 2) {
        targetState = 1;
      } else {
        targetState = 0;
      }

      // Only write to Firebase if the state actually changes
      if (targetState != _lastFanState) {
        _lastFanState = targetState;
        // Corrected path: relay2 is the Fan
        dbRef.child('devices/esp32_device_01/relays/relay2').set(targetState);
      }
    }
  });

  // 3. Motion -> Light (Motion detected) -> relay4
  dbRef.child('devices/esp32_device_01/sensors/motion').onValue.listen((event) {
    final value = event.snapshot.value;
    if (value != null) {
      final motion = double.tryParse(value.toString()) ?? 0.0;
      int targetState = (motion == 1) ? 1 : 0;

      // Only write to Firebase if the state actually changes
      if (targetState != _lastLightState) {
        _lastLightState = targetState;
        // Corrected path: relay4 is the Light
        dbRef.child('devices/esp32_device_01/relays/relay4').set(targetState);
      }
    }
  });
}

void _activateScene(app_scene.Scene scene) async {
  final dbRef = FirebaseDatabase.instance.ref();
  for (final deviceName in scene.devices) {
    final relayId = deviceName;
    if (scene.actions['turn_on'] == true) {
      await dbRef.child('devices/esp32_device_01/relays/$relayId').set(1);
    } else if (scene.actions['turn_off'] == true) {
      await dbRef.child('devices/esp32_device_01/relays/$relayId').set(0);
    }
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
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
