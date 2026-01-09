# Smart Home Automation System

A comprehensive smart home automation solution connecting a Mobile App (Flutter) with IoT Hardware (ESP32) using Firebase for real-time communication and authentication.

## 🚀 Features

### Mobile App (Flutter)
- **Real-time Device Control**: Toggle lights, fans, and appliances instantly.
- **Live Sensor Monitoring**: Visualize Temperature, Humidity, Gas Levels, and Motion detection.
- **Energy Monitoring**: Track energy usage (Wh/kWh) and estimated costs in real-time.
- **Voice Control**: Control devices using voice commands.
- **User Authentication**: Secure login via Firebase Auth.
- **Smart Connectivity**: Automatically syncs with ESP32 via Firebase Realtime Database.

### Hardware (ESP32)
- **Relay Control**: Physical switching of appliances (Active Low/High configurable).
- **Multi-Sensor Integration**:
    - **DHT11**: Temperature & Humidity.
    - **PIR**: Motion detection.
    - **MQ2/Gas**: Gas leak/smoke detection.
- **Energy Calculation**: Computes power consumption based on active time and wattage.
- **Offline Safety**: Keeps running basic logic even if WiFi disconnects.

## 🏗️ Tech Stack

- **Mobile Application**: Flutter (Dart)
- **Firmware**: C++ (Arduino Framework for ESP32)
- **Backend & Database**: Firebase Realtime Database
- **Authentication**: Firebase Authentication

## 🛠️ Setup Instructions

### 1. Hardware Setup (ESP32)
1.  Navigate to the `firmware` directory.
2.  Open `smart_home.ino` in Arduino IDE or VS Code (with PlatformIO).
3.  Install necessary libraries:
    -   `WiFi`
    -   `HTTPClient`
    -   `ArduinoJson`
    -   `DHT sensor library`
4.  **Configuration**:
    -   Update `WIFI_SSID` and `WIFI_PASS` with your WiFi credentials.
    -   Update `FIREBASE_HOST` and `FIREBASE_AUTH` with your Firebase project details.
5.  Select your board (e.g., "DOIT ESP32 DEVKIT V1") and upload the code.

### 2. Mobile App Setup
1.  Navigate to the `mobile_app` directory:
    ```bash
    cd mobile_app
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  **Firebase Config**:
    -   Ensure `google-services.json` (for Android) is placed in `android/app/`.
    -   Ensure `GoogleService-Info.plist` (for iOS) is placed in `ios/Runner/`.
4.  Run the app:
    ```bash
    flutter run
    ```

## 📊 Data Structure (Firebase)

The system uses the following structure in Firebase Realtime Database:

```json
{
  "devices": {
    "esp32_device_01": {
      "relays": {
        "relay1": 0,
        "relay2": 0,
        "timestamp": 123456789
      },
      "sensors": {
        "temperature": 25.5,
        "humidity": 60,
        "gasLevel": 12,
        "motion": 1
      },
      "energy": {
        "total_kWh": 1.2,
        "estimatedCost": 7.8
      }
    }
  }
}
```

## 🤝 Contributing

Feel free to fork this repository and submit pull requests for any improvements or new features!