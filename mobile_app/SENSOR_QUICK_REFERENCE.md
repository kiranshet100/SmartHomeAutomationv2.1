# Quick Reference: Sensor Monitoring & Automation

## 🚀 What Was Implemented

### Automatic Sensor Alerts
Your app now monitors sensors and sends notifications when values exceed safe thresholds:

| Sensor | Alert Threshold | Unit | Notification |
|--------|-----------------|------|--------------|
| **Gas Level** | > 50 | ppm | ⚠️ Gas Level Warning |
| **Temperature** | > 35 | °C | ⚠️ Temperature Warning |
| **Humidity** | > 80 | % | ⚠️ Humidity Warning |

### Motion-Triggered Automation
- **When**: Motion is detected (`motionDetected = true`)
- **Action**: Light (relay 4) turns on automatically
- **Notification**: "🚨 Motion Detected - Light turned on automatically"

## 📋 Implementation Details

### New Service: `SensorMonitorService`
**Location**: `lib/services/sensor_monitor_service.dart`

**Responsibilities**:
- Listens to Firebase sensor data in real-time
- Checks sensor values against thresholds
- Triggers notifications via NotificationService
- Executes automations (e.g., turn on light on motion)
- Manages 5-minute cooldown to prevent alert spam

### Firebase Sensor Path
```
devices/esp32_device_01/sensors/
  ├── gasLevel: 45
  ├── temperature: 28.5
  ├── humidity: 65
  ├── motionDetected: true
  └── motionCount: 2
```

## 🔧 Configuration

### To Change Thresholds
Edit `lib/services/sensor_monitor_service.dart`:

```dart
static const Map<String, double> sensorThresholds = {
  'gasLevel': 50.0,        // ← Modify this value
  'temperature': 35.0,     // ← Or this one
  'humidity': 80.0,        // ← Or this one
};
```

### To Change Motion-Triggered Device
Edit `_handleMotionDetection()` method:

```dart
_deviceProvider.controlRelay('relay4', true);  // ← Change 'relay4' to 'relay2', etc.
```

## ✅ How to Test

### Test 1: Gas Alert
1. Open Firebase Console → Realtime Database
2. Go to `devices/esp32_device_01/sensors/`
3. Set `gasLevel` to `60`
4. Check: Notification appears with "Gas Level Warning"

### Test 2: Temperature Alert
1. Set `temperature` to `40`
2. Check: Notification appears with "Temperature Warning"

### Test 3: Motion Automation
1. Set `motionDetected` to `true`
2. Check: Light turns on and notification appears

### Test 4: Cooldown (No Spam)
1. Set `gasLevel` to `60` again within 5 minutes
2. Check: No new notification appears (cooldown active)
3. Wait 5+ minutes and repeat
4. Check: Notification appears again

## 🎯 Customization Examples

### Example 1: Lower Temperature Threshold
```dart
'temperature': 30.0,  // Alert at 30°C instead of 35°C
```

### Example 2: Add New Sensor
1. Add to thresholds map:
   ```dart
   'airQuality': 150.0,
   ```
2. Update sensor title:
   ```dart
   case 'airquality':
     return 'Air Quality';
   ```
3. Update unit:
   ```dart
   case 'airquality':
     return ' AQI';
   ```

### Example 3: Motion Turns on Fan Instead of Light
```dart
_deviceProvider.controlRelay('relay2', true);  // relay2 is fan
```

## 📊 How It Works (Flow Diagram)

```
┌─────────────────────────┐
│  Firebase Realtime DB   │ (devices/esp32_device_01/sensors/)
└───────────┬─────────────┘
            │ (listens continuously)
            ▼
┌─────────────────────────────────────────┐
│    SensorMonitorService.initialize()    │
│  - Listens to sensor updates            │
│  - Processes sensor data                │
└───────────┬─────────────────────────────┘
            │
            ├─→ For each sensor value:
            │   ├─→ Check if > threshold
            │   ├─→ If yes & not on cooldown:
            │   │   └─→ Send Notification ✅
            │   └─→ Update cooldown timer
            │
            └─→ Special handling for motion:
                ├─→ If motionDetected = true
                ├─→ Call controlRelay('relay4', true)
                └─→ Send Motion Notification ✅
```

## 🔄 Initialization Order

When app starts:
1. Firebase initializes
2. `main.dart` creates DeviceProvider
3. DeviceProvider triggers:
   - `NotificationService().initialize(provider)`
   - `SensorMonitorService().initialize(provider, NotificationService())`
4. SensorMonitorService starts listening to Firebase
5. Sensor monitoring is active ✅

## 📱 User Experience

### Scenario 1: Gas Leak
1. ESP32 detects gas level = 55 ppm
2. Value syncs to Firebase
3. App receives update
4. App checks: 55 > 50 ✓
5. Notification appears: "⚠️ Gas Level Warning - Reading: 55ppm"
6. User sees alert and can take action

### Scenario 2: Motion at Night
1. Motion sensor triggers
2. Firebase updates `motionDetected = true`
3. App receives update
4. App detects motion
5. Light automatically turns on
6. Notification appears: "🚨 Motion Detected - Light turned on"
7. User wakes up to lit room

## ⚙️ Technical Details

**Real-time Updates**: Firebase Realtime Database streams data to the app
**Async Processing**: Notifications and automations happen non-blocking
**Error Handling**: App gracefully handles missing/invalid sensor data
**Value Parsing**: Supports multiple data types (bool, int, double, string)
**Spam Prevention**: Cooldown prevents multiple alerts for same sensor within 5 min

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| Notifications not showing | Check NotificationService is initialized |
| Motion not triggering light | Verify Firebase path is correct |
| Alert spam | Cooldown is working; check alert timestamp |
| No sensor data | Verify ESP32 is sending data to Firebase |
| App crashes on sensor update | Check sensor data type matches expected format |

## 📞 Support Info

- **Service File**: `lib/services/sensor_monitor_service.dart`
- **Documentation**: `SENSOR_MONITORING_README.md`
- **Configuration**: `SensorMonitorService.sensorThresholds`
- **Firebase Path**: `devices/esp32_device_01/sensors/`
