# Run this from the backend folder:
# .\run_backend.ps1

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
