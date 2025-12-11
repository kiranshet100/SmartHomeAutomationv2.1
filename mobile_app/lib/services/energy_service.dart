import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_model.dart';
import '../models/energy_usage_model.dart';

class EnergyService {
  List<Device> devices;
  final double _tariff;

  EnergyService._(
      {required List<Device> initialDevices, required double tariff})
      : devices = List.from(initialDevices),
        _tariff = tariff;

  static Future<EnergyService> create({required List<Device> devices}) async {
    final prefs = await SharedPreferences.getInstance();
    final tariff = prefs.getDouble('energy_tariff') ?? 8.0;
    return EnergyService._(initialDevices: devices, tariff: tariff);
  }

  void updateDevices(List<Device> newDevices) {
    print('Updating devices in energy service: ${newDevices.length} devices');

    // Preserve existing usage sessions and state information
    for (int i = 0; i < newDevices.length; i++) {
      final newDevice = newDevices[i];
      final existingDeviceIndex =
          devices.indexWhere((d) => d.id == newDevice.id);

      if (existingDeviceIndex != -1) {
        final existingDevice = devices[existingDeviceIndex];
        // Keep existing usage sessions and state transitions
        newDevices[i] = newDevice.copyWith(
          usageSessions: existingDevice.usageSessions,
          lastOnTime: existingDevice.lastOnTime,
          lastOffTime: existingDevice.lastOffTime,
        );
      } else {
        // For new devices, create initial session if device is active
        if (newDevice.isActive && newDevice.wattage != null) {
          final initialSession = DeviceUsageSession(
            deviceId: newDevice.id,
            onTime: DateTime.now(),
            wattage: newDevice.wattage!,
          );
          newDevices[i] = newDevice.copyWith(
            usageSessions: [initialSession],
            lastOnTime: DateTime.now(),
          );
          print(
              'Created initial session for new active device: ${newDevice.name}');
        }
      }
    }

    devices = List.from(newDevices);
    print(
        'Energy service devices updated. Active devices: ${devices.where((d) => d.isActive).length}');
  }

  // Initialize usage sessions for currently active devices that don't have sessions
  void initializeActiveDeviceSessions() {
    print('Initializing sessions for active devices without sessions');
    final now = DateTime.now();

    for (int i = 0; i < devices.length; i++) {
      final device = devices[i];

      // If device is active but has no usage sessions, create one
      if (device.isActive &&
          device.usageSessions.isEmpty &&
          device.wattage != null) {
        final initialSession = DeviceUsageSession(
          deviceId: device.id,
          onTime: device.lastOnTime ?? now,
          wattage: device.wattage!,
        );

        devices[i] = device.copyWith(
          usageSessions: [initialSession],
          lastOnTime: device.lastOnTime ?? now,
        );

        print('Created initial session for active device: ${device.name}');
      }
    }
  }

  // Track device state changes for real usage calculation
  Future<void> updateDeviceState(Device device, bool newState) async {
    print('updateDeviceState called: ${device.name}, newState: $newState');
    final now = DateTime.now();
    final deviceIndex = devices.indexWhere((d) => d.id == device.id);

    if (deviceIndex == -1) {
      print('Device not found in energy service: ${device.id}');
      return;
    }

    final currentDevice = devices[deviceIndex];
    print(
        'Current device state: ${currentDevice.isActive}, wattage: ${currentDevice.wattage}');
    Device? updatedDevice;

    if (newState && !currentDevice.isActive) {
      print('Device turning ON');
      // Device turned ON - create new usage session
      updatedDevice = currentDevice.copyWith(
        isActive: true,
        lastOnTime: now,
        lastUpdated: now,
      );

      // Create new usage session
      final newSession = DeviceUsageSession(
        deviceId: currentDevice.id,
        onTime: now,
        wattage: currentDevice.wattage ?? 0.0,
      );

      updatedDevice = updatedDevice.copyWith(
        usageSessions: [...currentDevice.usageSessions, newSession],
      );

      // Save to Firebase Database
      await _saveDeviceSession(currentDevice.id, newSession);
    } else if (!newState && currentDevice.isActive) {
      print('Device turning OFF');
      // Device turned OFF - close current usage session
      updatedDevice = currentDevice.copyWith(
        isActive: false,
        lastOffTime: now,
        lastUpdated: now,
      );

      // Close the last active session
      final updatedSessions = currentDevice.usageSessions.map((session) {
        if (session.deviceId == currentDevice.id && session.isActive) {
          return session.copyWith(offTime: now);
        }
        return session;
      }).toList();

      updatedDevice = updatedDevice.copyWith(usageSessions: updatedSessions);

      // Save energy record to Firebase
      final closedSession = currentDevice.usageSessions.lastWhere(
        (session) => session.deviceId == currentDevice.id && session.isActive,
        orElse: () => DeviceUsageSession(
          deviceId: currentDevice.id,
          onTime: now,
          wattage: currentDevice.wattage ?? 0.0,
        ),
      );

      if (closedSession.wattage > 0) {
        final energyRecord = EnergyRecord.session(
          deviceId: currentDevice.id,
          deviceName: currentDevice.name,
          startTime: closedSession.onTime,
          endTime: now,
          wattage: closedSession.wattage,
          energyConsumedKwh: closedSession.energyConsumed,
        );

        await _saveEnergyRecord(energyRecord);
      }
    } else {
      print('No state change needed');
      // No state change, just update timestamp
      updatedDevice = currentDevice.copyWith(
        lastUpdated: now,
      );
    }

    // Update devices list if there was a change
    devices[deviceIndex] = updatedDevice;
    print(
        'Updated device in energy service: ${updatedDevice.name}, isActive: ${updatedDevice.isActive}');
    print('Total power consumption now: ${totalPowerConsumption}W');
  }

  // Calculate total power consumption based on active devices
  double get totalPowerConsumption {
    double totalPower = 0.0;
    print('Calculating total power for ${devices.length} devices');
    for (final device in devices) {
      print(
          'Device: ${device.name}, isActive: ${device.isActive}, wattage: ${device.wattage}');
      if (device.isActive && device.wattage != null) {
        totalPower += device.wattage!;
        print('Added ${device.wattage}W for ${device.name}');
      }
    }
    print('Total power calculated: $totalPower');
    return totalPower;
  }

  // Calculate energy consumed today based on actual usage sessions
  double get totalEnergyConsumedToday {
    double totalEnergy = 0.0;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    print('Calculating today\'s energy consumption...');

    for (final device in devices) {
      for (final session in device.usageSessions) {
        final sessionEnd = session.offTime ?? now;

        // Only count sessions that overlap with today
        if (sessionEnd.isAfter(todayStart)) {
          final sessionStart =
              session.onTime.isAfter(todayStart) ? session.onTime : todayStart;

          final effectiveDuration = sessionEnd.difference(sessionStart);
          final energy = session.wattage * effectiveDuration.inHours / 1000;
          totalEnergy += energy;
          print(
              'Session from ${session.onTime} to ${sessionEnd}: ${energy.toStringAsFixed(3)} kWh');
        }
      }
    }

    print('Total energy for today: $totalEnergy kWh');
    return totalEnergy;
  }

  // Get estimated cost for today
  double get estimatedCostToday {
    return totalEnergyConsumedToday * _tariff;
  }

  // Calculate potential savings based on device optimization
  double get potentialSavings {
    double potentialEnergy = 0.0;

    // Calculate what energy would be consumed if devices were optimally used
    for (final device in devices) {
      if (device.wattage != null) {
        // Assume 4 hours of optimal usage for lights, 8 hours for other devices
        final optimalHours = device.type == 'light' ? 4.0 : 8.0;
        final actualHours = _getTodayUsageHours(device);
        final optimizationFactor =
            (optimalHours - actualHours).clamp(0, double.infinity);

        potentialEnergy += device.wattage! * optimizationFactor / 1000;
      }
    }

    final potentialCost = potentialEnergy * _tariff;
    return potentialCost;
  }

  // Get device energy consumption for today
  Map<String, double> get deviceEnergyConsumption {
    Map<String, double> consumption = {};
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final device in devices) {
      double deviceEnergy = 0.0;

      for (final session in device.usageSessions) {
        final sessionEnd = session.offTime ?? now;

        // Only count sessions that overlap with today
        if (sessionEnd.isAfter(todayStart)) {
          final sessionStart =
              session.onTime.isAfter(todayStart) ? session.onTime : todayStart;

          final effectiveDuration = sessionEnd.difference(sessionStart);
          final energy = session.wattage * effectiveDuration.inHours / 1000;
          deviceEnergy += energy;
        }
      }

      consumption[device.id] = deviceEnergy;
    }

    return consumption;
  }

  // Get energy consumption by time range
  Future<List<EnergyRecord>> getEnergyConsumptionByRange(
      DateTime start, DateTime end) async {
    final records = await _getEnergyRecordsFromDatabase(start, end);

    // Filter and combine with current active sessions
    for (final device in devices) {
      for (final session in device.usageSessions) {
        if (session.isActive) {
          final record = EnergyRecord(
            deviceId: session.deviceId,
            deviceName: device.name,
            recordDate: session.onTime,
            endTime: end,
            wattage: session.wattage,
            energyConsumed: session.energyConsumed,
            isActive: true,
            recordType: 'session',
          );
          records.add(record);
        }
      }
    }

    return records;
  }

  // Get daily energy consumption for chart data
  Future<List<Map<String, dynamic>>> getDailyEnergyConsumption(int days) async {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final nextDay = date.add(const Duration(days: 1));

      double dailyEnergy = 0.0;

      for (final device in devices) {
        for (final session in device.usageSessions) {
          final sessionEnd = session.offTime ?? now;

          // Check if session overlaps with this day
          if (sessionEnd.isAfter(date) && session.onTime.isBefore(nextDay)) {
            final overlapStart =
                session.onTime.isAfter(date) ? session.onTime : date;
            final overlapEnd =
                sessionEnd.isBefore(nextDay) ? sessionEnd : nextDay;

            final overlapDuration = overlapEnd.difference(overlapStart);
            final energy = session.wattage * overlapDuration.inHours / 1000;
            dailyEnergy += energy;
          }
        }
      }

      result.add({
        'date': date.toIso8601String(),
        'energy': dailyEnergy,
        'cost': dailyEnergy * _tariff,
      });
    }

    return result;
  }

  // Get device-wise usage statistics
  Map<String, Map<String, dynamic>> getDeviceUsageStats() {
    final stats = <String, Map<String, dynamic>>{};

    for (final device in devices) {
      final sessions = device.usageSessions;
      double totalEnergy = 0.0;
      int totalSessions = 0;
      Duration totalDuration = Duration.zero;

      for (final session in sessions) {
        totalEnergy += session.energyConsumed;
        totalSessions++;
        totalDuration += session.activeDuration;
      }

      stats[device.id] = {
        'device': device,
        'totalEnergy': totalEnergy,
        'totalSessions': totalSessions,
        'totalDuration': totalDuration,
        'averageDuration': sessions.isNotEmpty
            ? Duration(
                milliseconds: totalDuration.inMilliseconds ~/ sessions.length)
            : Duration.zero,
        'energyPerSession':
            totalSessions > 0 ? totalEnergy / totalSessions : 0.0,
      };
    }

    return stats;
  }

  // Helper methods
  double _getTodayUsageHours(Device device) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    double totalHours = 0.0;

    for (final session in device.usageSessions) {
      final sessionEnd = session.offTime ?? now;

      if (sessionEnd.isAfter(todayStart)) {
        final sessionStart =
            session.onTime.isAfter(todayStart) ? session.onTime : todayStart;

        totalHours += sessionEnd.difference(sessionStart).inMinutes / 60.0;
      }
    }

    return totalHours;
  }

  Future<void> _saveDeviceSession(
      String deviceId, DeviceUsageSession session) async {
    try {
      final sessionRef = FirebaseDatabase.instance.ref('device_sessions');
      await sessionRef
          .child('${deviceId}_${session.onTime.millisecondsSinceEpoch}')
          .set(session.toJson());
    } catch (e) {
      print('Error saving device session: $e');
    }
  }

  Future<void> _saveEnergyRecord(EnergyRecord record) async {
    try {
      final energyRef = FirebaseDatabase.instance.ref('energy_records');
      await energyRef
          .child(
              '${record.deviceId}_${record.recordDate.millisecondsSinceEpoch}')
          .set(record.toJson());
    } catch (e) {
      print('Error saving energy record: $e');
    }
  }

  Future<List<EnergyRecord>> _getEnergyRecordsFromDatabase(
      DateTime start, DateTime end) async {
    try {
      final energyRef = FirebaseDatabase.instance.ref('energy_records');
      final snapshot = await energyRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          List<EnergyRecord> records = [];
          data.forEach((key, value) {
            final recordData = Map<String, dynamic>.from(value);
            final record = EnergyRecord.fromJson(recordData);

            // Filter by date range using recordDate
            if (record.recordDate.isAfter(start) &&
                record.recordDate.isBefore(end)) {
              records.add(record);
            }
          });
          return records;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching energy records: $e');
      return [];
    }
  }
}
