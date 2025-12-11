import 'package:flutter/material.dart';
import 'voice_service.dart';
import '../providers/device_provider.dart';
import '../providers/auth_provider.dart' as custom_auth;
import '../models/device_model.dart';

// Shortcut mapping from spoken device names to relay IDs (fallback)
const Map<String, String> _shortcutRelayMap = {
  'fan': 'relay2',
  'light': 'relay4',
};

class VoiceCommandHandler {
  static DeviceProvider? _deviceProvider;
  static custom_auth.AuthProvider? _authProvider;
  static BuildContext? _context;

  static void initialize(
    BuildContext context,
    DeviceProvider deviceProvider,
    custom_auth.AuthProvider authProvider,
  ) {
    _context = context;
    _deviceProvider = deviceProvider;
    _authProvider = authProvider;

    // Listen to voice commands
    VoiceService.commandStream.listen(_handleVoiceCommand);
  }

  static void _handleVoiceCommand(String command) {
    if (_deviceProvider == null || _authProvider == null || _context == null) {
      return;
    }

    final parsedCommand = VoiceService.parseDeviceCommand(command);
    if (parsedCommand == null) return;

    final token = _authProvider!.user?.uid;
    if (token == null) return;

    switch (parsedCommand['action']) {
      case 'turn_on':
        _handleTurnOnCommand(parsedCommand, token);
        break;
      case 'turn_off':
        _handleTurnOffCommand(parsedCommand, token);
        break;
      case 'set_temperature':
        _handleTemperatureCommand(parsedCommand, token);
        break;
      case 'activate_scene':
        _handleSceneCommand(parsedCommand, token);
        break;
    }
  }

  static void _handleTurnOnCommand(Map<String, dynamic> command, String token) {
    final deviceType = command['device_type'];

    // If the command targets a specific relay (e.g., 'relay1'), call controlRelay
    if (deviceType != null &&
        deviceType.toString().toLowerCase().startsWith('relay')) {
      final relayId = deviceType.toString().toLowerCase();
      // Relay mapping: allow 'fan' and 'light' mapping to specific relays
      // but here user targeted specific relay id
      _deviceProvider!.controlRelay(relayId, true);
      _showFeedback('Turned on $relayId');
      return;
    }

    // Support named device shortcuts mapped to relays: try dynamic lookup first
    if (deviceType == 'fan' || deviceType == 'light') {
      final searchTerm = deviceType.toString().toLowerCase();
      final matched = _deviceProvider!.devices.firstWhere(
        (d) => d.type == 'relay' && d.name.toLowerCase().contains(searchTerm),
        orElse: () => Device(
          id: '',
          name: '',
          type: '',
          room: '',
          isOnline: false,
          isActive: false,
          properties: {},
          lastUpdated: DateTime.now(),
        ),
      );
      if (matched.id.isNotEmpty) {
        _deviceProvider!.controlRelay(matched.name.toLowerCase(), true);
        _showFeedback('Turned on ${deviceType} (${matched.name})');
        return;
      }

      // Fallback to shortcut mapping if dynamic lookup fails
      final fallbackRelay = _shortcutRelayMap[searchTerm];
      if (fallbackRelay != null) {
        _deviceProvider!.controlRelay(fallbackRelay, true);
        _showFeedback('Turned on ${deviceType} (${fallbackRelay})');
        return;
      }
    }

    // Fallback: control by device.type matching
    final devices = _deviceProvider!.devices
        .where((device) => device.type == deviceType && !device.isActive)
        .toList();

    for (final device in devices) {
      _deviceProvider!.controlDevice(device.id, 'turn_on', {}, token);
    }

    // Show feedback
    _showFeedback('Turned on ${devices.length} $deviceType device(s)');
  }

  static void _handleTurnOffCommand(
      Map<String, dynamic> command, String token) {
    final deviceType = command['device_type'];

    if (deviceType != null &&
        deviceType.toString().toLowerCase().startsWith('relay')) {
      final relayId = deviceType.toString().toLowerCase();
      _deviceProvider!.controlRelay(relayId, false);
      _showFeedback('Turned off $relayId');
      return;
    }

    // Support named device shortcuts mapped to relays: try dynamic lookup first
    if (deviceType == 'fan' || deviceType == 'light') {
      final searchTerm = deviceType.toString().toLowerCase();
      final matched = _deviceProvider!.devices.firstWhere(
        (d) => d.type == 'relay' && d.name.toLowerCase().contains(searchTerm),
        orElse: () => Device(
          id: '',
          name: '',
          type: '',
          room: '',
          isOnline: false,
          isActive: false,
          properties: {},
          lastUpdated: DateTime.now(),
        ),
      );
      if (matched.id.isNotEmpty) {
        _deviceProvider!.controlRelay(matched.name.toLowerCase(), false);
        _showFeedback('Turned off ${deviceType} (${matched.name})');
        return;
      }

      // Fallback to shortcut mapping if dynamic lookup fails
      final fallbackRelayOff = _shortcutRelayMap[searchTerm];
      if (fallbackRelayOff != null) {
        _deviceProvider!.controlRelay(fallbackRelayOff, false);
        _showFeedback('Turned off ${deviceType} (${fallbackRelayOff})');
        return;
      }
    }

    // Fallback: control by device.type matching
    final devices = _deviceProvider!.devices
        .where((device) => device.type == deviceType && device.isActive)
        .toList();

    for (final device in devices) {
      _deviceProvider!.controlDevice(device.id, 'turn_off', {}, token);
    }

    // Show feedback
    _showFeedback('Turned off ${devices.length} $deviceType device(s)');
  }

  static void _handleTemperatureCommand(
      Map<String, dynamic> command, String token) {
    final temperature = command['temperature'];
    final thermostats = _deviceProvider!.devices
        .where((device) => device.type == 'thermostat')
        .toList();

    for (final device in thermostats) {
      _deviceProvider!.controlDevice(
        device.id,
        'set_temperature',
        {'temperature': temperature},
        token,
      );
    }

    // Show feedback
    _showFeedback('Set temperature to ${temperature}°C');
  }

  static void _handleSceneCommand(Map<String, dynamic> command, String token) {
    final scene = command['scene'];

    switch (scene) {
      case 'morning':
        // Turn on lights, adjust thermostat
        final lights = _deviceProvider!.devices
            .where((device) => device.type == 'light')
            .toList();
        final thermostats = _deviceProvider!.devices
            .where((device) => device.type == 'thermostat')
            .toList();

        for (final light in lights) {
          _deviceProvider!.controlDevice(light.id, 'turn_on', {}, token);
        }
        for (final thermostat in thermostats) {
          _deviceProvider!.controlDevice(
            thermostat.id,
            'set_temperature',
            {'temperature': 22},
            token,
          );
        }
        _showFeedback('Good morning! Activated morning scene');
        break;

      case 'night':
        // Turn off lights, lower thermostat
        final lights = _deviceProvider!.devices
            .where((device) => device.type == 'light')
            .toList();
        final thermostats = _deviceProvider!.devices
            .where((device) => device.type == 'thermostat')
            .toList();

        for (final light in lights) {
          _deviceProvider!.controlDevice(light.id, 'turn_off', {}, token);
        }
        for (final thermostat in thermostats) {
          _deviceProvider!.controlDevice(
            thermostat.id,
            'set_temperature',
            {'temperature': 18},
            token,
          );
        }
        _showFeedback('Good night! Activated night scene');
        break;
    }
  }

  static void _showFeedback(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  static Future<void> processVoiceCommand(String commandText) async {
    // Process the command text directly
    final lowerText = commandText.toLowerCase();

    // Device control commands: Turn on/off, Start, Switch on/off
    if (lowerText.contains('turn on') ||
        lowerText.contains('turn off') ||
        lowerText.contains('start the') ||
        lowerText.contains('switch on') ||
        lowerText.contains('switch off')) {
      _extractAndHandleDeviceCommand(lowerText);
    }
    // Scene commands
    else if (lowerText.contains('good morning') ||
        lowerText.contains('good night')) {
      final command = _extractSceneCommand(lowerText);
      if (command != null) {
        _handleVoiceCommand(command);
      }
    }
    // Temperature commands
    else if (lowerText.contains('temperature') ||
        lowerText.contains('set to')) {
      final command = _extractTemperatureCommand(lowerText);
      if (command != null) {
        _handleVoiceCommand(command);
      }
    }
  }

  static void _extractAndHandleDeviceCommand(String text) {
    // Determine if turning on or off
    final isTurnOn = text.contains('turn on') ||
        text.contains('start the') ||
        text.contains('switch on');
    final isTurnOff = text.contains('turn off') || text.contains('switch off');

    if (!isTurnOn && !isTurnOff) return;

    // Handle "all lights" or "all fans"
    if (text.contains('all lights')) {
      _controlAllDevicesOfType('light', isTurnOn);
      return;
    }
    if (text.contains('all fans')) {
      _controlAllDevicesOfType('fan', isTurnOn);
      return;
    }

    // Handle "appliance N and M" or "appliance N"
    final applianceMatches =
        RegExp(r'appliance\s+([\d\s,and]+)', caseSensitive: false)
            .allMatches(text);
    if (applianceMatches.isNotEmpty) {
      for (final match in applianceMatches) {
        final applRef = match.group(1) ?? '';
        // Parse comma/and-separated numbers
        final nums = RegExp(r'\d+')
            .allMatches(applRef)
            .map((m) => m.group(0) ?? '')
            .toList();
        for (final num in nums) {
          _controlApplianceByNumber(num, isTurnOn);
        }
      }
      return;
    }

    // Handle room-qualified device names (e.g., "bedroom light", "living room fan")
    final roomMatch =
        RegExp(r'(\w+\s+)?(?:room\s+)?(light|lights|fan)', caseSensitive: false)
            .firstMatch(text);
    if (roomMatch != null) {
      final deviceType = roomMatch.group(2)?.toLowerCase() ?? '';
      // Extract room name if present
      final roomNameMatch = RegExp(r'(\w+)\s+(?:room\s+)?(?:light|lights|fan)',
              caseSensitive: false)
          .firstMatch(text);
      final roomName = roomNameMatch?.group(1)?.toLowerCase() ?? '';
      _controlDeviceInRoom(
          deviceType, roomName.isNotEmpty ? roomName : null, isTurnOn);
      return;
    }

    // Handle explicit relay commands
    final relayNum = _extractRelayNumber(text);
    if (relayNum.isNotEmpty) {
      final command = '${isTurnOn ? 'turn_on' : 'turn_off'}_relay$relayNum';
      _handleVoiceCommand(command);
      return;
    }

    // Handle named devices: fan, light, etc.
    final command = _extractDeviceCommand(text, isTurnOn);
    if (command != null) {
      _handleVoiceCommand(command);
    }
  }

  static String _extractRelayNumber(String text) {
    // Numeric form: "relay 1", "relay 2"
    final relayRegex = RegExp(r'relay\s*(\d+)', caseSensitive: false);
    final match = relayRegex.firstMatch(text);
    if (match != null) {
      return match.group(1) ?? '';
    }

    // Word form: "relay one", "relay two"
    final relayWordRegex =
        RegExp(r'relay\s*(one|two|three|four)', caseSensitive: false);
    final wordMatch = relayWordRegex.firstMatch(text);
    if (wordMatch != null) {
      final word = wordMatch.group(1)?.toLowerCase() ?? '';
      final wordToNum = {'one': '1', 'two': '2', 'three': '3', 'four': '4'};
      return wordToNum[word] ?? '';
    }

    return '';
  }

  static void _controlAllDevicesOfType(String deviceType, bool isOn) {
    if (_deviceProvider == null) return;
    final devices =
        _deviceProvider!.devices.where((d) => d.type == deviceType).toList();
    for (final device in devices) {
      _deviceProvider!.controlRelay(device.name.toLowerCase(), isOn);
    }
    _showFeedback('${isOn ? 'Turned on' : 'Turned off'} all ${deviceType}s');
  }

  static void _controlApplianceByNumber(String applNum, bool isOn) {
    if (_deviceProvider == null) return;
    // Map appliance 1->relay1, appliance 3->relay3, etc.
    final relayId = 'relay$applNum';
    _deviceProvider!.controlRelay(relayId, isOn);
    _showFeedback('${isOn ? 'Turned on' : 'Turned off'} appliance $applNum');
  }

  static void _controlDeviceInRoom(
      String deviceType, String? roomName, bool isOn) {
    if (_deviceProvider == null) return;
    // Filter devices by type and optionally by room
    var devices =
        _deviceProvider!.devices.where((d) => d.type == deviceType).toList();
    if (roomName != null && roomName.isNotEmpty) {
      devices = devices
          .where((d) => d.room.toLowerCase().contains(roomName))
          .toList();
    }
    for (final device in devices) {
      _deviceProvider!.controlRelay(device.name.toLowerCase(), isOn);
    }
    final roomStr =
        roomName != null && roomName.isNotEmpty ? 'in $roomName ' : '';
    _showFeedback(
        '${isOn ? 'Turned on' : 'Turned off'} ${roomStr}${deviceType}(s)');
  }

  static String? _extractDeviceCommand(String text, bool isTurnOn) {
    // Extract device name
    String deviceName = '';

    // Check common device patterns
    if (text.contains('light') || text.contains('lights')) {
      deviceName = 'light';
    } else if (text.contains('fan')) {
      deviceName = 'fan';
    } else if (text.contains('ac') || text.contains('air conditioner')) {
      deviceName = 'thermostat';
    } else if (text.contains('tv') || text.contains('television')) {
      deviceName = 'tv';
    } else if (text.contains('door') || text.contains('lock')) {
      deviceName = 'lock';
    }

    if (deviceName.isNotEmpty) {
      return '${isTurnOn ? 'turn_on' : 'turn_off'}_$deviceName';
    }

    return null;
  }

  static String? _extractSceneCommand(String text) {
    if (text.contains('good morning')) {
      return 'scene_morning';
    } else if (text.contains('good night')) {
      return 'scene_night';
    }

    return null;
  }

  static String? _extractTemperatureCommand(String text) {
    // Extract temperature value
    final tempRegex = RegExp(r'(\d+)\s*(?:degrees?|°)?');
    final match = tempRegex.firstMatch(text);

    if (match != null) {
      final temperature = int.tryParse(match.group(1) ?? '');
      if (temperature != null && temperature >= 16 && temperature <= 30) {
        return 'set_temperature_$temperature';
      }
    }

    return null;
  }
}
