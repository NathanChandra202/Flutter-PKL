# 🧪 GUIDE TESTING APLIKASI KOSTRAKTOR

## ✅ PERBAIKAN YANG SUDAH DILAKUKAN

### 1. Backend Server Configuration
- ✅ Fixed base URL: `http://127.0.0.1:8000/api/v1`
- ✅ Database seeded dengan akun admin dan user
- ✅ Backend server berjalan di localhost:8000

### 2. Akun Login yang Tersedia
```
Admin Account:
Email: admin@kostraktor.com
Password: admin123

User Account:  
Email: user@test.com
Password: test123
```

### 3. WhatsApp Configuration
- ✅ Updated admin WhatsApp number: `6282123456789`
- ✅ WhatsApp helper dengan multiple fallback methods
- ✅ Permission untuk WhatsApp sudah ditambahkan di AndroidManifest

## 🚀 CARA MENJALANKAN APLIKASI

### 1. Start Backend Server
```bash
cd backend
python seed_data.py
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

### 2. Build & Install APK
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### 3. Install APK ke HP
- APK location: `build\app\outputs\flutter-apk\app-debug.apk`
- Copy ke HP dan install
- Pastikan HP dan PC di jaringan WiFi yang sama

## 🧪 TESTING SCENARIOS

### 1. Test Login Admin
1. Buka aplikasi
2. Masuk dengan: `admin@kostraktor.com` / `admin123`
3. Harus masuk ke Admin Panel

### 2. Test Login User
1. Logout dari admin
2. Masuk dengan: `user@test.com` / `test123`  
3. Harus masuk ke halaman User biasa

### 3. Test WhatsApp Function
1. Login sebagai user
2. Pergi ke halaman Pembayaran atau Contact
3. Klik "Hubungi Admin via WhatsApp"
4. WhatsApp harus terbuka dengan pesan template

## 🔧 TROUBLESHOOTING

### Login Tidak Berhasil
**Error**: "Terjadi kesalahan koneksi"
**Solution**:
1. Pastikan backend server running: `http://127.0.0.1:8000`
2. Test API: `curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "username=admin@kostraktor.com&password=admin123" http://127.0.0.1:8000/api/v1/auth/login`
3. Cek HP dan PC di WiFi yang sama
4. Cek firewall Windows

### WhatsApp Tidak Terbuka
**Error**: "Tidak dapat membuka WhatsApp"
**Solutions**:
1. Install WhatsApp di HP
2. Ganti nomor admin di `lib/config/app_config.dart`
3. Rebuild app: `flutter build apk --debug`

### Permission Denied
**Error**: Aplikasi crash atau permission error
**Solution**:
1. Enable "Install from Unknown Sources"
2. Grant semua permissions yang diminta
3. Restart aplikasi

## 📱 FITUR YANG SUDAH AKTIF

### ✅ Authentication System
- Login/Register dengan backend API
- Role-based access (Admin/User)
- Session management dengan JWT token

### ✅ WhatsApp Integration  
- Hubungi admin via WhatsApp
- Template pesan pembayaran
- Multiple fallback URLs (app, web, API)
- Copy nomor jika WhatsApp tidak tersedia

### ✅ Face Verification
- KTP + Selfie verification
- AI-powered face matching
- Integration dengan FastAPI backend

### ✅ Booking System
- Room booking dengan payment countdown
- Admin approval system
- Payment confirmation via WhatsApp

## 🔗 API Endpoints

Base URL: `http://127.0.0.1:8000/api/v1`

### Authentication
- `POST /auth/login` - Login
- `GET /auth/me` - Get user profile

### Face Verification  
- `POST /verify/face-match` - Verify KTP vs Selfie

### Documentation
- `http://127.0.0.1:8000/docs` - Swagger API docs

## 📞 GANTI NOMOR WHATSAPP

Edit file `lib/config/app_config.dart`:
```dart
static const String adminWhatsAppNumber = '6282123456789'; // Ganti nomor ini
```

Format: `62XXXXXXXXXX` (dimulai dengan 62, tanpa +, spasi, atau tanda lain)

Setelah ganti, rebuild APK:
```bash
flutter build apk --debug
```

## 🎯 NEXT STEPS

1. **Test Semua Fitur**: Login, WhatsApp, Face verification, Booking
2. **Ganti Nomor WhatsApp**: Update dengan nomor admin yang benar
3. **Production Build**: `flutter build apk --release` untuk APK final
4. **Backend Production**: Deploy backend ke server publik untuk akses internet