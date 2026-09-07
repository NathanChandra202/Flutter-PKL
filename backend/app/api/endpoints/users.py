from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, ConfigDict
from datetime import datetime

from app.api import deps
from app.models.user import User
from app.models.role import Role

router = APIRouter()


# ─── Schemas ──────────────────────────────────────────────────────────────────

class AdminUserResponse(BaseModel):
    id: int
    email: str
    role: Optional[str] = None
    nama_lengkap: Optional[str] = None
    no_hp: Optional[str] = None
    is_active: bool
    is_face_verified: bool
    created_at: datetime
    current_room_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


class RoleUpdate(BaseModel):
    role_name: str


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _to_response(user: User) -> AdminUserResponse:
    return AdminUserResponse(
        id=user.id,
        email=user.email,
        role=user.role.name if user.role else None,
        nama_lengkap=user.profile.nama_lengkap if user.profile else None,
        no_hp=user.profile.no_hp if user.profile else None,
        is_active=user.is_active,
        is_face_verified=user.profile.is_face_verified if user.profile else False,
        created_at=user.created_at,
        current_room_id=user.current_room_id,
    )


def _require_superadmin(current_user: User):
    if not current_user.role or current_user.role.name != "SuperAdmin":
        raise HTTPException(status_code=403, detail="Hanya SuperAdmin yang bisa mengakses fitur ini")


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.get("/", response_model=List[AdminUserResponse])
def list_users(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    """SuperAdmin: list semua user."""
    _require_superadmin(current_user)
    users = db.query(User).order_by(User.created_at.desc()).all()
    return [_to_response(u) for u in users]


@router.put("/{user_id}/role", response_model=AdminUserResponse)
def update_user_role(
    user_id: int,
    body: RoleUpdate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    """SuperAdmin: ubah role user."""
    _require_superadmin(current_user)

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    role = db.query(Role).filter(Role.name == body.role_name).first()
    if not role:
        raise HTTPException(status_code=400, detail=f"Role '{body.role_name}' tidak ditemukan")

    user.role_id = role.id
    db.commit()
    db.refresh(user)
    return _to_response(user)


@router.put("/{user_id}/toggle-active", response_model=AdminUserResponse)
def toggle_user_active(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    """SuperAdmin: aktifkan / nonaktifkan akun user."""
    _require_superadmin(current_user)

    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Tidak bisa menonaktifkan akun sendiri")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    user.is_active = not user.is_active
    db.commit()
    db.refresh(user)
    return _to_response(user)
