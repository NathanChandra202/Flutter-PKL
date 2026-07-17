# Akun Login untuk Testing

Backend API sudah berjalan di `http://127.0.0.1:8000`

## Akun yang Tersedia

### 1. Admin Account
```
Email: admin@kostraktor.com
Password: admin123
```
- Akses ke admin panel
- Dapat approve/reject booking
- Manage rooms dan tools

### 2. User Account
```
Email: user@test.com
Password: test123
```
- Akun user biasa
- Dapat booking kamar
- Akses fitur jastip dan tool sharing

## Cara Menjalankan Backend

```bash
cd backend
python -m uvicorn app.main:app --reload
```

Backend akan berjalan di: `http://127.0.0.1:8000`
API Documentation: `http://127.0.0.1:8000/docs`

## Cara Reset Database

Jika perlu reset database dan recreate akun:

```bash
cd backend
python reset_db.py
python seed_data.py
```

## Troubleshooting

### Error "Terjadi kesalahan koneksi"
- Pastikan backend sudah running (`uvicorn app.main:app --reload`)
- Cek URL di `kostraktor/lib/providers/auth_provider.dart` baris 136
- Harus: `http://127.0.0.1:8000/api/v1`

### Error Login Failed
- Pastikan database sudah di-seed: `python seed_data.py`
- Cek akun ada di database
- Restart backend server

## Bug yang Sudah Diperbaiki

✅ Fixed: `ModuleNotFoundError: No module named 'email_validator'`
✅ Fixed: `ValueError: You have tensorflow 2.21.0 and this requires tf-keras package`
✅ Fixed: Incompatibility bcrypt 5.0.0 dengan passlib 1.7.4
✅ Fixed: Base URL Flutter app mengarah ke IP yang salah
✅ Fixed: Admin user tidak bisa login

## Update yang Dilakukan

1. Install `email-validator` dan `tf-keras`
2. Update `auth_provider.dart` base URL ke `http://127.0.0.1:8000/api/v1`
3. Replace passlib dengan native bcrypt di `security.py`
4. Reset dan reseed database dengan password yang benar
5. Tambah test user account
