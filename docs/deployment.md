# Deployment Guide

## Backend Deployment

### Option 1: Heroku Deployment

1. **Install Heroku CLI**
   ```bash
   npm install -g heroku
   heroku login
   ```

2. **Create Heroku App**
   ```bash
   cd SmartHomeAutomation/backend
   heroku create your-smart-home-backend
   ```

3. **Configure Environment Variables**
   ```bash
   heroku config:set MONGODB_URI="your_mongodb_connection_string"
   heroku config:set JWT_SECRET="your_jwt_secret"
   heroku config:set MQTT_BROKER="mqtt://your-mqtt-broker"
   ```

4. **Deploy**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git push heroku main
   ```

### Option 2: AWS EC2 Deployment

1. **Launch EC2 Instance**
   - Choose Ubuntu Server
   - Configure security groups (ports 22, 80, 443, 3000, 1883)

2. **Install Dependencies**
   ```bash
   sudo apt update
   sudo apt install nodejs npm mongodb
   ```

3. **Setup MQTT Broker**
   ```bash
   sudo apt install mosquitto
   sudo systemctl start mosquitto
   ```

4. **Deploy Application**
   ```bash
   git clone your-repo
   cd backend
   npm install
   npm start
   ```

5. **Setup PM2 for Production**
   ```bash
   npm install -g pm2
   pm2 start server.js
   pm2 startup
   pm2 save
   ```

### Option 3: Docker Deployment

1. **Create Dockerfile**
   ```dockerfile
   FROM node:16
   WORKDIR /app
   COPY package*.json ./
   RUN npm install
   COPY . .
   EXPOSE 3000
   CMD ["npm", "start"]
   ```

2. **Create docker-compose.yml**
   ```yaml
   version: '3.8'
   services:
     backend:
       build: .
       ports:
         - "3000:3000"
       environment:
         - MONGODB_URI=mongodb://mongo:27017/smart_home
         - MQTT_BROKER=mqtt://mosquitto:1883
     mongo:
       image: mongo:5.0
       ports:
         - "27017:27017"
     mosquitto:
       image: eclipse-mosquitto:2.0
       ports:
         - "1883:1883"
   ```

3. **Deploy**
   ```bash
   docker-compose up -d
   ```

## Mobile App Deployment

### Android Deployment

1. **Configure Firebase**
   - Create Firebase project
   - Add Android app with package name
   - Download google-services.json

2. **Build APK**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

3. **Sign APK (Optional)**
   ```bash
   keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   flutter build apk --release --target-platform android-arm64
   ```

### iOS Deployment

1. **Configure Firebase**
   - Add iOS app to Firebase project
   - Download GoogleService-Info.plist

2. **Build for iOS**
   ```bash
   flutter clean
   flutter pub get
   flutter build ios --release
   ```

3. **Deploy to TestFlight**
   - Open Xcode
   - Archive and upload to App Store Connect
   - Configure TestFlight testing

## Hardware Setup

### ESP32 Firmware Upload

1. **Install Arduino IDE**
   - Download from arduino.cc
   - Install ESP32 board support

2. **Configure Board**
   - Board: ESP32 Dev Module
   - Upload Speed: 115200
   - CPU Frequency: 240MHz

3. **Install Libraries**
   - DHT sensor library
   - PubSubClient for MQTT
   - WiFi library (built-in)

4. **Upload Firmware**
   - Open smart_home.ino
   - Update WiFi credentials
   - Update MQTT broker details
   - Upload to ESP32

### Hardware Assembly

1. **Wire Components**
   - Follow wiring diagram in hardware.md
   - Test connections with multimeter
   - Secure connections with solder/hot glue

2. **Power Supply**
   - Use regulated 5V/2A power supply
   - Add fuse protection
   - Ground all components properly

3. **Enclosure**
   - Mount components in project box
   - Provide ventilation for ESP32
   - Seal water-sensitive components

## Cloud Services Setup

### MongoDB Atlas

1. **Create Cluster**
   - Sign up for MongoDB Atlas
   - Create free tier cluster
   - Configure network access

2. **Get Connection String**
   - Go to Clusters > Connect
   - Choose "Connect your application"
   - Copy connection string

### Firebase Setup

1. **Create Project**
   - Go to Firebase Console
   - Create new project
   - Enable Authentication and Firestore

2. **Configure Authentication**
   - Enable Email/Password sign-in
   - Configure authorized domains

3. **Setup Firestore Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

## Monitoring and Maintenance

### Backend Monitoring

1. **PM2 Monitoring**
   ```bash
   pm2 monit
   pm2 logs
   ```

2. **Health Check Endpoint**
   ```javascript
   app.get('/health', (req, res) => {
     res.json({ status: 'OK', timestamp: new Date() });
   });
   ```

### Database Backup

1. **MongoDB Backup**
   ```bash
   mongodump --db smart_home --out backup
   ```

2. **Automated Backups**
   ```bash
   crontab -e
   0 2 * * * mongodump --db smart_home --out /backup/$(date +\%Y\%m\%d)
   ```

## Security Configuration

### SSL/TLS Setup

1. **Let's Encrypt (Free SSL)**
   ```bash
   sudo apt install certbot
   sudo certbot --nginx
   ```

2. **Environment Variables**
   - Store secrets in environment variables
   - Use strong passwords
   - Rotate API keys regularly

### Firewall Configuration

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 1883/tcp
sudo ufw enable
```

## Troubleshooting

### Common Issues

1. **ESP32 Not Connecting**
   - Check WiFi credentials
   - Verify MQTT broker accessibility
   - Check serial output for errors

2. **Backend Not Starting**
   - Verify environment variables
   - Check MongoDB connection
   - Review PM2 logs

3. **Mobile App Crashes**
   - Check Firebase configuration
   - Verify API endpoints
   - Check device permissions

### Logs and Debugging

1. **Backend Logs**
   ```bash
   pm2 logs smart-home-backend
   ```

2. **ESP32 Debugging**
   - Use Arduino Serial Monitor
   - Check MQTT broker logs
   - Verify sensor connections

3. **Mobile App Logs**
   - Use Flutter DevTools
   - Check Firebase console
   - Enable verbose logging