# Smart Energy Monitoring System

## Overview
The Smart Energy Monitoring System tracks real device usage based on actual on/off states and duration, providing accurate energy consumption data instead of real-time estimates.

## Key Features

### 1. Real Usage Tracking
- **Session-based tracking**: Each device on/off cycle creates a usage session
- **Precise timing**: Records exact start and end times for each session
- **Energy calculation**: Calculates energy consumption based on actual usage duration
- **Historical data**: Stores all usage sessions for analysis

### 2. Energy Models
- **EnergyUsageRecord**: Complete energy usage record with device info, timing, and consumption
- **DeviceUsageSession**: Individual on/off session with duration and energy calculation

### 3. Smart Analytics
- **Real-time monitoring**: Shows current power consumption
- **Daily/monthly trends**: Historical charts showing consumption patterns
- **Device breakdown**: Individual device energy usage analysis
- **Cost calculation**: Energy cost estimation based on actual usage
- **Optimization suggestions**: Identifies potential energy savings

### 4. Firebase Integration
- **Automatic storage**: Saves usage sessions and energy records to Firebase
- **Data persistence**: Historical energy data stored in cloud
- **Cross-device access**: Energy data accessible from any device

## Architecture

### Models
- `EnergyUsageRecord`: Complete energy usage data
- `DeviceUsageSession`: Individual usage sessions
- Updated `Device` model with usage tracking

### Services
- `EnergyService`: Core energy calculation and tracking logic
- `DatabaseService`: Firebase integration for data storage
- Updated `DeviceProvider`: Real-time energy tracking on device control

### UI Components
- `SmartEnergyMonitoringScreen`: Comprehensive energy monitoring interface
- Real-time charts using fl_chart library
- Interactive device breakdown and usage sessions

## Usage Flow

1. **Device Control**: When a device is turned on/off via the app
   - DeviceProvider calls EnergyService.updateDeviceState()
   - Creates new usage session or closes existing one
   - Calculates energy consumption for closed sessions
   - Saves data to Firebase

2. **Data Retrieval**: When viewing energy monitoring
   - Loads usage sessions from Firebase
   - Combines with current active sessions
   - Calculates real-time and historical consumption
   - Displays interactive charts and analytics

3. **Analysis**: Continuous energy monitoring
   - Tracks daily/monthly consumption trends
   - Identifies high-consumption devices
   - Suggests optimization opportunities
   - Calculates potential cost savings

## Key Benefits

✅ **Real Accuracy**: Based on actual device usage, not estimates
✅ **Complete History**: Full usage session tracking with timestamps
✅ **Smart Analytics**: Insights and optimization suggestions
✅ **Firebase Integration**: Cloud storage and cross-device access
✅ **Real-time Updates**: Live energy monitoring and alerts
✅ **Cost Analysis**: Accurate energy cost calculations

## File Structure

```
lib/
├── models/
│   ├── energy_usage_model.dart      # Energy usage models
│   └── device_model.dart            # Updated with usage tracking
├── services/
│   ├── energy_service.dart          # Core energy logic
│   └── database_service.dart        # Firebase integration
├── providers/
│   └── device_provider.dart         # Updated with energy tracking
└── screens/
    ├── smart_energy_monitoring_screen.dart  # Main energy UI
    └── home/
        └── home_screen.dart         # Updated navigation
```

## Next Steps

To fully complete the system:

1. **Firebase Setup**: Ensure Firebase project is configured for energy data
2. **Testing**: Test with real devices to validate accuracy
3. **Data Migration**: Convert existing energy data to new format
4. **Analytics Enhancement**: Add more sophisticated analysis features
5. **Notification System**: Energy usage alerts and notifications

## Usage Example

```dart
// View smart energy monitoring
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const SmartEnergyMonitoringScreen(),
  ),
);

// Energy data automatically tracked when controlling devices
await deviceProvider.controlRelay(deviceName, true); // Starts tracking
await deviceProvider.controlRelay(deviceName, false); // Ends session
```

The system now provides accurate, real-time energy monitoring based on actual device usage patterns!