# Smart Home Automation APK Build Script (PowerShell)
# Run from the project root directory

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Smart Home Automation - APK Build Script" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running from correct directory
if (-not (Test-Path "mobile_app\pubspec.yaml")) {
    Write-Host "Error: Please run this script from the SmartHomeAutomationv2.1 directory" -ForegroundColor Red
    Write-Host "Current directory: $PWD" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location "mobile_app"

# Step 1: Clean
Write-Host "[1/4] Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error during flutter clean" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Get dependencies
Write-Host "[2/4] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error getting dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Dependencies retrieved" -ForegroundColor Green
Write-Host ""

# Step 3: Build APK
Write-Host "[3/4] Building release APK..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Gray
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error building APK" -ForegroundColor Red
    Write-Host "Check the error messages above" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Build complete" -ForegroundColor Green
Write-Host ""

# Success message
Write-Host "================================================" -ForegroundColor Green
Write-Host "  BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "APK Location:" -ForegroundColor Cyan
Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
Write-Host ""
Write-Host "App Details:" -ForegroundColor Cyan
Write-Host "  Package: com.smarthomeautomation.app" -ForegroundColor White
Write-Host "  Version: 1.0.0" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Install on device: adb install -r app-release.apk" -ForegroundColor White
Write-Host "  2. Upload to Google Play Console" -ForegroundColor White
Write-Host "  3. Share for testing" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"
