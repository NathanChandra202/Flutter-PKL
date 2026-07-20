@echo off
cd /d "%~dp0"
echo Starting Kostraktor Backend Server...
call venv\Scripts\activate.bat
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
pause
