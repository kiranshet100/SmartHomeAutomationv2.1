import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../providers/device_provider.dart';
import '../models/device_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final StreamController<Map<String, dynamic>> _alertController =
      StreamController<Map<String, dynamic>>.broadcast();
  DeviceProvider? _deviceProvider;

  // Track dismissed alerts to avoid showing them again
  final Set<String> _dismissedAlerts = {};
  // Track last alert times to avoid spam
  final Map<String, DateTime> _lastAlertTimes = {};
  static const Duration _alertCooldown = Duration(minutes: 5);

  Stream<Map<String, dynamic>> get alertStream => _alertController.stream;

  NotificationService._internal() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  Future<void> initialize(DeviceProvider deviceProvider) async {
    _deviceProvider = deviceProvider;
    // Request notification permissions
    await _requestPermissions();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Start monitoring for alerts
    _startAlertMonitoring();
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smart_home_channel',
      'Smart Home Alerts',
      channelDescription: 'Notifications for smart home alerts and updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _startAlertMonitoring() {
    // Start periodic checks for alerts based on DeviceProvider data
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_deviceProvider != null && !_deviceProvider!.isLoading) {
        _checkForAlerts(_deviceProvider!.devices);
      }
    });
  }

  bool _canShowAlert(String alertKey) {
    if (_dismissedAlerts.contains(alertKey)) {
      return false;
    }
    final lastTime = _lastAlertTimes[alertKey];
    if (lastTime != null &&
        DateTime.now().difference(lastTime) < _alertCooldown) {
      return false;
    }
    return true;
  }

  void _handleAlert(Map<String, dynamic> alert) {
    final type = alert['type'];
    final alertKey = '${type}_${alert['location'] ?? 'unknown'}';

    if (!_canShowAlert(alertKey)) {
      return;
    }

    _lastAlertTimes[alertKey] = DateTime.now();

    final message = alert['message'];
    final severity = alert['severity'] ?? 'medium';

    String title;
    Color color;

    switch (type) {
      case 'gas_leak':
        title = '🚨 Gas Leak Alert!';
        color = Colors.red;
        break;
      case 'security':
        title = '🔒 Security Alert';
        color = Colors.orange;
        break;
      case 'fire':
        title = '🔥 Fire Alert!';
        color = Colors.red;
        break;
      case 'temperature_high':
        title = '🌡️ High Temperature';
        color = Colors.deepOrange;
        break;
      case 'temperature_low':
        title = '❄️ Low Temperature';
        color = Colors.blue;
        break;
      case 'humidity_high':
        title = '💧 High Humidity';
        color = Colors.teal;
        break;
      case 'device_offline':
        title = '📴 Device Offline';
        color = Colors.grey;
        break;
      case 'energy_high':
        title = '⚡ High Energy Usage';
        color = Colors.amber;
        break;
      case 'door_open':
        title = '🚪 Door Open';
        color = Colors.purple;
        break;
      case 'window_open':
        title = '🪟 Window Open';
        color = Colors.indigo;
        break;
      default:
        title = 'Smart Home Alert';
        color = Colors.grey;
    }

    // Show notification
    showNotification(
      title: title,
      body: message,
      payload: type,
      importance: severity == 'high' ? Importance.max : Importance.high,
      priority: severity == 'high' ? Priority.max : Priority.high,
    );

    // Add to alert stream for UI updates
    _alertController.add({
      ...alert,
      'id': alertKey,
      'title': title,
      'color': color,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Dismiss an alert by its ID
  void dismissAlert(String alertId) {
    _dismissedAlerts.add(alertId);
    // Send a null/empty alert to clear the UI
    _alertController.add({'dismissed': true, 'id': alertId});
  }

  /// Clear all dismissed alerts (allows them to show again)
  void clearDismissedAlerts() {
    _dismissedAlerts.clear();
  }

  void _checkForAlerts(List<Device> devices) {
    final sensors = devices.where((d) => d.type == 'sensor').toList();

    for (final sensor in sensors) {
      switch (sensor.name.toLowerCase()) {
        case 'gaslevel':
          final value = sensor.properties['value'] ?? 0;
          if (value >= 30.0) {
            _handleAlert({
              'type': 'gas_leak',
              'message':
                  'Gas leak detected! Level: ${value.toStringAsFixed(1)} ppm',
              'severity': 'high',
              'location': sensor.room,
            });
          }
          break;

        case 'motiondetected':
          if ((sensor.properties['value'] ?? 0) == 1.0) {
            _handleAlert({
              'type': 'security',
              'message': 'Motion detected in ${sensor.room}',
              'severity': 'medium',
              'location': sensor.room,
            });
          }
          break;

        case 'temperature':
          final temp = sensor.properties['value'] ?? 0;
          if (temp > 35.0) {
            _handleAlert({
              'type': 'temperature_high',
              'message':
                  'High temperature: ${temp.toStringAsFixed(1)}°C in ${sensor.room}',
              'severity': 'medium',
              'location': sensor.room,
            });
          } else if (temp < 10.0) {
            _handleAlert({
              'type': 'temperature_low',
              'message':
                  'Low temperature: ${temp.toStringAsFixed(1)}°C in ${sensor.room}',
              'severity': 'low',
              'location': sensor.room,
            });
          }
          break;

        case 'humidity':
          final humidity = sensor.properties['value'] ?? 0;
          if (humidity > 80.0) {
            _handleAlert({
              'type': 'humidity_high',
              'message':
                  'High humidity: ${humidity.toStringAsFixed(1)}% in ${sensor.room}',
              'severity': 'low',
              'location': sensor.room,
            });
          }
          break;
      }
    }

    // Check for offline devices
    for (final device in devices) {
      if (!device.isOnline && device.type == 'relay') {
        _handleAlert({
          'type': 'device_offline',
          'message': '${device.name} is offline',
          'severity': 'low',
          'location': device.room,
        });
      }
    }
  }

  // Specific alert methods
  Future<void> sendGasLeakAlert(double level, String location) async {
    await showNotification(
      title: '🚨 Gas Leak Emergency!',
      body:
          'Gas leak detected! Level: ${level.toStringAsFixed(1)} ppm at $location. Please evacuate immediately!',
      payload: 'gas_leak',
      importance: Importance.max,
      priority: Priority.max,
    );
  }

  Future<void> sendSecurityAlert(String message, String location) async {
    await showNotification(
      title: '🔒 Security Alert',
      body: '$message at $location',
      payload: 'security',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  Future<void> sendDeviceAlert(
      String deviceName, String status, String room) async {
    await showNotification(
      title: '📱 Device Alert',
      body: '$deviceName in $room is $status',
      payload: 'device',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  Future<void> sendAutomationAlert(String message) async {
    await showNotification(
      title: '🤖 Automation Alert',
      body: message,
      payload: 'automation',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  Future<void> sendEnergyAlert(double usage, double threshold) async {
    await showNotification(
      title: '⚡ High Energy Usage',
      body:
          'Current usage: ${usage.toStringAsFixed(1)}W exceeds threshold of ${threshold.toStringAsFixed(1)}W',
      payload: 'energy',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  // Schedule notifications (simplified for demo)
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    int? id,
  }) async {
    // For demo purposes, show notification immediately
    await showNotification(
      title: title,
      body: body,
      payload: payload,
      id: id,
    );
  }

  // Cancel notifications
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  void dispose() {
    _alertController.close();
  }
}
