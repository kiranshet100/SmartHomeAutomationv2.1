import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../providers/device_provider.dart';
import 'notification_service.dart';

/// SensorMonitorService monitors sensor data and triggers notifications and automations
class SensorMonitorService {
  static final SensorMonitorService _instance =
      SensorMonitorService._internal();
  factory SensorMonitorService() => _instance;

  late DeviceProvider _deviceProvider;
  late NotificationService _notificationService;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  StreamSubscription? _sensorSubscription;
  final Map<String, dynamic> _lastSensorValues = {};
  final Map<String, DateTime> _lastNotificationTime = {};
  static const Duration _notificationCooldown = Duration(minutes: 5);

  // Define sensor thresholds
  static const Map<String, double> sensorThresholds = {
    'gasLevel': 50.0, // Gas sensor warning at 50
    'temperature': 35.0, // Temperature warning at 35°C
    'humidity': 80.0, // Humidity warning at 80%
  };

  SensorMonitorService._internal();

  Future<void> initialize(
    DeviceProvider deviceProvider,
    NotificationService notificationService,
  ) async {
    _deviceProvider = deviceProvider;
    _notificationService = notificationService;
    _startMonitoring();
  }

  void _startMonitoring() {
    // Monitor sensors from Firebase in real-time
    _sensorSubscription =
        _dbRef.child('devices/esp32_device_01/sensors').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        _processSensorData(data);
      }
    });
  }

  void _processSensorData(Map<dynamic, dynamic> sensorData) {
    sensorData.forEach((key, value) {
      final sensorName = key.toString();
      final sensorValue = _parseValue(value);

      if (sensorValue == null) return;

      // Store last value
      _lastSensorValues[sensorName] = sensorValue;

      // Check thresholds
      _checkSensorThreshold(sensorName, sensorValue);

      // Handle motion detection
      if (sensorName.toLowerCase().contains('motion')) {
        _handleMotionDetection(sensorValue);
      }
    });
  }

  void _checkSensorThreshold(String sensorName, dynamic value) {
    // Get threshold for this sensor
    final threshold = sensorThresholds[sensorName];
    if (threshold == null) return;

    final numValue = _parseValue(value);
    if (numValue == null || numValue <= threshold) return;

    // Check cooldown to avoid spam
    final lastNotif = _lastNotificationTime[sensorName];
    if (lastNotif != null &&
        DateTime.now().difference(lastNotif) < _notificationCooldown) {
      return;
    }

    // Send warning notification
    _sendSensorWarning(sensorName, numValue, threshold);
    _lastNotificationTime[sensorName] = DateTime.now();
  }

  void _sendSensorWarning(String sensorName, dynamic value, double threshold) {
    final title = _getSensorTitle(sensorName);
    final unit = _getSensorUnit(sensorName);

    _notificationService.showNotification(
      title: '⚠️ $title Warning',
      body: 'Sensor reading: $value$unit (Threshold: $threshold$unit)',
      payload: 'sensor_alert_$sensorName',
    );

    print('Sensor warning: $sensorName = $value (threshold: $threshold)');
  }

  void _handleMotionDetection(dynamic value) {
    // If motion detected (value is typically true, 1, or non-zero)
    final motionDetected = _isMotionDetected(value);

    if (motionDetected) {
      print('Motion detected! Turning on light...');

      // Turn on the light (relay4)
      _deviceProvider.controlRelay('relay4', true);

      // Send notification
      _notificationService.showNotification(
        title: '🚨 Motion Detected',
        body: 'Motion sensor triggered. Light turned on automatically.',
        payload: 'motion_alert',
      );
    }
  }

  bool _isMotionDetected(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'detected';
    }
    return false;
  }

  double? _parseValue(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _getSensorTitle(String sensorName) {
    switch (sensorName.toLowerCase()) {
      case 'gaslevel':
        return 'Gas Level';
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'motiondetected':
        return 'Motion';
      default:
        return sensorName;
    }
  }

  String _getSensorUnit(String sensorName) {
    switch (sensorName.toLowerCase()) {
      case 'gaslevel':
        return ' ppm';
      case 'temperature':
        return '°C';
      case 'humidity':
        return '%';
      default:
        return '';
    }
  }

  /// Get current sensor value
  dynamic getSensorValue(String sensorName) {
    return _lastSensorValues[sensorName];
  }

  /// Get all current sensor values
  Map<String, dynamic> getAllSensorValues() {
    return Map.from(_lastSensorValues);
  }

  void dispose() {
    _sensorSubscription?.cancel();
  }
}
