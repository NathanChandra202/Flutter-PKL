# Face Verification System Improvements

## 🎯 Overview

Sistem verifikasi wajah telah ditingkatkan dengan deteksi kualitas gambar yang lebih baik dan error handling yang lebih informatif untuk memberikan pengalaman pengguna yang lebih baik.

## ✨ Fitur Baru

### 1. **Deteksi Blur (Kualitas Fokus)**
- Menggunakan metode Laplacian Variance untuk mendeteksi gambar buram
- Threshold: variance > 70.0 dianggap jelas
- Memberikan feedback spesifik jika foto terlalu buram

**Contoh Response:**
```json
{
  "error": "Foto selfie terlalu buram atau tidak jelas...",
  "error_type": "blur",
  "blur_score": 45.23,
  "suggestion": "Silakan ambil foto selfie ulang dengan:\n• Pencahayaan yang lebih baik\n• Kamera yang stabil (tidak bergerak)\n• Fokus yang jelas"
}
```

### 2. **Deteksi Brightness (Pencahayaan)**
- Mendeteksi foto yang terlalu gelap (< 40) atau terlalu terang (> 220)
- Memberikan saran spesifik berdasarkan kondisi pencahayaan

**Contoh Response - Terlalu Gelap:**
```json
{
  "error": "Foto KTP terlalu gelap...",
  "error_type": "brightness",
  "brightness_score": 35.5,
  "suggestion": "Foto ktp terlalu gelap. Tips:\n• Ambil foto di tempat yang lebih terang\n• Gunakan lampu tambahan jika perlu\n• Hindari bayangan pada wajah"
}
```

**Contoh Response - Terlalu Terang:**
```json
{
  "error": "Foto selfie terlalu terang...",
  "error_type": "brightness",
  "brightness_score": 235.8,
  "suggestion": "Foto selfie terlalu terang. Tips:\n• Kurangi pencahayaan langsung\n• Hindari flash yang terlalu kuat\n• Jangan menghadap langsung ke jendela/cahaya terang"
}
```

### 3. **Deteksi Wajah yang Lebih Baik**
- Pesan error yang lebih spesifik untuk foto tanpa wajah
- Suggestion yang jelas untuk user

**Contoh Response:**
```json
{
  "error": "Wajah tidak terdeteksi pada foto selfie...",
  "error_type": "no_face",
  "suggestion": "Wajah tidak terdeteksi pada foto selfie. Tips:\n• Pastikan wajah terlihat jelas dan tidak tertutup\n• Wajah menghadap langsung ke kamera\n• Lepas masker, kacamata hitam, atau aksesoris yang menutupi wajah\n• Pastikan pencahayaan cukup"
}
```

### 4. **Verifikasi Kesesuaian Wajah**
- Feedback yang jelas jika wajah tidak cocok
- Termasuk similarity score untuk debugging

**Contoh Response:**
```json
{
  "error": "Wajah pada foto KTP dan selfie tidak cocok...",
  "error_type": "not_matched",
  "similarity": 0.42,
  "suggestion": "Wajah tidak cocok. Pastikan:\n• Anda menggunakan KTP Anda sendiri\n• Foto selfie menampilkan wajah Anda dengan jelas\n• Tidak ada orang lain dalam foto\n• Kedua foto memiliki kualitas yang baik"
}
```

### 5. **Success Response yang Informatif**
- Similarity percentage untuk transparency
- Clear indication untuk proceed ke pembayaran

**Contoh Response:**
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

## 🔄 Alur Verifikasi

```
┌─────────────────┐
│  Upload Images  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Check Blur     │ ──► Blur? ──► Return Error + Suggestion
└────────┬────────┘
         │ Clear
         ▼
┌─────────────────┐
│ Check Brightness│ ──► Too Dark/Bright? ──► Return Error + Suggestion
└────────┬────────┘
         │ Adequate
         ▼
┌─────────────────┐
│  Detect Faces   │ ──► No Face? ──► Return Error + Suggestion
└────────┬────────┘
         │ Face Found
         ▼
┌─────────────────┐
│  Verify Match   │ ──► Not Matched? ──► Return Error + Suggestion
└────────┬────────┘
         │ Matched
         ▼
┌─────────────────┐
│ Update Profile  │
│  & Save Images  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Return Success  │
└─────────────────┘
```

## 📊 Quality Metrics

### Blur Detection
- **Metode**: Laplacian Variance
- **Threshold**: 70.0
- **Range**:
  - 0-70: Very blurry (rejected)
  - 70-100: Slightly blurry but acceptable
  - >100: Clear

### Brightness Detection
- **Metode**: Mean Pixel Value
- **Range**:
  - <40: Too dark (rejected)
  - 40-220: Adequate (accepted)
  - >220: Too bright (rejected)

### Face Detection
- **Backend**: RetinaFace
- **Features**: Face alignment & normalization

### Face Matching
- **Model**: Facenet
- **Output**: Distance & Similarity Score

## 🛠️ Technical Implementation

### Files Modified

1. **`app/services/ai_service.py`**
   - Added `check_image_brightness()` function
   - Enhanced `check_image_blur()` with better thresholds
   - Improved `verify_face_match()` with comprehensive checks
   - Better error messages and suggestions

2. **`app/api/endpoints/verify.py`**
   - Enhanced error handling
   - Added detailed suggestion generation
   - Cleanup uploaded files on error
   - Better success response format

### New Features in Code

```python
# Blur detection with adjustable threshold
def check_image_blur(image_path: str) -> tuple[bool, float]:
    # Variance > 70 = clear
    # Variance <= 70 = blurry
    
# Brightness detection
def check_image_brightness(image_path: str) -> tuple[bool, float]:
    # 40 < brightness < 220 = adequate
    # Otherwise = too dark or too bright

# Comprehensive verification
def verify_face_match(img1_path: str, img2_path: str) -> dict:
    # 1. Check blur
    # 2. Check brightness  
    # 3. Detect faces
    # 4. Verify match
    # All with detailed error messages
```

## 🎨 Frontend Integration

### Recommended UX Flow

1. **Before Upload**: Show camera guidelines
   ```
   📸 Tips for Clear Photos:
   • Hold phone steady
   • Good lighting (not too dark/bright)
   • Face clearly visible
   • No mask or sunglasses
   ```

2. **During Upload**: Show progress indicator
   ```
   ⏳ Verifying your identity...
   This may take a few seconds
   ```

3. **On Error**: Show specific error with retry option
   ```
   ❌ Foto Buram
   Foto selfie terlalu buram atau tidak jelas.
   
   Tips:
   • Pencahayaan yang lebih baik
   • Kamera yang stabil (tidak bergerak)
   • Fokus yang jelas
   
   [Ambil Ulang Foto Selfie] [Batal]
   ```

4. **On Success**: Show success and proceed
   ```
   ✅ Verifikasi Berhasil!
   Similarity: 85%
   
   [Lanjut ke Pembayaran]
   ```

### Sample Flutter Code

```dart
Future<void> handleVerification() async {
  try {
    showLoadingDialog('Memverifikasi identitas...');
    
    final response = await apiService.verifyFace(
      ktpImage: _ktpImage!,
      selfieImage: _selfieImage!,
    );
    
    hideLoadingDialog();
    
    if (response['success'] == true) {
      // Success
      showSuccessDialog(
        title: 'Verifikasi Berhasil!',
        message: response['message'],
        similarity: response['similarity_percentage'],
        onConfirm: () => navigateToPayment(),
      );
    } else {
      // Error with retry option
      final errorType = response['error_type'];
      final imageType = response['image_type'];
      final suggestion = response['suggestion'];
      
      showErrorDialogWithRetry(
        title: _getErrorTitle(errorType),
        message: response['message'],
        suggestion: suggestion,
        onRetry: () {
          if (imageType == 'ktp') {
            retakeKtpPhoto();
          } else if (imageType == 'selfie') {
            retakeSelfiePhoto();
          } else {
            retakeAllPhotos();
          }
        },
      );
    }
  } catch (e) {
    hideLoadingDialog();
    showErrorDialog('Terjadi kesalahan: $e');
  }
}

String _getErrorTitle(String errorType) {
  switch (errorType) {
    case 'blur': return 'Foto Buram';
    case 'brightness': return 'Masalah Pencahayaan';
    case 'no_face': return 'Wajah Tidak Terdeteksi';
    case 'not_matched': return 'Wajah Tidak Cocok';
    default: return 'Verifikasi Gagal';
  }
}
```

## 🧪 Testing Guide

### Manual Testing Scenarios

1. **✅ Happy Path**
   - Upload clear KTP and selfie photos
   - Expected: Success with high similarity score

2. **❌ Blurry Photo Test**
   - Upload an out-of-focus photo
   - Expected: Error with blur detection

3. **❌ Dark Photo Test**
   - Upload a photo taken in dark environment
   - Expected: Error with brightness (too dark)

4. **❌ Bright Photo Test**
   - Upload an overexposed photo
   - Expected: Error with brightness (too bright)

5. **❌ No Face Test**
   - Upload a photo without face
   - Expected: Error with no face detection

6. **❌ Masked Face Test**
   - Upload selfie with mask on
   - Expected: Error with no face or not matched

7. **❌ Different Person Test**
   - Upload KTP and selfie of different people
   - Expected: Error with not matched

### Automated Testing

```python
# test_face_verification.py
import pytest
from app.services import ai_service

def test_blur_detection_clear_image():
    is_clear, score = ai_service.check_image_blur("tests/fixtures/clear_image.jpg")
    assert is_clear == True
    assert score > 70.0

def test_blur_detection_blurry_image():
    is_clear, score = ai_service.check_image_blur("tests/fixtures/blurry_image.jpg")
    assert is_clear == False
    assert score <= 70.0

def test_brightness_detection_dark():
    is_adequate, brightness = ai_service.check_image_brightness("tests/fixtures/dark_image.jpg")
    assert is_adequate == False
    assert brightness < 40

def test_brightness_detection_bright():
    is_adequate, brightness = ai_service.check_image_brightness("tests/fixtures/bright_image.jpg")
    assert is_adequate == False
    assert brightness > 220

def test_verify_face_match_same_person():
    result = ai_service.verify_face_match(
        "tests/fixtures/person1_ktp.jpg",
        "tests/fixtures/person1_selfie.jpg"
    )
    assert result['verified'] == True
    assert result['similarity'] > 0.6

def test_verify_face_match_different_person():
    result = ai_service.verify_face_match(
        "tests/fixtures/person1_ktp.jpg",
        "tests/fixtures/person2_selfie.jpg"
    )
    assert result['verified'] == False
    assert result['error_type'] == 'not_matched'
```

## 📈 Monitoring & Analytics

### Recommended Metrics to Track

1. **Verification Success Rate**
   - Total verifications / Successful verifications
   - Target: >80%

2. **Error Distribution**
   - Blur errors: %
   - Brightness errors: %
   - No face errors: %
   - Not matched errors: %
   - System errors: %

3. **Retry Rate**
   - How many users retry after error
   - Average retries before success

4. **Quality Scores**
   - Average blur score for successful verifications
   - Average brightness score for successful verifications
   - Average similarity score for successful verifications

### Logging Example

```python
import logging

logger = logging.getLogger(__name__)

# Log verification attempts
logger.info(f"Face verification attempt: user_id={user_id}, ktp_blur={ktp_score:.2f}, selfie_blur={selfie_score:.2f}")

# Log errors
logger.warning(f"Face verification failed: user_id={user_id}, error_type={error_type}, image_type={image_type}")

# Log success
logger.info(f"Face verification success: user_id={user_id}, similarity={similarity:.2f}")
```

## 🔒 Security Considerations

1. **File Cleanup**: Files are deleted on verification failure to prevent accumulation
2. **Path Validation**: Uploaded files are saved with UUID to prevent path traversal
3. **Rate Limiting**: Consider adding rate limiting to prevent abuse
4. **File Size Limit**: Ensure max file size is enforced (e.g., 10MB)
5. **File Type Validation**: Only accept image files (JPG, PNG)

## 🚀 Future Enhancements

1. **Liveness Detection**: Detect if selfie is from a real person (not photo of photo)
2. **Anti-Spoofing**: Detect printed photos or screens
3. **Real-time Quality Check**: Client-side quality check before upload
4. **Multiple Face Detection**: Handle photos with multiple faces
5. **Pose Detection**: Ensure face is frontal
6. **Age Verification**: Compare age between KTP and selfie
7. **Document Authentication**: Verify KTP is authentic (not fake)

## 📞 Support

If users continue to experience issues after multiple retries:
1. Provide alternative verification method (manual review)
2. Customer service contact
3. Video call verification

## 📝 Changelog

### Version 2.0 (Current)
- ✅ Added blur detection with Laplacian Variance
- ✅ Added brightness detection
- ✅ Enhanced error messages with specific suggestions
- ✅ Added `can_retry` flag in responses
- ✅ Improved face detection error handling
- ✅ Added similarity percentage in success response
- ✅ File cleanup on verification failure
- ✅ Comprehensive API documentation

### Version 1.0 (Original)
- Basic face verification
- Simple error messages
- No quality checks
