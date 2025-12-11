# Smart Home Automation APK Build Guide

## Prerequisites Setup

### 1. Install Android SDK
You need to install Android Studio and SDK:
- Download Android Studio: https://developer.android.com/studio
- Run the installer and complete the setup wizard
- This will install Android SDK, NDK, and other required tools

### 2. Configure Android SDK Path
After installing Android Studio, run:
```powershell
flutter config --android-sdk "C:\Users\ASUS\AppData\Local\Android\Sdk"
```

### 3. Accept Android Licenses
```powershell
flutter doctor --android-licenses
```
Accept all licenses when prompted.

## Build Configuration Files

### ✅ Already Configured:
1. **Package Name**: `com.smarthomeautomation.app`
2. **Keystore**: `smart_home.keystore` (created)
3. **Signing Config**: Updated in `build.gradle.kts`
4. **Permissions**: Added to `AndroidManifest.xml`
5. **Version**: `1.0.0+1`

### Key Files:
- Keystore Location: `mobile_app/smart_home.keystore`
- Signing Config: `mobile_app/android/key.properties`
- Manifest: `mobile_app/android/app/src/main/AndroidManifest.xml`

## Build APK (After Android Setup)

### From Project Directory:
```powershell
cd "C:\Users\ASUS\Desktop\SmartHomeAutomationv2.1\mobile_app"

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

### Output APK Location:
```
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

## Keystore Information

**Location**: `mobile_app/smart_home.keystore`
**Alias**: `smart_home`
**Store Password**: `smartHome@123`
**Key Password**: `smartHome@123`

### Important Notes:
⚠️ Keep the keystore file safe - you'll need it for future app updates
⚠️ The passwords are stored in `android/key.properties`

## Firebase Configuration

Your app uses Firebase with these services:
- Authentication
- Realtime Database
- Storage

Make sure your Firebase project:
1. Has `com.smarthomeautomation.app` as the Android package
2. Has the correct database URL configured
3. Has security rules properly set

## App Size & Requirements

- Min SDK: 21 (Android 5.0)
- Target SDK: Latest
- Architecture: ARM64, ARM32, x86_64

## Distribution

### To Play Store:
1. Build APK (or App Bundle): `flutter build appbundle --release`
2. Sign in to Google Play Console
3. Upload the signed AAB
4. Fill app details and release

### Direct APK Distribution:
1. Build APK: `flutter build apk --release`
2. Output: `build/app/outputs/flutter-apk/app-release.apk`
3. Share via link or install directly on device

## Troubleshooting

If build fails:
```powershell
# Clean everything
flutter clean
cd android
gradlew clean
cd ..

# Rebuild
flutter pub get
flutter build apk --release
```

## Next Steps

1. ✅ Install Android SDK
2. ✅ Configure Flutter for Android
3. ✅ Accept Android licenses
4. ✅ Run build command
5. ✅ APK ready for testing and distribution
