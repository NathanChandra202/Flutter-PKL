from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.models.community import JastipListing
from app.models.user import User

router = APIRouter()

class JastipCreate(BaseModel):
    title: str
    description: str
    price: str
    wa_number: str

class JastipResponse(BaseModel):
    id: int
    title: str
    description: str
    price: str
    wa_number: str
    user_id: int
    author_name: Optional[str] = None
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True
        from_attributes = True

@router.get("/", response_model=List[JastipResponse])
def get_jastip_listings(db: Session = Depends(deps.get_db)):
    listings = db.query(JastipListing).filter(JastipListing.is_active == True).order_by(JastipListing.created_at.desc()).all()
    return [_to_response(l) for l in listings]

@router.post("/", response_model=JastipResponse)
def create_jastip_listing(
    listing_in: JastipCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
):
    listing = JastipListing(
        title=listing_in.title,
        description=listing_in.description,
        price=listing_in.price,
        wa_number=listing_in.wa_number,
        user_id=current_user.id
    )
    db.add(listing)
    db.commit()
    db.refresh(listing)
    return _to_response(listing)

@router.delete("/{listing_id}")
def delete_jastip_listing(
    listing_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
):
    listing = db.query(JastipListing).filter(JastipListing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your listing")
    listing.is_active = False
    db.commit()
    return {"message": "Listing deleted"}

def _to_response(listing: JastipListing) -> JastipResponse:
    return JastipResponse(
        id=listing.id,
        title=listing.title,
        description=listing.description,
        price=listing.price,
        wa_number=listing.wa_number,
        user_id=listing.user_id,
        author_name=listing.user.profile.nama_lengkap if listing.user and listing.user.profile else listing.user.email if listing.user else "Unknown",
        is_active=listing.is_active,
        created_at=listing.created_at
    )
