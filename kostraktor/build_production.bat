@echo off
title Build Kostraktor APK
echo ========================================
echo       BUILD KOSTRAKTOR APK
echo ========================================
echo.

echo [1/4] Cleaning previous builds...
flutter clean
echo     ✅ Build cache cleaned
echo.

echo [2/4] Getting dependencies...
flutter pub get
echo     ✅ Dependencies updated
echo.

echo [3/4] Building debug APK...
flutter build apk --debug
echo     ✅ Debug APK built successfully!
echo.

echo [4/4] APK Location:
echo     📱 kostraktor\build\app\outputs\flutter-apk\app-debug.apk
echo.

echo ========================================
echo            BUILD COMPLETE!
echo ========================================
echo.
echo Next steps:
echo 1. Copy APK to your phone
echo 2. Install and test
echo 3. Login with: admin@kostraktor.com / admin123
echo.
pause