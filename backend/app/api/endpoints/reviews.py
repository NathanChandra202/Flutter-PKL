from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.models.review import Review
from app.models.user import User

router = APIRouter()


# ─── Pydantic schemas ──────────────────────────────────────────────────────────

class ReviewCreate(BaseModel):
    rating: float
    comment: str
    room_type: Optional[str] = None


class ManualReviewCreate(BaseModel):
    reviewer_name: str
    rating: float
    comment: str
    room_type: Optional[str] = None


class ReviewResponse(BaseModel):
    id: int
    user_name: str
    user_email: str
    rating: float
    comment: str
    room_type: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ─── Helper ────────────────────────────────────────────────────────────────────

def _to_response(r: Review) -> ReviewResponse:
    # Prefer manual reviewer name if set (admin-entered review)
    display_name = (
        r.manual_reviewer_name
        if r.manual_reviewer_name
        else (
            r.user.profile.nama_lengkap
            if r.user and r.user.profile and r.user.profile.nama_lengkap
            else (r.user.email if r.user else "Anonymous")
        )
    )
    return ReviewResponse(
        id=r.id,
        user_name=display_name,
        user_email=r.user.email if r.user else "",
        rating=r.rating,
        comment=r.comment,
        room_type=r.room_type,
        created_at=r.created_at,
    )


# ─── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/", response_model=List[ReviewResponse])
def get_reviews(db: Session = Depends(deps.get_db)):
    """Fetch all reviews, newest first. Public — no auth required."""
    reviews = db.query(Review).order_by(Review.created_at.desc()).all()
    return [_to_response(r) for r in reviews]


@router.post("/", response_model=ReviewResponse)
def create_review(
    review_in: ReviewCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    """Submit a new review. Each user can submit at most one review."""
    existing = db.query(Review).filter(Review.user_id == current_user.id).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail="Anda sudah memberikan review sebelumnya.",
        )

    if not (1 <= review_in.rating <= 5):
        raise HTTPException(status_code=400, detail="Rating harus antara 1-5 bintang.")

    if not review_in.comment.strip():
        raise HTTPException(status_code=400, detail="Komentar tidak boleh kosong.")

    review = Review(
        user_id=current_user.id,
        rating=review_in.rating,
        comment=review_in.comment.strip(),
        room_type=review_in.room_type,
    )
    db.add(review)
    db.commit()
    db.refresh(review)
    return _to_response(review)


@router.post("/manual", response_model=ReviewResponse)
def create_manual_review(
    review_in: ManualReviewCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    """Admin-only: create a review with a custom reviewer name."""
    if current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    if not (1 <= review_in.rating <= 5):
        raise HTTPException(status_code=400, detail="Rating harus antara 1-5 bintang.")

    if not review_in.comment.strip():
        raise HTTPException(status_code=400, detail="Komentar tidak boleh kosong.")

    if not review_in.reviewer_name.strip():
        raise HTTPException(status_code=400, detail="Nama pengulas tidak boleh kosong.")

    review = Review(
        user_id=current_user.id,
        rating=review_in.rating,
        comment=review_in.comment.strip(),
        room_type=review_in.room_type,
        manual_reviewer_name=review_in.reviewer_name.strip(),
    )
    db.add(review)
    db.commit()
    db.refresh(review)
    return _to_response(review)
