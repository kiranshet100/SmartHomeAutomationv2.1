# Smart Home Automation Mobile App

A comprehensive Flutter-based smart home automation mobile application with real-time device control, energy monitoring, voice commands, and smart automation features.

## Features

### 🔐 Authentication
- User registration and login
- JWT token-based authentication
- Secure session management
- Profile management

### 🏠 Dashboard & Device Control
- Real-time device status monitoring
- Device control (lights, thermostats, cameras, locks)
- Room-based device organization
- Quick device toggles

### ⚡ Energy Monitoring
- Real-time energy consumption tracking
- Energy usage charts and analytics
- Cost calculation and monitoring
- Energy-saving recommendations

### 🎤 Voice Commands
- Voice-activated device control
- Scene activation (morning/night routines)
- Temperature control via voice
- Smart command parsing

### 🌙 Smart Automation
- Water tank level monitoring with auto-pump control
- Automated device scheduling
- Smart scene management
- Real-time sensor data processing

### 🎨 User Interface
- Modern Material Design 3 UI
- Dark/Light theme support
- Responsive design for all screen sizes
- Smooth animations and transitions

### 📱 Cross-Platform
- iOS and Android support
- Optimized performance
- Offline mode capabilities
- Push notifications

## Architecture

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Node.js, Express.js
- **Database**: MongoDB
- **Real-time Communication**: MQTT, Socket.io
- **Authentication**: JWT
- **State Management**: Provider Pattern

### Project Structure
```
SmartHomeAutomation/
├── mobile_app/                 # Flutter mobile application
│   ├── lib/
│   │   ├── models/            # Data models
│   │   ├── providers/         # State management
│   │   ├── screens/           # UI screens
│   │   ├── services/          # Business logic services
│   │   └── theme/             # App theming
│   ├── assets/                # Static assets
│   └── pubspec.yaml           # Flutter dependencies
├── backend/                   # Node.js backend server
│   ├── models/               # Database models
│   ├── routes/               # API routes
│   ├── server.js             # Main server file
│   └── package.json          # Node dependencies
├── firmware/                 # IoT device firmware
├── docs/                     # Documentation
└── deployment/               # Deployment scripts
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Node.js (16.0.0 or higher)
- MongoDB (4.0 or higher)
- Android Studio / Xcode for mobile development
- Git

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd SmartHomeAutomation/backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Environment configuration:**
   Create a `.env` file in the backend directory:
   ```env
   MONGODB_URI=mongodb://localhost:27017/smart_home
   JWT_SECRET=your_jwt_secret_key_here
   MQTT_BROKER=mqtt://localhost:1883
   PORT=3000
   ```

4. **Start MongoDB:**
   ```bash
   # Using MongoDB locally
   mongod

   # Or using Docker
   docker run -d -p 27017:27017 --name mongodb mongo:latest
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

3. **Configure Firebase (optional for notifications):**
   - Create a Firebase project
   - Add Android/iOS apps to the project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place files in appropriate directories

4. **Update API endpoints:**
   Edit `lib/providers/auth_provider.dart`, `lib/providers/device_provider.dart`, and `lib/providers/sensor_provider.dart` to update the backend URL if needed.

5. **Run the app:**
   ```bash
   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios

   # For web (development)
   flutter run -d chrome
   ```

## Dependencies

### Flutter Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.15.1
  firebase_auth: ^4.7.3
  cloud_firestore: ^4.9.1
  firebase_messaging: ^14.6.9

  # HTTP & Networking
  http: ^1.1.0
  socket_io_client: ^2.0.3
  mqtt_client: ^9.8.1

  # State Management
  provider: ^6.0.5

  # UI Components
  cupertino_icons: ^1.0.2
  flutter_svg: ^2.0.7
  cached_network_image: ^3.2.3
  fl_chart: ^0.63.0
  shimmer: ^3.0.0
  flutter_staggered_animations: ^1.1.1
  flutter_slidable: ^3.0.0

  # Utilities
  shared_preferences: ^2.2.0
  intl: ^0.19.0
  flutter_local_notifications: ^15.1.0
  speech_to_text: ^6.1.1
  permission_handler: ^11.0.1
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  connectivity_plus: ^4.0.1
```

### Backend Dependencies
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^7.5.0",
    "jsonwebtoken": "^9.0.2",
    "mqtt": "^5.1.1",
    "socket.io": "^4.7.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "bcryptjs": "^2.4.3"
  }
}
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile

### Devices
- `GET /api/devices` - Get all user devices
- `POST /api/devices` - Add new device
- `PUT /api/devices/:id` - Update device
- `DELETE /api/devices/:id` - Remove device
- `POST /api/devices/:id/control` - Control device

### Sensors
- `GET /api/sensors/latest` - Get latest sensor data
- `GET /api/sensors/device/:deviceId` - Get sensor data for device
- `GET /api/sensors/history` - Get sensor data history
- `GET /api/sensors/stats/:deviceId` - Get sensor statistics

## MQTT Topics

### Device Control
- `home/control` - Send control commands to devices
- `home/status` - Receive device status updates

### Sensor Data
- `home/sensors` - Publish sensor readings
- `home/alert` - Publish alert notifications

## Voice Commands

### Device Control
- "Turn on/off [device name]"
- "Turn on/off lights"
- "Turn on/off fan"
- "Turn on/off AC"

### Scenes
- "Good morning" - Activates morning scene
- "Good night" - Activates night scene

### Temperature
- "Set temperature to [number] degrees"
- "Make it warmer/cooler"

## Deployment

### Backend Deployment
1. **Environment Setup:**
   ```bash
   # Production environment variables
   NODE_ENV=production
   MONGODB_URI=mongodb://production-server/smart_home
   JWT_SECRET=your_production_jwt_secret
   MQTT_BROKER=mqtt://production-broker:1883
   ```

2. **Process Management:**
   ```bash
   # Using PM2
   npm install -g pm2
   pm2 start server.js --name "smart-home-backend"
   pm2 save
   pm2 startup
   ```

### Mobile App Deployment

1. **Android Build:**
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

2. **iOS Build:**
   ```bash
   flutter build ios --release
   ```

3. **Web Build:**
   ```bash
   flutter build web --release
   ```

## Testing

### Unit Tests
```bash
# Run Flutter tests
flutter test

# Run with coverage
flutter test --coverage
```

### Integration Tests
```bash
# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Backend Tests
```bash
# Run backend tests
npm test
```

## Troubleshooting

### Common Issues

1. **Backend Connection Issues:**
   - Ensure backend server is running on correct port
   - Check firewall settings
   - Verify API endpoint URLs in mobile app

2. **Database Connection:**
   - Ensure MongoDB is running
   - Check connection string in `.env` file
   - Verify network connectivity

3. **Voice Commands Not Working:**
   - Grant microphone permissions
   - Check device compatibility
   - Ensure speech-to-text service is available

4. **Real-time Updates Not Working:**
   - Verify MQTT broker is running
   - Check Socket.io connection
   - Ensure proper topic subscriptions

### Debug Mode
Enable debug logging by setting:
```dart
// In main.dart
debugShowCheckedModeBanner: true,
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check the documentation in `/docs`
- Review the troubleshooting section above

## Future Enhancements

- [ ] Advanced automation rules engine
- [ ] Integration with popular smart home platforms (Google Home, Alexa)
- [ ] Machine learning for energy optimization
- [ ] Multi-user household support
- [ ] Advanced security features
- [ ] Mobile app widgets
- [ ] Wear OS companion app