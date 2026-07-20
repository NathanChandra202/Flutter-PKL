# Run this from the backend folder:
# .\run_backend.ps1

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Run the FastAPI server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
