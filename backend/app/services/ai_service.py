import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

import cv2
import numpy as np
import pytesseract
from deepface import DeepFace
import re
import tempfile

def check_image_blur(image_path: str) -> tuple[bool, float]:
    """
    Check if an image is blurry using Laplacian variance method.
    Returns (is_clear, variance_score)
    """
    try:
        img = cv2.imread(image_path)
        if img is None:
            return False, 0.0
        
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        variance = cv2.Laplacian(gray, cv2.CV_64F).var()
        
        # Threshold 20: Very lenient, because physical KTPs often appear blurry
        # variance < 20 = very blurry (reject)
        # variance >= 20 = acceptable quality
        is_clear = variance >= 20.0
        return is_clear, variance
    except Exception as e:
        print(f"Error checking blur: {e}")
        return False, 0.0

def check_image_brightness(image_path: str) -> tuple[bool, float]:
    """
    Check if an image has adequate brightness.
    Returns (is_bright_enough, brightness_score)
    """
    try:
        img = cv2.imread(image_path)
        if img is None:
            return False, 0.0
        
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        brightness = np.mean(gray)
        
        # Wider range: 20-245 to be very lenient for real-world photos
        is_adequate = 20 < brightness < 245
        return is_adequate, brightness
    except Exception as e:
        print(f"Error checking brightness: {e}")
        return False, 0.0

def _save_array_to_temp(arr: np.ndarray, suffix: str = ".jpg") -> str:
    """
    Save a numpy image array to a temporary file and return the path.
    Caller is responsible for deleting the file after use.
    """
    # arr is float32 in range [0,1] from DeepFace.extract_faces(normalize_face=True)
    # Convert to uint8 [0,255] for saving
    img_uint8 = (arr * 255).astype(np.uint8)

    # DeepFace returns RGB, cv2.imwrite expects BGR
    if img_uint8.ndim == 3 and img_uint8.shape[2] == 3:
        img_uint8 = cv2.cvtColor(img_uint8, cv2.COLOR_RGB2BGR)

    tmp = tempfile.NamedTemporaryFile(suffix=suffix, delete=False)
    tmp_path = tmp.name
    tmp.close()
    cv2.imwrite(tmp_path, img_uint8)
    return tmp_path

def verify_face_match(img1_path: str, img2_path: str) -> dict:
    """
    Verifies if two faces belong to the same person.
    Performs multiple quality checks before face verification.
    
    Flow:
    1. Blur check on both images
    2. Brightness check on both images
    3. Extract and detect faces using RetinaFace
    4. Save face crops to temp files
    5. Compare faces using VGG-Face (more tolerant than Facenet for KTP vs selfie)
    """
    tmp1_path = None
    tmp2_path = None

    try:
        # ── 1. Blur check ─────────────────────────────────────────────────────
        ktp_clear, ktp_score = check_image_blur(img1_path)
        selfie_clear, selfie_score = check_image_blur(img2_path)
        
        if not ktp_clear:
            return {
                "error": f"Foto KTP terlalu buram (skor: {round(ktp_score,1)}). Silakan ambil foto ulang dengan kamera yang stabil dan pencahayaan yang cukup.",
                "verified": False,
                "error_type": "blur",
                "image_type": "ktp",
                "blur_score": round(ktp_score, 2),
                "can_retry": True,
            }
        
        if not selfie_clear:
            return {
                "error": f"Foto selfie terlalu buram (skor: {round(selfie_score,1)}). Silakan ambil foto ulang dengan kamera yang stabil.",
                "verified": False,
                "error_type": "blur",
                "image_type": "selfie",
                "blur_score": round(selfie_score, 2),
                "can_retry": True,
            }
        
        # ── 2. Brightness check ────────────────────────────────────────────────
        ktp_bright, ktp_brightness = check_image_brightness(img1_path)
        selfie_bright, selfie_brightness = check_image_brightness(img2_path)
        
        if not ktp_bright:
            msg = (
                "Foto KTP terlalu gelap. Ambil di tempat yang lebih terang."
                if ktp_brightness <= 30
                else "Foto KTP terlalu terang / overexposed. Kurangi cahaya langsung."
            )
            return {
                "error": msg,
                "verified": False,
                "error_type": "brightness",
                "image_type": "ktp",
                "brightness_score": round(ktp_brightness, 2),
                "can_retry": True,
            }
        
        if not selfie_bright:
            msg = (
                "Foto selfie terlalu gelap. Ambil di tempat yang lebih terang."
                if selfie_brightness <= 30
                else "Foto selfie terlalu terang / overexposed. Kurangi cahaya langsung."
            )
            return {
                "error": msg,
                "verified": False,
                "error_type": "brightness",
                "image_type": "selfie",
                "brightness_score": round(selfie_brightness, 2),
                "can_retry": True,
            }
        
        # ── 3. Extract faces ───────────────────────────────────────────────────
        def extract_with_fallback(image_path):
            for detector in ["retinaface", "opencv"]:
                try:
                    faces = DeepFace.extract_faces(
                        img_path=image_path,
                        detector_backend=detector,
                        enforce_detection=True,
                        align=True,
                        normalize_face=True,
                    )
                    if faces:
                        return np.asarray(faces[0]["face"])
                except Exception:
                    continue
            raise ValueError("No face detected by any detector")

        try:
            face1_arr = extract_with_fallback(img1_path)
        except Exception as e:
            return {
                "error": "Wajah tidak terdeteksi pada foto KTP. Pastikan wajah pada KTP terlihat jelas, tidak tertutup, dan foto tidak terlipat.",
                "verified": False,
                "error_type": "no_face",
                "image_type": "ktp",
                "detail": str(e),
                "can_retry": True,
            }

        try:
            face2_arr = extract_with_fallback(img2_path)
        except Exception as e:
            return {
                "error": "Wajah tidak terdeteksi pada foto selfie. Pastikan wajah menghadap kamera, tidak pakai masker/kacamata hitam, dan pencahayaan cukup.",
                "verified": False,
                "error_type": "no_face",
                "image_type": "selfie",
                "detail": str(e),
                "can_retry": True,
            }

        # ── 4. Save face crops to temp files ──────────────────────────────────
        tmp1_path = _save_array_to_temp(face1_arr, suffix="_ktp_face.jpg")
        tmp2_path = _save_array_to_temp(face2_arr, suffix="_selfie_face.jpg")

        # ── 5. Verify face match ───────────────────────────────────────────────
        # VGG-Face with cosine distance is more robust for KTP vs selfie comparison
        # Default cosine threshold for VGG-Face is 0.40; we allow up to 0.55
        result = DeepFace.verify(
            img1_path=tmp1_path,
            img2_path=tmp2_path,
            model_name="VGG-Face",
            distance_metric="cosine",
            enforce_detection=False,
            detector_backend="skip",
        )

        distance = result.get("distance", 1.0)
        threshold = result.get("threshold", 0.40)
        # Use an extremely lenient threshold: 0.65 for KTP vs selfie scenarios
        LENIENT_THRESHOLD = 0.65
        is_verified = distance <= LENIENT_THRESHOLD
        similarity = round(max(0.0, 1.0 - distance), 4)

        if not is_verified:
            return {
                "verified": False,
                "distance": round(distance, 4),
                "similarity": similarity,
                "error": "Wajah pada foto KTP dan selfie tidak cocok. Pastikan Anda menggunakan KTP Anda sendiri, wajah terlihat jelas, dan pencahayaan baik.",
                "error_type": "not_matched",
                "can_retry": True,
            }

        return {
            "verified": True,
            "distance": round(distance, 4),
            "similarity": similarity,
            "message": "Verifikasi wajah berhasil! Wajah pada KTP dan selfie cocok.",
        }

    except Exception as e:
        print(f"Unexpected error in verify_face_match: {e}")
        return {
            "error": f"Gagal melakukan verifikasi wajah: {str(e)}",
            "verified": False,
            "error_type": "system_error",
            "detail": str(e),
            "can_retry": True,
        }
    finally:
        # Always clean up temp files
        for p in [tmp1_path, tmp2_path]:
            if p and os.path.exists(p):
                try:
                    os.remove(p)
                except Exception:
                    pass


def extract_ktp_data(ktp_path: str) -> dict:
    """
    Extracts NIK and Name from KTP using OCR.
    """
    try:
        img = cv2.imread(ktp_path)
        if img is None:
            return {"error": "Could not read image"}
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Simple preprocessing
        gray = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]
        
        text = pytesseract.image_to_string(gray)
        
        # Basic regex to find NIK (16 digits)
        nik_match = re.search(r'\b\d{16}\b', text)
        nik = nik_match.group(0) if nik_match else None
        
        return {
            "raw_text": text,
            "nik": nik
        }
    except Exception as e:
        return {"error": str(e)}
