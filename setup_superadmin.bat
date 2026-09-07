@echo off
echo ========================================
echo   Setup SuperAdmin Account
echo ========================================
echo.

cd backend

echo [1/3] Creating SuperAdmin role and account...
python seed_data.py
echo.

echo [2/3] Verifying SuperAdmin exists...
python -c "from app.db.session import SessionLocal; from app.models.user import User; db = SessionLocal(); user = db.query(User).filter(User.email=='superadmin@kostraktor.com').first(); print(f'\nSuperAdmin: {user.email if user else \"NOT FOUND\"}'); print(f'Role: {user.role.name if user and user.role else \"NO ROLE\"}')"
echo.

echo [3/3] Setup complete!
echo.
echo ========================================
echo   SuperAdmin Credentials:
echo ========================================
echo   Email: superadmin@kostraktor.com
echo   Password: superadmin123
echo ========================================
echo.
echo Next steps:
echo 1. Restart backend: python -m uvicorn app.main:app --reload
echo 2. Restart admin dashboard: cd kostraktor-admin ^&^& npm run dev
echo 3. Login at http://localhost:3000
echo.
pause
