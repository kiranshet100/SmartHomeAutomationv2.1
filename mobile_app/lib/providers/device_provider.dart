import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_model.dart';
import '../services/energy_service.dart';

class DeviceProvider with ChangeNotifier {
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;
  final DatabaseReference _devicesRef =
      FirebaseDatabase.instance.ref('devices/esp32_device_01');
  late StreamSubscription<DatabaseEvent> _devicesSubscription;
  EnergyService? _energyService;

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DeviceProvider() {
    _listenToDevices();
  }

  void _listenToDevices() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _devicesSubscription = _devicesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final oldDevices = List<Device>.from(_devices);
        _devices = _parseDevices(data);

        // Update energy service with new device data
        _updateEnergyServiceDevices();

        // Preserve usage sessions from old devices when possible
        for (int i = 0; i < _devices.length; i++) {
          final oldDevice = oldDevices.firstWhere(
            (d) => d.id == _devices[i].id,
            orElse: () => _devices[i],
          );
          if (oldDevice.usageSessions.isNotEmpty) {
            _devices[i] = _devices[i].copyWith(
              usageSessions: oldDevice.usageSessions,
              lastOnTime: oldDevice.lastOnTime,
              lastOffTime: oldDevice.lastOffTime,
            );
          }
        }
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _error = 'Failed to fetch devices: $error';
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Device> _parseDevices(Map<dynamic, dynamic> data) {
    final List<Device> devices = [];
    final String deviceId = data['deviceId'];
    final int timestamp = data['timestamp'];
    final lastUpdated = DateTime.fromMillisecondsSinceEpoch(timestamp);

    final relays = data['relays'] as Map<dynamic, dynamic>;
    relays.forEach((key, value) {
      bool isActive = false;
      double? wattage;

      if (value is Map) {
        // Handle both 'state' and direct numeric values
        isActive = (value['state'] == 1) ||
            (value['state'] == true) ||
            (value == 1) ||
            (value == true);
        wattage = (value['wattage'] as num?)?.toDouble();
      } else {
        // Handle direct numeric or boolean values
        isActive = (value == 1) ||
            (value == true) ||
            (value == '1') ||
            (value == 'on');
      }

      // Set default wattage if not provided
      if (wattage == null) {
        // Default wattage based on device type
        switch (key.toLowerCase()) {
          case 'light':
          case 'lights':
            wattage = 10.0; // LED bulb
            break;
          case 'fan':
            wattage = 50.0;
            break;
          case 'ac':
          case 'airconditioner':
            wattage = 1500.0;
            break;
          case 'heater':
            wattage = 1200.0;
            break;
          case 'tv':
            wattage = 100.0;
            break;
          default:
            wattage = 25.0; // Generic relay device
        }
      }

      // Map specific relay keys to friendly names
      String displayName = key.toString();
      final lowerKey = key.toString().toLowerCase();
      if (lowerKey == 'relay2') displayName = 'fan';
      if (lowerKey == 'relay4') displayName = 'light';

      print(
          'Parsed device: $displayName (key: $key), isActive: $isActive, wattage: $wattage');

      devices.add(Device(
        id: '$deviceId-$key',
        name: displayName,
        type: 'relay',
        room: 'Living Room',
        isOnline: true,
        isActive: isActive,
        wattage: wattage,
        properties: {},
        lastUpdated: lastUpdated,
      ));
    });

    final sensors = data['sensors'] as Map<dynamic, dynamic>;
    sensors.forEach((key, value) {
      devices.add(Device(
        id: '$deviceId-$key',
        name: key,
        type: 'sensor',
        room: 'Living Room',
        isOnline: true,
        isActive: false, // Not applicable for sensors
        properties: {'value': value},
        lastUpdated: lastUpdated,
      ));
    });

    return devices;
  }

  Future<void> controlRelay(String relayId, bool isOn) async {
    try {
      // Resolve device either by friendly name (e.g., 'fan') or by relay key (e.g., 'relay2')
      Device device = _devices.firstWhere(
        (d) =>
            d.type == 'relay' && d.name.toLowerCase() == relayId.toLowerCase(),
        orElse: () => _devices.firstWhere(
            (d) =>
                d.type == 'relay' &&
                d.id.toLowerCase().endsWith('-' + relayId.toLowerCase()),
            orElse: () => throw Exception('Device not found')),
      );

      // Update local device state immediately for instant UI feedback
      final deviceIndex = _devices.indexWhere((d) => d.id == device.id);
      if (deviceIndex != -1) {
        final now = DateTime.now();
        _devices[deviceIndex] = _devices[deviceIndex].copyWith(
          isActive: isOn,
          lastUpdated: now,
          lastOnTime: isOn ? now : null,
          lastOffTime: !isOn ? now : null,
        );
      }

      // Notify UI immediately
      notifyListeners();

      // Track energy usage with the updated local device state
      await _initializeEnergyService();

      // Get the updated device from our local list
      final currentDevice = _devices[deviceIndex];
      await _energyService?.updateDeviceState(currentDevice, isOn);

      // Sync energy service devices with updated local devices
      _energyService?.updateDevices(_devices);

      // Determine the relay key to write to Firebase (the original key is the last segment of id)
      final parts = device.id.split('-');
      final originalKey = parts.isNotEmpty ? parts.last : relayId;
      await _devicesRef.child('relays').child(originalKey).set(isOn ? 1 : 0);

      // Final notify to ensure all UI components update
      notifyListeners();
    } catch (e) {
      _error = 'Failed to control relay: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _devicesSubscription.cancel();
    super.dispose();
  }

  // The following methods are kept for compatibility but are not used with the current Firebase implementation.
  Future<void> fetchDevices(String token) async {}
  Future<bool> controlDevice(String deviceId, String action,
      Map<String, dynamic> params, String token) async {
    return false;
  }

  Future<bool> addDevice(Device device, String token) async {
    return false;
  }

  Future<bool> removeDevice(String deviceId, String token) async {
    return false;
  }

  List<Device> getDevicesByRoom(String room) {
    return _devices.where((device) => device.room == room).toList();
  }

  List<Device> getDevicesByType(String type) {
    return _devices.where((device) => device.type == type).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _initializeEnergyService() async {
    if (_energyService == null) {
      _energyService = await EnergyService.create(devices: _devices);
      // Initialize sessions for currently active devices
      _energyService!.initializeActiveDeviceSessions();
    } else {
      // Update existing energy service with current devices
      _energyService!.updateDevices(_devices);
      // Initialize sessions for any active devices that don't have sessions
      _energyService!.initializeActiveDeviceSessions();
    }
  }

  void _updateEnergyServiceDevices() {
    _initializeEnergyService();
  }

  // Debug method to help troubleshoot energy calculation issues
  void debugEnergyCalculation() {
    print('=== ENERGY CALCULATION DEBUG ===');
    print('Total devices: ${_devices.length}');
    print('Active devices: ${_devices.where((d) => d.isActive).length}');

    for (final device in _devices) {
      print('Device: ${device.name}');
      print('  - Type: ${device.type}');
      print('  - Is Active: ${device.isActive}');
      print('  - Wattage: ${device.wattage}');
      print('  - Usage Sessions: ${device.usageSessions.length}');
      for (final session in device.usageSessions) {
        print(
            '    Session: ${session.onTime} - ${session.offTime ?? "ongoing"}, ${session.wattage}W');
      }
      print('');
    }

    if (_energyService != null) {
      print(
          'Energy Service - Total Power: ${_energyService!.totalPowerConsumption}W');
      print(
          'Energy Service - Today\'s Energy: ${_energyService!.totalEnergyConsumedToday} kWh');
    } else {
      print('Energy Service not initialized');
    }
    print('================================');
  }
}
