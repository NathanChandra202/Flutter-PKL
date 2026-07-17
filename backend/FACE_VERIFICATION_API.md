# Face Verification API Documentation

## Endpoint: POST `/api/verify/face-match`

Endpoint untuk verifikasi identitas pengguna dengan membandingkan foto KTP dan foto selfie.

### Request

**Headers:**
- `Authorization: Bearer <access_token>`
- `Content-Type: multipart/form-data`

**Body (Form Data):**
- `ktp_image`: File (required) - Foto KTP dalam format JPG/PNG
- `selfie_image`: File (required) - Foto selfie dalam format JPG/PNG

### Response Format

#### Success Response (200 OK)

```json
{
  "success": true,
  "verified": true,
  "message": "Verifikasi identitas berhasil! Anda sekarang dapat melanjutkan ke pembayaran.",
  "similarity": 0.85,
  "similarity_percentage": 85.0,
  "ocr_nik": "1234567890123456",
  "can_proceed": true
}
```

#### Error Responses (200 OK with success: false)

##### 1. Foto Buram (Blur Detection)

```json
{
  "success": false,
  "verified": false,
  "message": "Foto KTP terlalu buram atau tidak jelas. Silakan ambil foto ulang dengan pencahayaan yang lebih baik dan pastikan kamera tidak bergetar.",
  "error": "Foto KTP terlalu buram atau tidak jelas...",
  "error_type": "blur",
  "image_type": "ktp", // atau "selfie"
  "blur_score": 45.23,
  "can_retry": true,
  "suggestion": "Silakan ambil foto ktp ulang dengan:\n• Pencahayaan yang lebih baik\n• Kamera yang stabil (tidak bergerak)\n• Fokus yang jelas"
}
```

##### 2. Pencahayaan Tidak Tepat (Brightness Detection)

**Foto Terlalu Gelap:**
```json
{
  "success": false,
  "verified": false,
  "message": "Foto KTP terlalu gelap. Silakan ambil foto di tempat dengan pencahayaan yang lebih terang.",
  "error": "Foto KTP terlalu gelap...",
  "error_type": "brightness",
  "image_type": "ktp", // atau "selfie"
  "brightness_score": 35.5,
  "can_retry": true,
  "suggestion": "Foto ktp terlalu gelap. Tips:\n• Ambil foto di tempat yang lebih terang\n• Gunakan lampu tambahan jika perlu\n• Hindari bayangan pada wajah"
}
```

**Foto Terlalu Terang:**
```json
{
  "success": false,
  "verified": false,
  "message": "Foto selfie terlalu terang atau overexposed. Silakan kurangi pencahayaan atau hindari cahaya langsung.",
  "error": "Foto selfie terlalu terang...",
  "error_type": "brightness",
  "image_type": "selfie",
  "brightness_score": 235.8,
  "can_retry": true,
  "suggestion": "Foto selfie terlalu terang. Tips:\n• Kurangi pencahayaan langsung\n• Hindari flash yang terlalu kuat\n• Jangan menghadap langsung ke jendela/cahaya terang"
}
```

##### 3. Wajah Tidak Terdeteksi (No Face Detection)

```json
{
  "success": false,
  "verified": false,
  "message": "Wajah tidak terdeteksi pada foto selfie. Pastikan wajah terlihat jelas, menghadap kamera, dan tidak tertutup masker, kacamata, atau objek lain.",
  "error": "Wajah tidak terdeteksi pada foto selfie...",
  "error_type": "no_face",
  "image_type": "selfie", // atau "ktp"
  "detail": "No face detected",
  "can_retry": true,
  "suggestion": "Wajah tidak terdeteksi pada foto selfie. Tips:\n• Pastikan wajah terlihat jelas dan tidak tertutup\n• Wajah menghadap langsung ke kamera\n• Lepas masker, kacamata hitam, atau aksesoris yang menutupi wajah\n• Pastikan pencahayaan cukup"
}
```

##### 4. Wajah Tidak Cocok (Face Not Matched)

```json
{
  "success": false,
  "verified": false,
  "message": "Wajah pada foto KTP dan selfie tidak cocok. Pastikan Anda menggunakan KTP Anda sendiri dan foto selfie yang jelas.",
  "error": "Wajah pada foto KTP dan selfie tidak cocok...",
  "error_type": "not_matched",
  "similarity": 0.42,
  "can_retry": true,
  "suggestion": "Wajah tidak cocok. Pastikan:\n• Anda menggunakan KTP Anda sendiri\n• Foto selfie menampilkan wajah Anda dengan jelas\n• Tidak ada orang lain dalam foto\n• Kedua foto memiliki kualitas yang baik"
}
```

##### 5. Kesalahan Sistem (System Error)

```json
{
  "success": false,
  "verified": false,
  "message": "Gagal melakukan verifikasi wajah: Internal error",
  "error": "Gagal melakukan verifikasi wajah: Internal error",
  "error_type": "system_error",
  "detail": "Internal error",
  "can_retry": true,
  "suggestion": "Terjadi kesalahan sistem. Silakan coba lagi atau hubungi customer service jika masalah berlanjut."
}
```

## Error Types

| Error Type | Deskripsi | User Action |
|------------|-----------|-------------|
| `blur` | Foto terlalu buram atau tidak fokus | Ambil foto ulang dengan kamera stabil dan fokus jelas |
| `brightness` | Pencahayaan terlalu gelap atau terlalu terang | Sesuaikan pencahayaan atau posisi |
| `no_face` | Wajah tidak terdeteksi pada foto | Pastikan wajah terlihat jelas dan tidak tertutup |
| `not_matched` | Wajah di KTP dan selfie tidak cocok | Gunakan KTP sendiri dan foto selfie yang jelas |
| `system_error` | Kesalahan sistem internal | Coba lagi atau hubungi customer service |

## Quality Thresholds

### Blur Detection (Laplacian Variance)
- **Clear**: variance > 70.0
- **Blurry**: variance ≤ 70.0

### Brightness Detection (Mean Pixel Value)
- **Too Dark**: brightness < 40
- **Adequate**: 40 ≤ brightness ≤ 220
- **Too Bright**: brightness > 220

### Face Similarity
- **Matched**: similarity > threshold (model: Facenet)
- **Not Matched**: similarity ≤ threshold

## Frontend Integration Guide

### Handling Responses

```javascript
// Example Flutter/Dart code
Future<void> verifyFace(File ktpImage, File selfieImage) async {
  final response = await api.verifyFace(ktpImage, selfieImage);
  
  if (response['success']) {
    // Verifikasi berhasil
    showSuccessDialog(response['message']);
    navigateToPayment();
  } else {
    // Verifikasi gagal
    final errorType = response['error_type'];
    final imageType = response['image_type'];
    final suggestion = response['suggestion'];
    
    switch (errorType) {
      case 'blur':
        showRetryDialog(
          title: 'Foto Buram',
          message: response['message'],
          suggestion: suggestion,
          retryAction: () => retakePhoto(imageType)
        );
        break;
        
      case 'brightness':
        showRetryDialog(
          title: 'Masalah Pencahayaan',
          message: response['message'],
          suggestion: suggestion,
          retryAction: () => retakePhoto(imageType)
        );
        break;
        
      case 'no_face':
        showRetryDialog(
          title: 'Wajah Tidak Terdeteksi',
          message: response['message'],
          suggestion: suggestion,
          retryAction: () => retakePhoto(imageType)
        );
        break;
        
      case 'not_matched':
        showRetryDialog(
          title: 'Wajah Tidak Cocok',
          message: response['message'],
          suggestion: suggestion,
          retryAction: () => retakeAllPhotos()
        );
        break;
        
      default:
        showErrorDialog(response['message']);
    }
  }
}
```

### Retry Logic

1. **Single Photo Retry**: Jika error pada satu foto (blur, brightness, no_face), user hanya perlu mengulang foto yang bermasalah
2. **Both Photos Retry**: Jika error not_matched, user sebaiknya mengulang kedua foto
3. **Max Retry**: Batasi retry maksimal 3-5 kali sebelum menyarankan hubungi customer service

### UI/UX Recommendations

1. **Preview Before Submit**: Tampilkan preview foto sebelum submit untuk memastikan kualitas
2. **Camera Guidelines**: Tampilkan guidelines saat mengambil foto (frame wajah, tips pencahayaan)
3. **Real-time Quality Check**: Jika memungkinkan, deteksi blur/brightness di client-side sebelum upload
4. **Clear Error Messages**: Tampilkan pesan error yang jelas dengan suggestion dari API
5. **Progress Indicator**: Tampilkan loading saat proses verifikasi (bisa 5-10 detik)

## Testing

### Test Cases

1. **Happy Path**: Upload KTP dan selfie dengan kualitas baik → Berhasil
2. **Blur Test**: Upload foto buram → Error blur dengan suggestion
3. **Dark Test**: Upload foto gelap → Error brightness dengan suggestion
4. **Bright Test**: Upload foto overexposed → Error brightness dengan suggestion
5. **No Face Test**: Upload foto tanpa wajah → Error no_face
6. **Different Person**: Upload KTP dan selfie orang berbeda → Error not_matched
7. **Covered Face**: Upload selfie dengan masker → Error no_face

## Notes

- File yang diupload akan dihapus otomatis jika verifikasi gagal
- File yang diupload akan disimpan di database jika verifikasi berhasil
- OCR NIK dari KTP akan diekstrak dan divalidasi (optional)
- User profile akan diupdate dengan status `is_face_verified = True` setelah verifikasi berhasil
