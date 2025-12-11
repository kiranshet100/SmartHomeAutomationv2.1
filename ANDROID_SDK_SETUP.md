# 🔧 Android SDK Installation Guide

## ⚠️ Required Before Building APK

Your Flutter app is configured, but you need Android SDK to build the APK.

---

## Step 1: Download Android Studio

1. Go to https://developer.android.com/studio
2. Click **"Download Android Studio"**
3. Accept terms and download the Windows installer

---

## Step 2: Install Android Studio

1. **Run the installer** (AndroidStudio-[version]-windows.exe)
2. Click **"Next"** through the setup wizard
3. Choose **"Standard"** installation
4. Select installation location (default is fine)
5. Wait for download and installation (~2-5 GB)

### During Installation:
- ✅ Android SDK Platform
- ✅ Android SDK Platform-Tools
- ✅ Android Emulator
- ✅ Intel HAXM (or check your CPU)

Let it finish - this is automatic.

---

## Step 3: First Launch & SDK Setup

1. **Launch Android Studio** (after installation)
2. Complete the initial setup wizard
3. When asked, select **"Custom"** installation
4. Ensure you have:
   - ✅ Android SDK
   - ✅ Android SDK Platform
   - ✅ Android Virtual Device (optional)
5. Click **"Finish"**

---

## Step 4: Configure Flutter

Open **PowerShell** and run:

```powershell
flutter config --android-sdk "C:\Users\ASUS\AppData\Local\Android\Sdk"
```

---

## Step 5: Accept Android Licenses

```powershell
flutter doctor --android-licenses
```

When prompted, **type `y` and press Enter** for each license:
- Android SDK License Agreement
- Android SDK Preview License
- Android NDK License
- Google Play Services License
- Google Play APK Signing Certificate Digest License

---

## Step 6: Verify Setup

```powershell
flutter doctor
```

You should see:
```
[✓] Flutter (Channel stable, 3.38.3...)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
...
```

If you see ✓ for Android toolchain, you're ready!

---

## Troubleshooting

### Issue: "Unable to locate Android SDK"

**Solution:**
```powershell
# Find where SDK is installed
Get-ChildItem "C:\Users\ASUS\AppData\Local\Android"

# Set the path
flutter config --android-sdk "C:\Users\ASUS\AppData\Local\Android\Sdk"

# Verify
flutter doctor
```

### Issue: License Errors

**Solution:**
```powershell
# Accept all licenses
flutter doctor --android-licenses

# Type 'y' for each prompt
```

### Issue: "Gradle wrapper not found"

**Solution:**
```powershell
cd "C:\Users\ASUS\Desktop\SmartHomeAutomationv2.1\mobile_app"
flutter clean
flutter pub get
```

### Issue: "NDK not found"

**Solution:**
Open Android Studio → Settings → Appearance & Behavior → System Settings → Android SDK
- Go to "SDK Tools" tab
- Check ✓ "NDK (Side by side)"
- Click "Apply" and "OK"

---

## Total Time Required

| Step | Time |
|------|------|
| Download installer | 5-10 min |
| Install Android Studio | 10-15 min |
| First launch setup | 10-20 min |
| Configure Flutter | 2 min |
| Accept licenses | 2 min |
| **Total** | **~30-50 minutes** |

---

## After Installation: Build APK

Once Android SDK is set up, build your APK:

```powershell
cd "C:\Users\ASUS\Desktop\SmartHomeAutomationv2.1"
.\build_apk.ps1
```

Or manually:
```powershell
cd mobile_app
flutter build apk --release
```

Your APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Need Help?

1. **Flutter Docs**: https://flutter.dev/docs/deployment/android
2. **Android Studio Help**: https://developer.android.com/studio/intro
3. **Common Issues**: https://flutter.dev/docs/get-started/install/windows#android-setup

---

**Once Android SDK is installed, you can build your APK anytime! ✨**
