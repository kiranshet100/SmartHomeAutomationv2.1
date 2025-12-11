# Sensor Monitoring and Automation System

## Overview
The Smart Home App now includes automatic sensor monitoring with notifications and automations.

## Features Implemented

### 1. Sensor Threshold Monitoring
The app monitors sensor values and sends alerts when thresholds are exceeded:

#### Current Thresholds:
- **Gas Sensor (gasLevel)**: ⚠️ Warning at > 50 ppm
- **Temperature**: ⚠️ Warning at > 35°C
- **Humidity**: ⚠️ Warning at > 80%

#### Alert Features:
- Notifications are sent when thresholds are exceeded
- Cooldown of 5 minutes between alerts for the same sensor (prevents spam)
- Each alert shows:
  - Sensor name (e.g., "Gas Level")
  - Current reading and unit
  - Threshold value

### 2. Motion Detection Automation
When motion is detected, the light (relay 4) automatically turns on:

- **Trigger**: Motion sensor detects motion
- **Action**: Light (relay 4) turns on automatically
- **Notification**: User is notified of motion detection

#### Supported Motion Detection Values:
- `true` (boolean)
- `1` (numeric)
- `"detected"` (string)
- Any non-zero value

### 3. Real-time Firebase Monitoring
The system monitors Firebase Realtime Database at:
```
devices/esp32_device_01/sensors/
```

Continuously listens for sensor data updates and processes them in real-time.

## System Architecture

### Key Components:

1. **SensorMonitorService** (`lib/services/sensor_monitor_service.dart`)
   - Monitors sensor data from Firebase
   - Checks thresholds and triggers notifications
   - Handles motion detection and automation
   - Manages notification cooldowns

2. **NotificationService** (`lib/services/notification_service.dart`)
   - Displays local notifications
   - Manages notification channels
   - Handles user interactions with alerts

3. **DeviceProvider** (`lib/providers/device_provider.dart`)
   - Manages device control (relays)
   - Provides `controlRelay()` for automations

### Service Initialization (in `lib/main.dart`):
```dart
// In MultiProvider setup:
ChangeNotifierProvider<DeviceProvider>(
  create: (_) {
    final provider = DeviceProvider();
    NotificationService().initialize(provider);
    SensorMonitorService().initialize(provider, NotificationService());
    return provider;
  },
)
```

## Sensor Data Structure in Firebase

Expected sensor data format in Firebase:
```json
{
  "devices": {
    "esp32_device_01": {
      "sensors": {
        "gasLevel": 45,
        "temperature": 28.5,
        "humidity": 65,
        "motionDetected": true,
        "motionCount": 2
      }
    }
  }
}
```

## How to Customize

### Add New Sensor Thresholds
Edit `lib/services/sensor_monitor_service.dart`:

```dart
static const Map<String, double> sensorThresholds = {
  'gasLevel': 50.0,
  'temperature': 35.0,
  'humidity': 80.0,
  'customSensor': 100.0,  // Add new threshold here
};
```

### Add New Automation Rules
Extend the `_processSensorData()` method to handle additional sensors:

```dart
// Handle custom sensor
if (sensorName.toLowerCase().contains('custom')) {
  _handleCustomSensor(sensorValue);
}
```

### Change Motion-Triggered Device
Edit the `_handleMotionDetection()` method:

```dart
// Change from relay4 (light) to another relay
_deviceProvider.controlRelay('relay2', true);  // Turn on fan instead
```

### Adjust Notification Cooldown
Modify the cooldown duration:
```dart
static const Duration _notificationCooldown = Duration(minutes: 5);
```

## Testing

### Simulate Sensor Alerts:
1. Use Firebase Console to update sensor values
2. Set `gasLevel` to > 50 to trigger gas alert
3. Set `temperature` to > 35 to trigger temperature alert
4. Set `motionDetected` to `true` to trigger motion automation

### Check Logs:
Look for messages like:
```
Sensor warning: gasLevel = 55 (threshold: 50)
Motion detected! Turning on light...
```

## Future Enhancements

1. Add configurable thresholds via Settings screen
2. Add automation history logging
3. Add option to disable/enable automations
4. Add multiple motion-triggered actions (turn on lights, record video, etc.)
5. Add SMS/Email alerts for critical sensors
6. Add machine learning for anomaly detection
7. Add hysteresis (different on/off thresholds for stability)
