from fastapi import APIRouter, UploadFile, File
import os
import shutil
import uuid

from app.services import ai_service

router = APIRouter()

UPLOAD_DIR = "uploads"

@router.post("/face-match")
async def verify_identity(
    ktp_image: UploadFile = File(...),
    selfie_image: UploadFile = File(...),
):
    """
    Public endpoint: Verifies user identity by comparing KTP face vs Selfie face.
    No authentication required — caller is responsible for ensuring the request is valid.
    
    Steps:
    1. Save uploaded files to disk
    2. Run blur + brightness quality checks
    3. Detect faces with RetinaFace
    4. Compare faces with VGG-Face (cosine, lenient threshold)
    5. Return result with detailed error info if failed
    """
    # ── Save uploaded files ────────────────────────────────────────────────────
    ktp_ext = (ktp_image.filename or "ktp.jpg").split(".")[-1].lower()
    selfie_ext = (selfie_image.filename or "selfie.jpg").split(".")[-1].lower()

    # Fallback to jpg if extension looks weird
    if ktp_ext not in ("jpg", "jpeg", "png", "webp"):
        ktp_ext = "jpg"
    if selfie_ext not in ("jpg", "jpeg", "png", "webp"):
        selfie_ext = "jpg"

    ktp_filename = f"{uuid.uuid4()}_ktp.{ktp_ext}"
    selfie_filename = f"{uuid.uuid4()}_selfie.{selfie_ext}"

    ktp_path = os.path.join(UPLOAD_DIR, "ktp", ktp_filename)
    selfie_path = os.path.join(UPLOAD_DIR, "selfies", selfie_filename)

    os.makedirs(os.path.dirname(ktp_path), exist_ok=True)
    os.makedirs(os.path.dirname(selfie_path), exist_ok=True)

    with open(ktp_path, "wb") as buffer:
        shutil.copyfileobj(ktp_image.file, buffer)

    with open(selfie_path, "wb") as buffer:
        shutil.copyfileobj(selfie_image.file, buffer)

    # ── OCR on KTP (best-effort, non-blocking) ─────────────────────────────────
    extracted_nik = None
    try:
        ocr_result = ai_service.extract_ktp_data(ktp_path)
        extracted_nik = ocr_result.get("nik")
    except Exception:
        pass  # OCR failure doesn't block verification

    # ── Face verification ──────────────────────────────────────────────────────
    match_result = ai_service.verify_face_match(ktp_path, selfie_path)

    # ── Cleanup uploaded files regardless of result ────────────────────────────
    def _cleanup():
        for p in [ktp_path, selfie_path]:
            try:
                if os.path.exists(p):
                    os.remove(p)
            except Exception:
                pass

    # ── Handle error results ───────────────────────────────────────────────────
    if match_result.get("error"):
        error_type = match_result.get("error_type", "unknown")
        error_msg = match_result.get("error", "Verifikasi wajah gagal.")
        image_type = match_result.get("image_type", "gambar")

        response = {
            "success": False,
            "verified": False,
            "message": error_msg,
            "error": error_msg,
            "error_type": error_type,
            "image_type": image_type,
            "can_retry": match_result.get("can_retry", True),
        }

        if error_type == "blur":
            response["blur_score"] = match_result.get("blur_score", 0)
            response["suggestion"] = (
                f"Silakan ambil foto {image_type} ulang dengan:\n"
                "• Kamera yang stabil (tahan dengan dua tangan)\n"
                "• Pencahayaan yang cukup dan merata\n"
                "• Jarak yang tepat (tidak terlalu dekat/jauh)"
            )

        elif error_type == "brightness":
            b_score = match_result.get("brightness_score", 0)
            response["brightness_score"] = b_score
            if b_score <= 30:
                response["suggestion"] = (
                    f"Foto {image_type} terlalu gelap. Tips:\n"
                    "• Pindah ke tempat yang lebih terang\n"
                    "• Nyalakan lampu tambahan\n"
                    "• Hindari bayangan menutupi wajah/KTP"
                )
            else:
                response["suggestion"] = (
                    f"Foto {image_type} terlalu terang. Tips:\n"
                    "• Hindari cahaya langsung (sinar matahari, lampu sorot)\n"
                    "• Matikan flash kamera\n"
                    "• Pindah ke area dengan cahaya tidak langsung"
                )

        elif error_type == "no_face":
            if image_type == "ktp":
                response["suggestion"] = (
                    "Wajah tidak terdeteksi pada foto KTP. Tips:\n"
                    "• Pastikan foto menampilkan seluruh KTP dengan jelas\n"
                    "• Hindari pantulan cahaya pada permukaan KTP\n"
                    "• Foto harus fokus dan tidak buram\n"
                    "• Pastikan bagian foto wajah di KTP tidak tertutup"
                )
            else:
                response["suggestion"] = (
                    "Wajah tidak terdeteksi pada foto selfie. Tips:\n"
                    "• Wajah harus menghadap langsung ke kamera\n"
                    "• Lepas masker, kacamata hitam, atau topi\n"
                    "• Pastikan cahaya menerangi wajah dengan baik\n"
                    "• Jangan terlalu jauh dari kamera"
                )

        elif error_type == "not_matched":
            response["similarity"] = match_result.get("similarity", 0)
            response["suggestion"] = (
                "Wajah tidak cocok dengan KTP. Pastikan:\n"
                "• Anda menggunakan KTP milik Anda sendiri\n"
                "• Foto selfie menampilkan wajah Anda dengan jelas\n"
                "• Tidak ada orang lain dalam frame\n"
                "• Kedua foto berkualitas baik dan pencahayaan cukup"
            )

        else:
            response["suggestion"] = (
                "Terjadi kesalahan sistem. Silakan coba lagi.\n"
                "Jika masalah berlanjut, hubungi customer service."
            )

        _cleanup()
        return response

    # ── Success path ───────────────────────────────────────────────────────────
    if not match_result.get("verified", False):
        _cleanup()
        return {
            "success": False,
            "verified": False,
            "message": "Verifikasi wajah gagal.",
            "similarity": match_result.get("similarity"),
            "can_retry": True,
        }

    _cleanup()
    return {
        "success": True,
        "verified": True,
        "message": "Verifikasi identitas berhasil! Anda sekarang dapat melanjutkan ke pembayaran.",
        "similarity": match_result.get("similarity"),
        "similarity_percentage": (
            round(match_result.get("similarity", 0) * 100, 2)
            if match_result.get("similarity") is not None
            else None
        ),
        "ocr_nik": extracted_nik,
        "can_proceed": True,
    }
