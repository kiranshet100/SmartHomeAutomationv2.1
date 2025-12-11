# 📱 Smart Home Automation - APK Build Ready

## ✅ What's Been Done

Your Flutter app is now **configured and ready to build into an APK**. Here's what has been completed:

### 1. **App Configuration**
- ✅ Updated package name to `com.smarthomeautomation.app`
- ✅ Set version to `1.0.0+1`
- ✅ Updated app label to "Smart Home"

### 2. **Android Signing**
- ✅ Generated keystore file: `smart_home.keystore`
- ✅ Configured signing in `build.gradle.kts`
- ✅ Created signing credentials file: `android/key.properties`

**Keystore Details:**
```
File: mobile_app/smart_home.keystore
Alias: smart_home
Store Password: smartHome@123
Key Password: smartHome@123
```

### 3. **Permissions & Manifest**
- ✅ Added Internet permission
- ✅ Added Record Audio (for voice control)
- ✅ Added POST_NOTIFICATIONS (for push notifications)
- ✅ Added Camera permission
- ✅ Added Location permissions
- ✅ Added Foreground Service permission
- ✅ Added Boot completion permission

### 4. **Real-time Features Implemented**
- ✅ Firebase Realtime Energy Monitoring
- ✅ Real-time cost tracking with rupees (₹) symbol
- ✅ Live cost graph visualization
- ✅ Relay-wise energy display

---

## 🚀 How to Build APK

### **Prerequisite: Install Android SDK**

Before building, you need Android SDK installed:

1. **Download & Install Android Studio**
   - https://developer.android.com/studio
   - Run the installer
   - Complete the setup wizard (it will install Android SDK automatically)

2. **Configure Flutter (after Android Studio install)**
   ```powershell
   flutter config --android-sdk "C:\Users\ASUS\AppData\Local\Android\Sdk"
   flutter doctor --android-licenses
   # Accept all licenses when prompted
   ```

3. **Verify setup**
   ```powershell
   flutter doctor
   # Should show ✓ for Android toolchain
   ```

### **Build the APK**

#### **Option 1: Using the Build Script (Easiest)**
```powershell
# From PowerShell (Windows 11/10)
cd "C:\Users\ASUS\Desktop\SmartHomeAutomationv2.1"
.\build_apk.ps1
```

Or for Command Prompt:
```cmd
cd C:\Users\ASUS\Desktop\SmartHomeAutomationv2.1
build_apk.bat
```

#### **Option 2: Manual Build**
```powershell
cd "C:\Users\ASUS\Desktop\SmartHomeAutomationv2.1\mobile_app"

# Clean and prepare
flutter clean
flutter pub get

# Build release APK
flutter build apk --release
```

### **Output Location**
After successful build, your APK will be at:
```
C:\Users\ASUS\Desktop\SmartHomeAutomationv2.1\mobile_app\build\app\outputs\flutter-apk\app-release.apk
```

---

## 📦 What's Inside Your APK

- **Size**: ~150-200 MB (typical for Flutter apps with Firebase)
- **Min Android**: 5.0 (SDK 21)
- **Target Android**: Latest
- **Features**:
  - Firebase Authentication
  - Real-time Device Control
  - Energy Monitoring with Live Graphs
  - Voice Commands
  - Smart Automation
  - Push Notifications
  - Dark/Light Theme

---

## 🧪 Testing APK

### **Install on Connected Device**
```powershell
adb install -r "build\app\outputs\flutter-apk\app-release.apk"
```

### **Create Virtual Device**
```powershell
# List available AVDs
emulator -list-avds

# Run an AVD
emulator -avd <avd_name>

# Then install APK
adb install -r "build\app\outputs\flutter-apk\app-release.apk"
```

---

## 📤 Distribution Options

### **Option 1: Google Play Store (Recommended)**
1. Sign up at https://play.google.com/console
2. Create new app
3. Build App Bundle instead of APK:
   ```powershell
   flutter build appbundle --release
   ```
4. Upload to Play Console
5. Fill app metadata and release

### **Option 2: Direct APK Link**
1. Build APK (follow steps above)
2. Host on cloud storage (Google Drive, OneDrive, Firebase)
3. Share download link
4. Users can install directly

### **Option 3: Firebase App Distribution**
1. Set up Firebase CLI
2. Upload APK:
   ```powershell
   firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk \
     --app 1:123456789:android:abc123 \
     --release-notes "Version 1.0" \
     --testers-file testers.txt
   ```

---

## 🔒 Security Notes

### **Keystore File**
- ⚠️ **Never commit** `smart_home.keystore` to git
- ✅ Already in `.gitignore` (should be)
- 💾 **Backup** this file securely
- 🔑 Keep passwords safe - you need them for future updates

### **Firebase Security**
- Verify your Realtime Database rules
- Enable authentication properly
- Use environment-specific credentials

### **App Signing**
- Same keystore must be used for all future updates
- If lost, you cannot update the app on Play Store

---

## ❓ Troubleshooting

### **"No Android SDK found"**
```powershell
# Install Android Studio and run:
flutter config --android-sdk "C:\Users\ASUS\AppData\Local\Android\Sdk"
```

### **Build Fails with Gradle Error**
```powershell
cd mobile_app
flutter clean
cd android
gradlew clean
cd ..
flutter pub get
flutter build apk --release
```

### **APK Too Large**
```powershell
# Build split APKs by architecture
flutter build apk --release --split-per-abi
```

### **Version Code Issues**
```powershell
# In pubspec.yaml, increment the +number:
# version: 1.0.0+2  (for next release)
```

---

## 📋 Checklist Before Publishing

- [ ] Android SDK installed and configured
- [ ] Flutter doctor shows no issues
- [ ] APK builds successfully
- [ ] Tested on at least one Android device
- [ ] Firebase credentials verified
- [ ] Permissions checked and reasonable
- [ ] App version updated
- [ ] Keystore file backed up securely
- [ ] Privacy policy created
- [ ] App screenshots prepared (for Play Store)
- [ ] App description written (for Play Store)

---

## 🎯 Next Steps

1. **Install Android SDK** (if not done)
2. **Run build script** or manual build
3. **Test APK** on device
4. **Choose distribution** method
5. **Submit to Play Store** or share link

---

## 📞 Support Files

- `APK_BUILD_GUIDE.md` - Detailed build guide
- `build_apk.ps1` - PowerShell build script
- `build_apk.bat` - Batch build script
- `mobile_app/android/key.properties` - Signing config
- `mobile_app/smart_home.keystore` - Signing certificate

---

**Ready to build?** Follow the steps above and your APK will be ready in minutes! 🚀
