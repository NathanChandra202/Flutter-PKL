@echo off
echo Building Flutter App...
echo.
flutter clean
flutter pub get
flutter build apk --debug
echo.
echo ✅ APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-debug.apk
echo.
pause