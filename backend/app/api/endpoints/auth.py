from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

from app.api import deps
from app.core import security
from app.core.config import settings
from app.models.user import User, UserProfile
from app.models.role import Role

router = APIRouter()

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    nama_lengkap: str
    nik: str
    role_name: str = "Customer"

class Token(BaseModel):
    access_token: str
    token_type: str

class GoogleLoginRequest(BaseModel):
    id_token: str

@router.post("/register", response_model=dict)
def register(user_in: UserCreate, db: Session = Depends(deps.get_db)):
    user = db.query(User).filter(User.email == user_in.email).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this email already exists in the system.",
        )
        
    role = db.query(Role).filter(Role.name == user_in.role_name).first()
    if not role:
        # Create role if not exists (for initial setup)
        role = Role(name=user_in.role_name)
        db.add(role)
        db.commit()
        db.refresh(role)

    user = User(
        email=user_in.email,
        password_hash=security.get_password_hash(user_in.password),
        role_id=role.id
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    profile = UserProfile(
        user_id=user.id,
        nama_lengkap=user_in.nama_lengkap,
        nik=user_in.nik if user_in.nik else None
    )
    db.add(profile)
    db.commit()
    
    return {"message": "User registered successfully"}

@router.post("/login", response_model=Token)
def login(db: Session = Depends(deps.get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not security.verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    elif not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
        
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        subject=user.id, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/google", response_model=Token)
def google_login(payload: GoogleLoginRequest, db: Session = Depends(deps.get_db)):
    try:
        idinfo = google_id_token.verify_oauth2_token(
            payload.id_token, google_requests.Request()
        )
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid Google token")

    email = idinfo["email"]
    nama = idinfo.get("name", email.split("@")[0])

    user = db.query(User).filter(User.email == email).first()
    if not user:
        role = db.query(Role).filter(Role.name == "Customer").first()
        if not role:
            role = Role(name="Customer")
            db.add(role)
            db.commit()
            db.refresh(role)
        
        # Placeholder hash that can never be guessed
        placeholder_hash = security.get_password_hash(f"google_{email}_{datetime.now().timestamp()}")
        
        user = User(
            email=email,
            password_hash=placeholder_hash,
            role_id=role.id
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
        profile = UserProfile(
            user_id=user.id,
            nama_lengkap=nama,
            nik=None
        )
        db.add(profile)
        db.commit()
    elif not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        subject=user.id, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=dict)
def read_users_me(current_user: User = Depends(deps.get_current_active_user)):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role.name if current_user.role else None,
        "nama_lengkap": current_user.profile.nama_lengkap if current_user.profile else None,
        "phone": current_user.profile.no_hp if current_user.profile else None,
        "is_face_verified": current_user.profile.is_face_verified if current_user.profile else False,
        "current_room_id": current_user.current_room_id,
        "current_room_name": current_user.current_room.name if current_user.current_room else None,
    }

class UpdateProfileRequest(BaseModel):
    nama_lengkap: str | None = None
    phone: str | None = None

@router.patch("/me", response_model=dict)
def update_profile_me(
    req: UpdateProfileRequest,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
):
    profile = current_user.profile
    if not profile:
        raise HTTPException(status_code=404, detail="Profil tidak ditemukan")
    
    if req.nama_lengkap is not None:
        profile.nama_lengkap = req.nama_lengkap.strip()
    if req.phone is not None:
        profile.no_hp = req.phone.strip()
    
    db.commit()
    db.refresh(profile)
    
    return {
        "message": "Profil berhasil diperbarui",
        "nama_lengkap": profile.nama_lengkap,
        "phone": profile.no_hp,
    }

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class VerifyOtpRequest(BaseModel):
    email: EmailStr
    otp: str

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str

@router.post("/forgot-password")
def forgot_password(req: ForgotPasswordRequest, db: Session = Depends(deps.get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user:
        # Prevent user enumeration by returning success anyway, or throw 404. Since this is an internal app, 404 is fine.
        raise HTTPException(status_code=404, detail="Email tidak terdaftar")
    
    import random
    import string
    otp_code = ''.join(random.choices(string.digits, k=6))
    
    user.reset_otp = otp_code
    user.reset_otp_expires = datetime.now(timezone.utc) + timedelta(minutes=15)
    db.commit()
    
    from app.services.email_service import send_reset_password_email
    send_reset_password_email(user.email, otp_code)
    
    return {"message": "OTP sent to email"}

@router.post("/verify-reset-otp")
def verify_reset_otp(req: VerifyOtpRequest, db: Session = Depends(deps.get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or user.reset_otp != req.otp:
        raise HTTPException(status_code=400, detail="Kode OTP tidak valid")
    
    if user.reset_otp_expires and user.reset_otp_expires < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Kode OTP sudah kedaluwarsa")
        
    return {"message": "OTP valid"}

@router.post("/reset-password")
def reset_password(req: ResetPasswordRequest, db: Session = Depends(deps.get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or user.reset_otp != req.otp:
        raise HTTPException(status_code=400, detail="Kode OTP tidak valid")
        
    if user.reset_otp_expires and user.reset_otp_expires < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Kode OTP sudah kedaluwarsa")
        
    # Update password
    user.password_hash = security.get_password_hash(req.new_password)
    user.reset_otp = None
    user.reset_otp_expires = None
    db.commit()
    
    return {"message": "Password berhasil direset"}
