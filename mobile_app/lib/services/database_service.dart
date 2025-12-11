import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/scene_model.dart';
import '../models/energy_usage_model.dart';
import '../models/device_model.dart';

class DatabaseService {
  final DatabaseReference _automationsRef =
      FirebaseDatabase.instance.ref('automations');
  final DatabaseReference _energyHistoryRef =
      FirebaseDatabase.instance.ref('energy_history');
  final DatabaseReference _deviceSessionsRef =
      FirebaseDatabase.instance.ref('device_sessions');
  final DatabaseReference _energyRecordsRef =
      FirebaseDatabase.instance.ref('energy_records');

  // Scene operations
  Future<void> saveScene(Scene scene) async {
    try {
      await _automationsRef.child('scenes').child(scene.id).set(scene.toJson());
    } catch (e) {
      print('Failed to save scene: $e');
      rethrow;
    }
  }

  Future<void> deleteScene(String sceneId) async {
    try {
      await _automationsRef.child('scenes').child(sceneId).remove();
    } catch (e) {
      print('Failed to delete scene: $e');
      rethrow;
    }
  }

  Stream<List<Scene>> getScenes() {
    return _automationsRef.child('scenes').onValue.map((event) {
      final scenesMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (scenesMap == null) {
        return [];
      }
      return scenesMap.entries.map((entry) {
        final sceneData = Map<String, dynamic>.from(entry.value);
        return Scene.fromJson(sceneData);
      }).toList();
    });
  }

  // Energy History operations (uses unified EnergyRecord model)
  Future<void> saveEnergyHistory(EnergyRecord history) async {
    try {
      final date = history.recordDate;
      final path = '${date.year}/${date.month}/${date.day}/${history.deviceId}';
      await _energyHistoryRef.child(path).set(history.toJson());
    } catch (e) {
      print('Failed to save energy history: $e');
      rethrow;
    }
  }

  // Device operations with proper DateTime handling
  Future<void> saveDevice(Device device) async {
    try {
      await _automationsRef
          .child('devices')
          .child(device.id)
          .set(device.toJson());
    } catch (e) {
      print('Failed to save device: $e');
      rethrow;
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _automationsRef.child('devices').child(deviceId).remove();
    } catch (e) {
      print('Failed to delete device: $e');
      rethrow;
    }
  }

  Stream<List<Device>> getDevices() {
    return _automationsRef.child('devices').onValue.map((event) {
      final devicesMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (devicesMap == null) {
        return [];
      }
      return devicesMap.entries.map((entry) {
        final deviceData = Map<String, dynamic>.from(entry.value);
        return Device.fromJson(deviceData);
      }).toList();
    });
  }

  // Device Usage Session operations
  Future<void> saveDeviceUsageSession(DeviceUsageSession session) async {
    try {
      final timestamp = session.onTime.millisecondsSinceEpoch;
      final path = '${session.deviceId}_$timestamp';
      await _deviceSessionsRef.child(path).set(session.toJson());
    } catch (e) {
      print('Failed to save device usage session: $e');
      rethrow;
    }
  }

  Future<void> saveEnergyRecord(EnergyRecord record) async {
    try {
      final timestamp = record.recordDate.millisecondsSinceEpoch;
      final path = '${record.deviceId}_$timestamp';
      await _energyRecordsRef.child(path).set(record.toJson());
    } catch (e) {
      print('Failed to save energy record: $e');
      rethrow;
    }
  }

  // Get device usage sessions by date range
  Future<List<DeviceUsageSession>> getDeviceSessionsByDateRange(
    String deviceId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _deviceSessionsRef.get();
      final sessionsMap = snapshot.value as Map<dynamic, dynamic>?;
      if (sessionsMap == null) {
        return [];
      }

      return sessionsMap.entries
          .where((entry) {
            final key = entry.key.toString();
            return key.startsWith('${deviceId}_');
          })
          .map((entry) {
            final sessionData = Map<String, dynamic>.from(entry.value);
            return DeviceUsageSession.fromJson(sessionData);
          })
          .where((session) =>
              session.onTime.isAfter(startDate) &&
              session.onTime.isBefore(endDate))
          .toList();
    } catch (e) {
      print('Failed to get device sessions by date range: $e');
      return [];
    }
  }

  Future<List<EnergyRecord>> getEnergyHistory(DateTime date) async {
    try {
      final path = '${date.year}/${date.month}/${date.day}';
      final snapshot = await _energyHistoryRef.child(path).get();
      final historyMap = snapshot.value as Map<dynamic, dynamic>?;
      if (historyMap == null) {
        return [];
      }
      return historyMap.entries.map((entry) {
        final historyData = Map<String, dynamic>.from(entry.value);
        return EnergyRecord.fromJson(historyData);
      }).toList();
    } catch (e) {
      print('Failed to get energy history: $e');
      return [];
    }
  }
}
