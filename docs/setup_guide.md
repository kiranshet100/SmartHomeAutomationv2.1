# Smart Home Automation Setup Guide

## Prerequisites

### Hardware Requirements
- ESP32 Development Board
- DHT22 Temperature/Humidity Sensor
- PIR Motion Sensor
- LDR Light Sensor
- MQ2 Gas/Smoke Sensor
- Water Level Sensor
- 4-Channel Relay Module
- Jumper wires and breadboard
- 5V/2A Power supply
- Computer with USB port

### Software Requirements
- Arduino IDE (with ESP32 support)
- Node.js (v16 or higher)
- MongoDB
- Flutter SDK
- Git
- MQTT Broker (Mosquitto)

## Step 1: Hardware Assembly

### Gather Components
1. ESP32 Dev Board
2. DHT22 Sensor
3. PIR Sensor
4. LDR Sensor
5. MQ2 Gas Sensor
6. Water Level Sensor
7. 4-Channel Relay Module
8. Breadboard and jumper wires

### Wiring Connections

#### Power Supply
```
ESP32 VIN ------> +5V Power Supply
ESP32 GND ------> Ground
ESP32 3.3V -----> 3.3V Components
```

#### DHT22 Sensor
```
ESP32 GPIO 4 ------> DHT22 DATA
ESP32 3.3V --------> DHT22 VCC
ESP32 GND ---------> DHT22 GND
10kΩ Resistor: DHT22 DATA to 3.3V
```

#### PIR Motion Sensor
```
ESP32 GPIO 5 ------> PIR SIGNAL
ESP32 5V ----------> PIR VCC
ESP32 GND ---------> PIR GND
```

#### LDR Light Sensor
```
ESP32 GPIO 6 ------> LDR (voltage divider)
ESP32 3.3V --------> 10kΩ Resistor ------> LDR ------> GND
ESP32 GPIO 6 connected to resistor-LDR junction
```

#### MQ2 Gas Sensor
```
ESP32 GPIO 7 ------> MQ2 AO (Analog Output)
ESP32 5V ----------> MQ2 VCC
ESP32 GND ---------> MQ2 GND
```

#### Water Level Sensor
```
ESP32 GPIO 8 ------> Water Sensor SIGNAL
ESP32 5V ----------> Water Sensor VCC
ESP32 GND ---------> Water Sensor GND
```

#### Relay Module
```
ESP32 GPIO 9 ------> Relay IN1 (Light)
ESP32 GPIO 10 -----> Relay IN2 (Fan)
ESP32 GPIO 11 -----> Relay IN3 (Appliance)
ESP32 GPIO 12 -----> Relay IN4 (Pump)
ESP32 5V ----------> Relay VCC
ESP32 GND ---------> Relay GND
```

#### Status LEDs
```
ESP32 GPIO 13 -----> LED1 (System Status)
ESP32 GPIO 14 -----> LED2 (WiFi Status)
ESP32 GPIO 15 -----> LED3 (Alert Status)
220Ω Resistor: Each LED to GND
```

### Testing Hardware
1. Power on the system
2. Check LED indicators
3. Verify sensor readings via serial monitor

## Step 2: ESP32 Firmware Setup

### Install Arduino IDE
1. Download Arduino IDE from arduino.cc
2. Install ESP32 board support:
   - File > Preferences > Additional Boards Manager URLs
   - Add: `https://dl.espressif.com/dl/package_esp32_index.json`
   - Tools > Board > Boards Manager > Search ESP32 > Install

### Install Required Libraries
1. DHT Sensor Library by Adafruit
2. PubSubClient by Nick O'Leary
3. WiFi (built-in)

### Configure Firmware
1. Open `SmartHomeAutomation/firmware/smart_home.ino`
2. Update WiFi credentials:
   ```cpp
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```
3. Update MQTT broker details:
   ```cpp
   const char* mqtt_server = "YOUR_MQTT_BROKER_IP";
   const char* mqtt_user = "YOUR_MQTT_USER";
   const char* mqtt_pass = "YOUR_MQTT_PASSWORD";
   ```

### Upload Firmware
1. Select Board: ESP32 Dev Module
2. Select Port: COMx (ESP32 port)
3. Click Upload
4. Monitor serial output for connection status

## Step 3: Backend Setup

### Install Dependencies
```bash
cd SmartHomeAutomation/backend
npm install
```

### Configure Environment
1. Copy `.env` file
2. Update configuration:
   ```env
   PORT=3000
   MONGODB_URI=mongodb://localhost:27017/smart_home
   JWT_SECRET=your_super_secret_jwt_key
   MQTT_BROKER=mqtt://localhost:1883
   ```

### Setup MongoDB
```bash
# Install MongoDB locally or use MongoDB Atlas
sudo apt install mongodb
sudo systemctl start mongodb
```

### Setup MQTT Broker
```bash
# Install Mosquitto
sudo apt install mosquitto
sudo systemctl start mosquitto
```

### Start Backend Server
```bash
npm start
# or for development
npm run dev
```

## Step 4: Mobile App Setup

### Install Flutter
1. Download Flutter SDK
2. Add to PATH
3. Run `flutter doctor` to verify installation

### Configure Firebase
1. Create Firebase project at console.firebase.google.com
2. Enable Authentication and Firestore
3. Add Android/iOS apps to project
4. Download configuration files:
   - Android: google-services.json
   - iOS: GoogleService-Info.plist

### Install Dependencies
```bash
cd SmartHomeAutomation/mobile_app
flutter pub get
```

### Configure API Endpoints
Update API base URL in the app:
```dart
const String baseUrl = 'http://your-backend-url:3000';
```

### Run App
```bash
flutter run
```

## Step 5: System Integration

### Test Device Connection
1. Power on ESP32
2. Check backend logs for device registration
3. Verify MQTT messages in broker

### Test Mobile App
1. Register/Login in app
2. Add device in app
3. Test device control
4. Monitor sensor data

### Configure Automation Rules
1. Set up scheduled tasks
2. Configure alert thresholds
3. Test automation scenarios

## Step 6: Security Setup

### User Roles
- **Owner**: Full access to all features
- **Family**: Limited device control
- **Guest**: View-only access

### Network Security
1. Use WPA3 WiFi encryption
2. Change default MQTT credentials
3. Enable SSL/TLS for API calls
4. Configure firewall rules

### Device Security
1. Update ESP32 firmware regularly
2. Use secure MQTT connections
3. Implement device authentication
4. Monitor device access logs

## Step 7: Testing and Validation

### Hardware Testing
- [ ] All sensors reading correctly
- [ ] Relays switching properly
- [ ] LEDs indicating correct status
- [ ] Power supply stable

### Software Testing
- [ ] Backend API responding
- [ ] Database connections working
- [ ] MQTT messages flowing
- [ ] Mobile app connecting

### Integration Testing
- [ ] Device registration working
- [ ] Real-time data updates
- [ ] Control commands executing
- [ ] Alerts triggering

### User Acceptance Testing
- [ ] User registration/login
- [ ] Device management
- [ ] Sensor monitoring
- [ ] Automation features

## Step 8: Production Deployment

### Backend Deployment
Choose one deployment option:
- Heroku (simple)
- AWS EC2 (scalable)
- Docker (containerized)

### Mobile App Deployment
1. Build release APK/IPA
2. Configure app store listings
3. Submit for review
4. Publish to app stores

### Hardware Deployment
1. Mount components securely
2. Connect to permanent power
3. Test in production environment
4. Monitor system performance

## Troubleshooting

### Common Issues

#### ESP32 Not Connecting to WiFi
- Check WiFi credentials
- Verify ESP32 board selection
- Check antenna placement
- Try different WiFi channel

#### Backend Not Starting
- Verify Node.js version
- Check MongoDB connection
- Review environment variables
- Check port availability

#### Mobile App Crashes
- Verify Firebase configuration
- Check API endpoints
- Review device permissions
- Update Flutter dependencies

#### MQTT Connection Issues
- Verify broker IP/port
- Check authentication credentials
- Review firewall settings
- Check network connectivity

### Debug Tools

#### ESP32 Debugging
```cpp
Serial.begin(115200);
Serial.println("Debug message");
```

#### Backend Debugging
```bash
npm run dev
# Check console logs
```

#### Mobile App Debugging
```bash
flutter logs
flutter run --debug
```

## Maintenance

### Regular Tasks
- [ ] Update ESP32 firmware
- [ ] Backup database
- [ ] Monitor system logs
- [ ] Check sensor calibration
- [ ] Update mobile app

### Performance Monitoring
- Monitor CPU/memory usage
- Check response times
- Review error logs
- Analyze user usage patterns

### Backup Strategy
- Database backups daily
- Configuration files backup
- Firmware backups
- User data encryption

## Support and Resources

### Documentation
- API documentation in `/docs`
- Hardware schematics in `/hardware`
- Troubleshooting guides

### Community Support
- GitHub Issues
- Stack Overflow
- IoT Forums

### Professional Services
- System integration
- Custom development
- Training and support

## Conclusion

Your Smart Home Automation system is now ready for use. The system provides comprehensive home monitoring and control with real-time data, automated operations, and mobile access. Regular maintenance and monitoring will ensure optimal performance and security.