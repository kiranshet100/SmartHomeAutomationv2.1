# Sensor Monitoring & Automation Implementation Summary

## ✅ Features Implemented

### 1. **Gas Sensor Monitoring**
   - Monitors `gasLevel` from Firebase sensors
   - **Alert Threshold**: > 50 ppm
   - **Notification**: "⚠️ Gas Level Warning" with current value
   - Example: If gas = 55, notification shows "Sensor reading: 55ppm (Threshold: 50ppm)"

### 2. **Temperature Monitoring**
   - Monitors `temperature` from Firebase sensors
   - **Alert Threshold**: > 35°C
   - **Notification**: "⚠️ Temperature Warning" with current value
   - Example: If temp = 38°C, alert triggers

### 3. **Humidity Monitoring**
   - Monitors `humidity` from Firebase sensors
   - **Alert Threshold**: > 80%
   - **Notification**: "⚠️ Humidity Warning" with current value
   - Example: If humidity = 85%, alert triggers

### 4. **Motion Detection Automation**
   - Detects motion sensor (`motionDetected`)
   - **Automatic Action**: Light (relay4) turns ON
   - **Notification**: "🚨 Motion Detected" with status message
   - Supports multiple motion value formats: `true`, `1`, `"detected"`

### 5. **Smart Alert Management**
   - **Cooldown System**: 5-minute cooldown between alerts for same sensor
   - **Prevents Spam**: Won't repeatedly notify for same condition
   - **Real-time Monitoring**: Listens to Firebase Realtime Database continuously

## 📁 Files Created/Modified

### New Files:
1. **`lib/services/sensor_monitor_service.dart`**
   - Core sensor monitoring logic
   - Threshold checking
   - Motion automation
   - Notification triggering

2. **`SENSOR_MONITORING_README.md`**
   - Complete documentation of the system
   - Configuration guide
   - Testing instructions

### Modified Files:
1. **`lib/main.dart`**
   - Added import: `sensor_monitor_service.dart`
   - Initialized SensorMonitorService in MultiProvider setup
   - Passes DeviceProvider and NotificationService to sensor monitor

## 🔧 How It Works

### System Flow:

```
Firebase Realtime Database
    ↓
    └─→ SensorMonitorService (listens on /devices/esp32_device_01/sensors/)
         ↓
         ├─→ Checks sensor values against thresholds
         ├─→ Triggers NotificationService (shows alert)
         └─→ For motion: calls DeviceProvider.controlRelay('relay4', true)
```

### Sensor Data Path in Firebase:
```
devices/
  esp32_device_01/
    sensors/
      gasLevel: 45
      temperature: 28.5
      humidity: 60
      motionDetected: true
      motionCount: 2
```

## 🎯 Customization Guide

### Change Thresholds:
Edit `lib/services/sensor_monitor_service.dart`, line ~20:
```dart
static const Map<String, double> sensorThresholds = {
  'gasLevel': 50.0,        // Change to desired ppm value
  'temperature': 35.0,     // Change to desired temperature
  'humidity': 80.0,        // Change to desired humidity %
};
```

### Change Motion-Triggered Device:
Edit `lib/services/sensor_monitor_service.dart`, line ~105:
```dart
_deviceProvider.controlRelay('relay4', true);  // Change 'relay4' to 'relay2', 'relay3', etc.
```

### Add New Sensor Monitoring:
1. Add threshold to `sensorThresholds` map
2. Add handling logic in `_checkSensorThreshold()` or `_processSensorData()`
3. Update `_getSensorTitle()` and `_getSensorUnit()` methods

## 📊 Testing Checklist

- [ ] Gas alert triggers when value > 50 ppm
- [ ] Temperature alert triggers when > 35°C
- [ ] Humidity alert triggers when > 80%
- [ ] Motion detection turns on light automatically
- [ ] Notifications appear with correct titles and values
- [ ] 5-minute cooldown prevents spam (same sensor doesn't alert twice in 5 min)
- [ ] Multiple sensors can alert simultaneously
- [ ] App doesn't crash if sensor values are missing
- [ ] App handles null/undefined sensor values gracefully

## 🚀 Testing in Firebase Console

1. Go to Firebase Console → Realtime Database
2. Navigate to: `devices/esp32_device_01/sensors/`
3. Update sensor values:
   - `gasLevel`: Set to 60 (should trigger alert)
   - `temperature`: Set to 40 (should trigger alert)
   - `humidity`: Set to 90 (should trigger alert)
   - `motionDetected`: Set to `true` (should turn on light)

## 📱 Expected Behavior

### Gas Alert Example:
```
Notification Title: ⚠️ Gas Level Warning
Notification Body: Sensor reading: 55ppm (Threshold: 50ppm)
Console Log: Sensor warning: gasLevel = 55 (threshold: 50)
```

### Motion Example:
```
Notification Title: 🚨 Motion Detected
Notification Body: Motion sensor triggered. Light turned on automatically.
Console Log: Motion detected! Turning on light...
Firebase Update: devices/esp32_device_01/relays/relay4 → true
```

## ⚙️ System Requirements

- Firebase Realtime Database configured
- Notification Service initialized
- DeviceProvider initialized
- Valid sensor data in Firebase at specified path

## 🔒 Error Handling

- Gracefully handles missing sensors (won't crash)
- Handles invalid sensor data types
- Cooldown prevents notification spam
- Supports multiple value formats (bool, int, string)

## 📈 Future Enhancements

1. Add Settings UI to customize thresholds
2. Add automation history view
3. Add critical alert levels (SMS/Email)
4. Add machine learning anomaly detection
5. Add hysteresis (on/off thresholds)
6. Add automation enable/disable toggle
7. Add multiple motion-triggered actions
