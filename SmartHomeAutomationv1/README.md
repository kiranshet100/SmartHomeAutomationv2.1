# Smart Home Automation System

A comprehensive smart home automation mobile application built with Flutter, featuring real-time device control, energy monitoring, automation scenes, and voice commands.

## 🚀 Features

### Core Functionality
- **User Authentication**: Secure login and registration with JWT tokens
- **Real-time Device Control**: Control lights, thermostats, cameras, locks, and fans
- **Energy Monitoring**: Track energy usage with charts and analytics
- **Automation Scenes**: Create and activate predefined automation scenarios
- **Scheduling**: Set up automated schedules for device control
- **Voice Commands**: Control devices using voice commands
- **Push Notifications**: Receive alerts for device status changes and security events

### Advanced Features
- **Offline Mode**: Local data caching for offline functionality
- **Multi-platform Support**: iOS and Android compatibility
- **Responsive Design**: Optimized for various screen sizes
- **Dark/Light Theme**: Automatic theme switching
- **Real-time Updates**: MQTT integration for instant device status updates
- **Security Alerts**: Gas leak detection and motion sensor alerts
- **Water Tank Monitoring**: Real-time water level monitoring with auto-pump control

## 🏗️ Architecture

### Frontend (Flutter)
- **State Management**: Provider pattern for app-wide state management
- **UI Framework**: Material Design with custom theming
- **Networking**: HTTP client for API communication
- **Local Storage**: SharedPreferences and SQLite for data persistence
- **Real-time Communication**: Socket.io and MQTT for live updates

### Backend (Node.js)
- **Framework**: Express.js with RESTful API
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT-based authentication
- **Real-time**: Socket.io for real-time communication
- **IoT Integration**: MQTT broker for device communication

## 📱 Screenshots

### Dashboard
- Overview of all connected devices
- Quick stats and energy summary
- Real-time alerts and notifications
- Water tank monitoring with visual indicators

### Device Control
- Individual device control screens
- Real-time status updates
- Advanced settings for each device type
- Voice command integration

### Energy Monitoring
- Energy consumption charts
- Cost analysis and savings tips
- Device-wise energy usage breakdown
- Historical data visualization

### Automation
- Scene creation and management
- Schedule setup and configuration
- Voice command training
- Automation rule builder

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Node.js (16.0.0 or higher)
- MongoDB
- Android Studio / Xcode for mobile development
- MQTT Broker (optional, for IoT integration)

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd SmartHomeAutomation/backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Environment Configuration:**
   Create a `.env` file in the backend directory:
   ```env
   MONGODB_URI=mongodb://localhost:27017/smart_home
   JWT_SECRET=your_jwt_secret_key
   MQTT_BROKER=mqtt://localhost:1883
   PORT=3000
   ```

4. **Start MongoDB:**
   ```bash
   mongod
   ```

5. **Start the backend server:**
   ```bash
   npm start
   ```

### Mobile App Setup

1. **Navigate to mobile app directory:**
   ```bash
   cd SmartHomeAutomation/mobile_app
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase (optional):**
   - Create a Firebase project
   - Add Android/iOS apps to Firebase
   - Download configuration files
   - Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in appropriate directories

4. **Run the app:**
   ```bash
   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios

   # For Web (Chrome)
   flutter run -d chrome
   ```

## 🔧 Configuration

### API Endpoints
- **Base URL**: `http://10.0.2.2:3000/api` (Android emulator)
- **Authentication**: `/auth/login`, `/auth/register`
- **Devices**: `/devices`
- **Sensors**: `/sensors`

### MQTT Topics
- **Device Control**: `home/control`
- **Sensor Data**: `home/sensors`
- **Alerts**: `home/alert`

## 📊 Data Models

### Device Model
```dart
class Device {
  final String id;
  final String name;
  final String type; // light, thermostat, camera, lock, fan
  final String room;
  final bool isOnline;
  final bool isActive;
  final Map<String, dynamic> properties;
  final DateTime lastUpdated;
}
```

### Sensor Data Model
```dart
class SensorData {
  final String id;
  final String deviceId;
  final String sensorType; // temperature, humidity, motion, light, gas
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}
```

## 🎯 Usage Examples

### Voice Commands
- "Turn on living room lights"
- "Set temperature to 22 degrees"
- "Activate movie scene"
- "Show me energy usage"

### Automation Scenes
- **Good Morning**: Turn on lights, adjust thermostat
- **Good Night**: Turn off lights, secure home
- **Movie Time**: Dim lights, adjust settings
- **Away Mode**: Turn off devices, activate security

### Scheduling
- Morning routine at 7:00 AM
- Evening wind down at 10:00 PM
- Security check at 11:00 PM

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Device Authorization**: User-specific device access control
- **Encrypted Communication**: HTTPS for API communication
- **Local Data Encryption**: Encrypted local storage
- **Security Alerts**: Real-time security monitoring

## 📈 Performance Optimization

- **Lazy Loading**: On-demand data loading
- **Caching**: Local data caching for offline mode
- **Efficient Rendering**: Optimized widget rebuilding
- **Background Processing**: Asynchronous operations
- **Memory Management**: Proper resource disposal

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Backend Tests
```bash
cd backend
npm test
```

## 🚀 Deployment

### Mobile App
1. **Build APK:**
   ```bash
   flutter build apk --release
   ```

2. **Build iOS:**
   ```bash
   flutter build ios --release
   ```

3. **Web Deployment:**
   ```bash
   flutter build web
   ```

### Backend
1. **Production Build:**
   ```bash
   npm run build
   ```

2. **Docker Deployment:**
   ```bash
   docker build -t smart-home-backend .
   docker run -p 3000:3000 smart-home-backend
   ```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Email: support@smarthomeapp.com
- Documentation: [Wiki](https://github.com/username/smart-home-automation/wiki)
- Issues: [GitHub Issues](https://github.com/username/smart-home-automation/issues)

## 🔄 Future Enhancements

- [ ] Google Assistant integration
- [ ] Amazon Alexa integration
- [ ] Advanced analytics dashboard
- [ ] Multi-user household support
- [ ] Energy optimization algorithms
- [ ] Smart device discovery
- [ ] Backup and restore functionality
- [ ] Third-party device integration

---

**Built with ❤️ using Flutter and Node.js**