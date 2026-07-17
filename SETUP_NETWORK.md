# Setup Network untuk Testing Flutter App dengan Backend

## IP Address Komputer
**IP Address Saat Ini:** `192.168.1.40`

## Cara Menjalankan Backend Server

### Option 1: Manual dengan Uvicorn
```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Option 2: Menggunakan PowerShell Script
Edit file `run_backend.ps1` dan pastikan menggunakan `--host 0.0.0.0`:
```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Konfigurasi Flutter App

File: `kostraktor/lib/providers/auth_provider.dart`

```dart
static const String _baseUrl = 'http://192.168.1.40:8000/api/v1';
```

### ⚠️ PENTING: Update IP Address

Jika IP address komputer berubah, Anda perlu:

1. **Cek IP address komputer:**
   ```powershell
   ipconfig
   ```
   Cari IPv4 Address yang bukan `127.0.0.1` atau `169.254.*`

2. **Update file `auth_provider.dart`:**
   Ganti IP address di line yang berisi `_baseUrl`

3. **Hot Reload Flutter App:**
   Tekan `r` di terminal flutter run

## Troubleshooting

### Error: Connection Refused
- ✅ Pastikan backend server jalan dengan `--host 0.0.0.0`
- ✅ Pastikan IP address di Flutter app sesuai dengan IP komputer
- ✅ Pastikan komputer dan device Android di jaringan WiFi yang sama

### Error: Timeout
- ✅ Cek firewall Windows apakah memblok port 8000
- ✅ Pastikan tidak ada VPN yang aktif
- ✅ Pastikan WiFi router tidak memblok komunikasi antar device

## Testing

Test backend dari browser di device Android:
```
http://192.168.1.40:8000/
```

Harusnya muncul response:
```json
{"message": "Welcome to Kostraktor Backend API"}
```

## Status Saat Ini
✅ Backend server: Running di `0.0.0.0:8000`  
✅ Flutter app: Configured untuk `192.168.1.40:8000`  
✅ CORS: Configured untuk accept semua origins (development mode)
