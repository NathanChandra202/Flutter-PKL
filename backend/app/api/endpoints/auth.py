from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr

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
        nik=user_in.nik
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

@router.get("/me", response_model=dict)
def read_users_me(current_user: User = Depends(deps.get_current_active_user)):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role.name if current_user.role else None,
        "nama_lengkap": current_user.profile.nama_lengkap if current_user.profile else None,
        "is_face_verified": current_user.profile.is_face_verified if current_user.profile else False
    }
