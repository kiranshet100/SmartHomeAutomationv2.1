@echo off
REM Smart Home Automation APK Build Script
REM Run this script from the project root directory

echo ================================================
echo  Smart Home Automation - APK Build Script
echo ================================================
echo.

REM Check if running from correct directory
if not exist "mobile_app\pubspec.yaml" (
    echo Error: Please run this script from the SmartHomeAutomationv2.1 directory
    echo Current directory: %cd%
    pause
    exit /b 1
)

cd mobile_app

echo [1/4] Cleaning previous builds...
call flutter clean
if errorlevel 1 (
    echo Error during flutter clean
    pause
    exit /b 1
)
echo ✓ Clean complete

echo.
echo [2/4] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo Error getting dependencies
    pause
    exit /b 1
)
echo ✓ Dependencies retrieved

echo.
echo [3/4] Building release APK...
echo This may take several minutes...
call flutter build apk --release
if errorlevel 1 (
    echo Error building APK
    echo Check the error messages above
    pause
    exit /b 1
)
echo ✓ Build complete

echo.
echo ================================================
echo  BUILD SUCCESSFUL!
echo ================================================
echo.
echo APK Location:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
echo App Details:
echo   Package: com.smarthomeautomation.app
echo   Version: 1.0.0
echo.
echo Next Steps:
echo   1. Install on device: adb install -r app-release.apk
echo   2. Upload to Google Play Console
echo   3. Share for testing
echo.
pause
