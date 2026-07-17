# Troubleshooting Face Verification

## ❌ Problem: Verifikasi Wajah Gagal Meskipun Foto Jelas

Jika Anda sudah memfoto KTP dengan jelas dan selfie dengan baik namun verifikasi tetap gagal, berikut adalah langkah-langkah debugging yang harus dicoba:

### 1. Cek Backend Server

**Pastikan backend server sudah running:**

```bash
cd "c:\projek PKL\Flutter-PKL\backend"
venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Expected output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### 2. Cek IP Address Backend

**Update IP di Flutter app:**

File: `lib/providers/auth_provider.dart`

```dart
static const String _baseUrl = 'http://192.168.1.40:8000/api/v1';
```

**Ganti `192.168.1.40` dengan IP address komputer yang menjalankan backend.**

**Cara cek IP address:**

Windows:
```bash
ipconfig
```

Cari bagian "IPv4 Address" di adapter yang aktif (WiFi atau Ethernet).

### 3. Test Backend API Langsung

**Test endpoint verification:**

```bash
curl -X POST "http://192.168.1.40:8000/api/v1/verify/face-match" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "ktp_image=@path/to/ktp.jpg" \
  -F "selfie_image=@path/to/selfie.jpg"
```

### 4. Cek Logs Backend

**Monitor backend logs untuk error:**

Backend akan menampilkan logs ketika ada request masuk. Lihat error messages untuk debugging:

```
INFO:     192.168.1.100:52342 - "POST /api/v1/verify/face-match HTTP/1.1" 200 OK
```

Atau jika ada error:
```
ERROR:    Exception in ASGI application
Traceback (most recent call last):
  ...
```

### 5. Common Issues & Solutions

#### Issue 1: "Anda harus login terlebih dahulu"

**Problem:** User belum login atau token expired.

**Solution:**
1. Logout dan login ulang
2. Pastikan `_accessToken` tidak null di AuthProvider

#### Issue 2: "Terjadi kesalahan koneksi"

**Problem:** Flutter app tidak bisa koneksi ke backend.

**Solutions:**
1. Pastikan backend running
2. Cek IP address sudah benar
3. Pastikan firewall tidak block port 8000
4. Cek WiFi - harus di network yang sama

**Windows Firewall:**
```powershell
# Allow port 8000
netsh advfirewall firewall add rule name="Allow Port 8000" dir=in action=allow protocol=TCP localport=8000
```

#### Issue 3: "Foto terlalu buram"

**Problem:** Blur score < 70

**Solutions:**
- Gunakan pencahayaan yang lebih baik
- Stabilkan kamera (jangan goyang)
- Fokus dengan baik sebelum ambil foto
- Bersihkan lensa kamera

**Debug blur score:**

Backend akan return blur_score di response. Cek nilainya:
- Score < 70 = Too blurry (rejected)
- Score 70-100 = Acceptable
- Score > 100 = Clear

#### Issue 4: "Foto terlalu gelap/terang"

**Problem:** Brightness < 40 atau > 220

**Solutions:**
- Too dark (< 40): Tambah pencahayaan
- Too bright (> 220): Kurangi pencahayaan, hindari cahaya langsung

#### Issue 5: "Wajah tidak terdeteksi"

**Problem:** DeepFace tidak bisa detect face

**Solutions:**
- Pastikan wajah terlihat jelas
- Wajah harus menghadap kamera
- Lepas masker, kacamata hitam
- Pastikan tidak ada objek menutupi wajah
- Coba dengan pencahayaan lebih baik

#### Issue 6: "Wajah tidak cocok"

**Problem:** Similarity score terlalu rendah

**Possible Causes:**
1. Menggunakan KTP orang lain
2. Foto KTP tidak jelas
3. Foto selfie tidak menampilkan wajah dengan baik
4. Perubahan penampilan drastis (rambut, kumis, dll)

**Solutions:**
- Pastikan KTP adalah milik sendiri
- Ambil foto KTP di tempat terang dengan fokus jelas
- Selfie dengan wajah menghadap kamera
- Lepas aksesoris yang menutupi wajah

### 6. Check Model Files

**Pastikan model DeepFace sudah terdownload:**

Backend akan otomatis download model saat pertama kali digunakan. Lokasi default:
- Windows: `C:\Users\YourUsername\.deepface\`
- Models: Facenet, RetinaFace

**If model download fails:**

```python
# Test di Python console
from deepface import DeepFace

# Download models manually
DeepFace.build_model('Facenet')
DeepFace.build_model('RetinaFace')
```

### 7. Enable Debug Mode

**Update auth_provider.dart untuk debug:**

```dart
Future<String?> verifyFaceMatch(
  Uint8List ktpBytes,
  Uint8List selfieBytes,
) async {
  if (_accessToken == null) {
    return 'Anda harus login terlebih dahulu.';
  }

  print('DEBUG: Starting face verification');
  print('DEBUG: KTP bytes length: ${ktpBytes.length}');
  print('DEBUG: Selfie bytes length: ${selfieBytes.length}');
  print('DEBUG: Base URL: $_baseUrl');
  print('DEBUG: Access token: ${_accessToken?.substring(0, 20)}...');

  try {
    // ... rest of code
    
    print('DEBUG: Response status: ${response.statusCode}');
    print('DEBUG: Response body: ${response.body}');
    
    // ... rest of code
  } catch (e) {
    print('DEBUG: Exception: $e');
    // ... rest of code
  }
}
```

### 8. Test Images Quality

**Manually test image quality before upload:**

```python
# Test script
import cv2
import numpy as np

def check_blur(image_path):
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    variance = cv2.Laplacian(gray, cv2.CV_64F).var()
    print(f"Blur score: {variance}")
    if variance > 70:
        print("✓ Clear image")
    else:
        print("✗ Blurry image")

def check_brightness(image_path):
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    brightness = np.mean(gray)
    print(f"Brightness: {brightness}")
    if 40 < brightness < 220:
        print("✓ Good brightness")
    else:
        print("✗ Poor brightness")

# Test your images
check_blur("path/to/ktp.jpg")
check_brightness("path/to/ktp.jpg")
check_blur("path/to/selfie.jpg")
check_brightness("path/to/selfie.jpg")
```

### 9. API Response Examples

**Success Response:**
```json
{
  "success": true,
  "verified": true,
  "message": "Verifikasi identitas berhasil! Anda sekarang dapat melanjutkan ke pembayaran.",
  "similarity": 0.85,
  "similarity_percentage": 85.0,
  "can_proceed": true
}
```

**Blur Error:**
```json
{
  "success": false,
  "verified": false,
  "message": "Foto selfie terlalu buram atau tidak jelas...",
  "error_type": "blur",
  "image_type": "selfie",
  "blur_score": 45.23,
  "can_retry": true,
  "suggestion": "Silakan ambil foto selfie ulang dengan:\n• Pencahayaan yang lebih baik\n• Kamera yang stabil\n• Fokus yang jelas"
}
```

### 10. Network Configuration

**If using Android Emulator:**

Backend URL should be: `http://10.0.2.2:8000/api/v1`

**If using Real Device:**

1. Connect device and PC to same WiFi
2. Use PC's local IP: `http://192.168.1.40:8000/api/v1`
3. Make sure firewall allows connections

### 11. Recommended Image Guidelines

**KTP Photo:**
- Resolution: Min 800x600px
- Format: JPG/PNG
- Size: Max 5MB
- Lighting: Even, no shadows
- Angle: Straight from above
- Focus: All text readable

**Selfie Photo:**
- Resolution: Min 640x480px
- Format: JPG/PNG
- Size: Max 5MB
- Lighting: Bright but not overexposed
- Angle: Face directly to camera
- Distance: Face fills ~60% of frame
- Background: Plain, simple
- Face: No mask, sunglasses, or obstructions

### 12. Contact Support

Jika masalah masih berlanjut setelah mencoba semua solusi di atas:

1. Capture screenshots of error messages
2. Save backend logs
3. Note down:
   - Device model & OS version
   - Backend server OS & Python version
   - Exact steps to reproduce
   - Image file sizes and formats

## Quick Checklist ✓

- [ ] Backend server running
- [ ] IP address correct in Flutter app
- [ ] Same WiFi network
- [ ] Firewall allows port 8000
- [ ] User is logged in
- [ ] Images are clear and well-lit
- [ ] Face is visible in both photos
- [ ] DeepFace models downloaded
- [ ] No network errors in logs

## Still Having Issues?

Try these diagnostic commands:

```bash
# Backend health check
curl http://192.168.1.40:8000/

# Expected: {"message":"Welcome to Kostraktor Backend API"}

# Check if verify endpoint exists
curl http://192.168.1.40:8000/docs

# This should show FastAPI Swagger docs
```

## Performance Tips

- Use good quality camera (min 5MP)
- Natural daylight is best
- Avoid flash photography
- Keep phone steady when taking photos
- Crop images if too large (> 2MB)
- Use landscape mode for KTP photo

## Security Notes

- Photos are temporarily stored on server
- Photos are deleted on verification failure
- Photos are encrypted in transit (use HTTPS in production)
- Access token required for all requests
- Rate limiting recommended to prevent abuse
