@echo off
title Kostraktor Development Server
echo ========================================
echo   KOSTRAKTOR DEVELOPMENT SERVER
echo ========================================
echo.

echo [1/3] Starting Backend Server...
cd ..\backend
start "Backend Server" cmd /k "python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000"
echo     ✅ Backend starting at http://127.0.0.1:8000
echo.

echo [2/3] Waiting for backend to initialize...
timeout /t 3 >nul
echo     ✅ Backend ready!
echo.

echo [3/3] Starting Flutter Hot Reload...
cd ..\kostraktor
echo     📱 Flutter app starting in debug mode...
echo.
flutter run