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
    });
  }



  /// Get current sensor value
  dynamic getSensorValue(String sensorName) {
    return _lastSensorValues[sensorName];
  }

  /// Get all current sensor values
  Map<String, dynamic> getAllSensorValues() {
    return Map.from(_lastSensorValues);
  }

  double? _parseValue(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void dispose() {
    _sensorSubscription?.cancel();
  }
}
