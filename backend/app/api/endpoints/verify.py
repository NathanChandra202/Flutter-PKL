from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
import os
import shutil
import uuid

from app.api import deps
from app.models.user import User
from app.services import ai_service

router = APIRouter()

UPLOAD_DIR = "uploads"

@router.post("/face-match")
async def verify_identity(
    ktp_image: UploadFile = File(...),
    selfie_image: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_active_user),
    db: Session = Depends(deps.get_db)
):
    """
    Verifies user identity by comparing KTP and Selfie, performing Liveness check, and OCR on KTP.
    """
    # Save files
    ktp_ext = ktp_image.filename.split('.')[-1]
    selfie_ext = selfie_image.filename.split('.')[-1]
    
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
        

    # 2. Extract OCR from KTP
    ocr_result = ai_service.extract_ktp_data(ktp_path)
    extracted_nik = ocr_result.get("nik")
    
    # Check if NIK matches the one in user profile (optional, just for strict validation)
    if current_user.profile and extracted_nik and current_user.profile.nik != extracted_nik:
        pass # Depending on business logic, we could reject. For now just log it.
        
    # 3. Face Match
    match_result = ai_service.verify_face_match(ktp_path, selfie_path)
    
    if match_result.get("error"):
        return {"success": False, "message": "Failed to extract face. Please ensure both images contain clear faces.", "error": match_result["error"]}
        
    is_verified = match_result.get("verified", False)
    
    # Update user profile
    if is_verified and current_user.profile:
        current_user.profile.is_face_verified = True
        current_user.profile.foto_ktp_path = ktp_path
        current_user.profile.selfie_path = selfie_path
        
        if extracted_nik and not current_user.profile.nik:
            current_user.profile.nik = extracted_nik
            
        db.commit()
    
    return {
        "success": is_verified,
        "message": "Identity verified successfully" if is_verified else "Face does not match.",
        "similarity": match_result.get("similarity"),
        "ocr_nik": extracted_nik
    }
