# 🚀 KONFIGURASI BACKEND SERVER DEPLOYMENT

## 📱 UPDATE URL SERVER YANG SUDAH DI-DEPLOY

Anda sudah deploy backend ke server. Sekarang perlu update URL di aplikasi Flutter.

### 🔧 CARA UPDATE BASE URL:

#### Method 1: Update Langsung di Code
Edit file: `kostraktor/lib/providers/auth_provider.dart`

```dart
// Line 143-145, update URL production:
static const String _prodDefaultBaseUrl =
    'https://your-actual-server.com/api/v1'; // 👈 GANTI URL INI
```

#### Method 2: Override saat Build (Recommended)
```bash
# Build dengan URL custom:
flutter build apk --release --dart-define=API_BASE_URL=https://your-server.com/api/v1

# Build production (pakai URL di _prodDefaultBaseUrl):
flutter build apk --release --dart-define=ENV=prod
```

### 🌐 CONTOH URL SERVER:

**Jika deploy di VPS/Cloud:**
```dart
static const String _prodDefaultBaseUrl = 'https://api.kostraktor.com/api/v1';
static const String _prodDefaultBaseUrl = 'https://kostraktor-api.herokuapp.com/api/v1';
static const String _prodDefaultBaseUrl = 'https://your-domain.com/api/v1';
```

**Jika deploy di Railway/Vercel/Netlify:**
```dart
static const String _prodDefaultBaseUrl = 'https://your-app.railway.app/api/v1';
static const String _prodDefaultBaseUrl = 'https://your-app.vercel.app/api/v1';
```

**Jika deploy di server local dengan domain:**
```dart
static const String _prodDefaultBaseUrl = 'http://192.168.1.100:8000/api/v1';
static const String _prodDefaultBaseUrl = 'http://your-local-server:8000/api/v1';
```

### ✅ LANGKAH DEPLOYMENT:

#### Step 1: Update URL Server
1. **Kasih tahu URL server yang sudah di-deploy**
2. Update `_prodDefaultBaseUrl` dengan URL tersebut
3. Atau gunakan `--dart-define=API_BASE_URL=xxx` saat build

#### Step 2: Test Server
```bash
# Test apakah server berjalan:
curl -X POST https://your-server.com/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@kostraktor.com&password=admin123"
```

#### Step 3: Build Production APK
```bash
cd kostraktor

# Option A: Build dengan ENV prod (pakai _prodDefaultBaseUrl):
flutter build apk --release --dart-define=ENV=prod

# Option B: Build dengan URL override:
flutter build apk --release --dart-define=API_BASE_URL=https://your-server.com/api/v1

# Option C: Build debug untuk testing:
flutter build apk --debug --dart-define=API_BASE_URL=https://your-server.com/api/v1
```

#### Step 4: Test APK
1. Install APK baru di HP
2. Test login dengan akun: `admin@kostraktor.com / admin123`
3. Pastikan connect ke server production

### 🔧 TROUBLESHOOTING SERVER:

#### Error 524 (Timeout):
- Server mungkin masih starting up
- Check server logs
- Pastikan port 8000 accessible

#### Connection Refused:
- Server tidak running
- Firewall blocking
- URL/Port salah

#### CORS Error:
- Add CORS headers di backend
- Allow origin dari aplikasi

### 📋 CURRENT STATUS:

**URL yang dikonfigurasi saat ini:**
```
Dev: http://dev-api.kostraktor.duaenam.id/api/v1
Prod: https://your-actual-server.com/api/v1 (perlu update)
Local: http://127.0.0.1:8000/api/v1
```

**Test result untuk URL saat ini:**
- `dev-api.kostraktor.duaenam.id` = Error 524 (timeout)
- Server mungkin belum fully deployed atau ada masalah

### 🎯 NEXT STEPS:

1. **Kasih tahu URL server yang benar** yang sudah Anda deploy
2. **Update konfigurasi** dengan URL tersebut
3. **Build APK baru** dengan server production
4. **Test login** dengan server yang baru

### 📞 INFO YANG DIBUTUHKAN:

Tolong kasih tahu:
- **URL server yang sudah di-deploy** (contoh: https://kostraktor.railway.app)
- **Platform deployment** (VPS, Heroku, Railway, Vercel, etc.)
- **Status server** (apakah sudah running dan accessible)

Setelah dapat info tersebut, saya akan update konfigurasi dan build APK production yang benar! 🚀