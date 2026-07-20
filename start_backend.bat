@echo off
echo Starting Backend Server...
echo.
cd backend
python seed_data.py
echo.
echo Backend server starting at http://127.0.0.1:8000
echo API Documentation: http://127.0.0.1:8000/docs
echo.
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000