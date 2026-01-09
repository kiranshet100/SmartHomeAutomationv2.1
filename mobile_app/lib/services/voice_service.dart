import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  static final SpeechToText _speechToText = SpeechToText();
  static bool _isInitialized = false;
  static bool _isListening = false;

  static final StreamController<String> _commandController =
      StreamController<String>.broadcast();
  static final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  static Stream<String> get commandStream => _commandController.stream;
  static Stream<String> get statusStream => _statusController.stream;

  static bool get isListening => _isListening;
  static bool get isInitialized => _isInitialized;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: _onStatus,
        onError: (error) => _onError(error.errorMsg),
        debugLogging: true, 
      );

      if (kDebugMode) {
        print('Speech to text initialized: $_isInitialized');
      }

      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize speech to text: $e');
      }
      return false;
    }
  }

  static void _onStatus(String status) {
    if (kDebugMode) {
      print('Speech recognition status: $status');
    }

    _statusController.add(status);

    if (status == 'notListening') {
      _isListening = false;
    } else if (status == 'listening') {
      _isListening = true;
    }
  }

  static void _onError(String error) {
    if (kDebugMode) {
      print('Speech recognition error: $error');
    }
    _statusController.add('Error: $error');
    _isListening = false;
  }

  static Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    await _speechToText.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: false, 
      listenMode: ListenMode.search,
    );

    _isListening = true;
    _statusController.add('Listening...');
  }

  static Future<void> stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    _isListening = false;
    _statusController.add('Stopped listening');
  }

  static void _onResult(SpeechRecognitionResult result) {
    final recognizedWords = result.recognizedWords;

    if (kDebugMode) {
      print('Recognized words: $recognizedWords');
    }

    if (result.finalResult) {
      // Process the final result
      final command = _processVoiceCommand(recognizedWords);
      if (command != null) {
        _commandController.add(command);
      }
    }
  }

  static String? _processVoiceCommand(String text) {
    final lowerText = text.toLowerCase();

    // Device control commands
    if (lowerText.contains('turn on') || lowerText.contains('turn off')) {
      return _extractDeviceCommand(lowerText);
    }

    // Scene commands
    if (lowerText.contains('good morning') ||
        lowerText.contains('good night')) {
      return _extractSceneCommand(lowerText);
    }

    // Status commands
    if (lowerText.contains('status') || lowerText.contains('how is')) {
      return 'status_request';
    }

    // Temperature commands
    if (lowerText.contains('temperature') || lowerText.contains('set to')) {
      return _extractTemperatureCommand(lowerText);
    }

    return null;
  }

  static String? _extractDeviceCommand(String text) {
    final isTurnOn = text.contains('turn on') || text.contains('switch on') || text.contains('start');
    final isTurnOff = text.contains('turn off') || text.contains('switch off') || text.contains('stop');

    if (!isTurnOn && !isTurnOff) return null;

    final action = isTurnOn ? 'turn_on' : 'turn_off';
    
    // Clean the text to just the target
    // e.g. "turn on the kitchen light please" -> "kitchen light please"
    // We'll strip common prefixes
    String target = text;
    if (isTurnOn) {
        target = target.replaceAll(RegExp(r'turn on|switch on|start'), '').trim();
    } else {
        target = target.replaceAll(RegExp(r'turn off|switch off|stop'), '').trim();
    }
    
    // Remove "the"
    if (target.startsWith('the ')) {
        target = target.substring(4).trim();
    }
    
    // Remove "please"
    target = target.replaceAll('please', '').trim();
    
    if (target.isEmpty) return null;
    
    // Return action_target
    return '${action}_$target';
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

  static Future<void> speak(String text) async {
    // TODO: Implement text-to-speech when TTS package is available
    if (kDebugMode) {
      print('TTS: $text');
    }
  }

  static void dispose() {
    _commandController.close();
    _statusController.close();
    if (_isListening) {
      _speechToText.stop();
    }
  }

  // Voice command processing methods for external use
  static Map<String, dynamic>? parseDeviceCommand(String command) {
    if (command.startsWith('turn_on_') || command.startsWith('turn_off_')) {
      final isTurnOn = command.startsWith('turn_on_');
      final prefix = isTurnOn ? 'turn_on_' : 'turn_off_';
      final deviceType = command.substring(prefix.length);
      
      return {
        'action': isTurnOn ? 'turn_on' : 'turn_off',
        'device_type': deviceType,
      };
    } else if (command.startsWith('set_temperature_')) {
      final parts = command.split('_');
      if (parts.length >= 3) {
        final temperature = int.tryParse(parts[2]);
        if (temperature != null) {
          return {
            'action': 'set_temperature',
            'temperature': temperature,
          };
        }
      }
    } else if (command.startsWith('scene_')) {
      final scene = command.split('_')[1];
      return {
        'action': 'activate_scene',
        'scene': scene,
      };
    }

    return null;
  }
}
