from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.models.booking import Booking
from app.models.kost import KostRoom
from app.models.user import User

router = APIRouter()

class BookingCreate(BaseModel):
    room_name: str
    start_date: datetime

class BookingResponse(BaseModel):
    id: int
    user_id: int
    room_id: int
    booking_date: datetime
    start_date: datetime
    status: str
    
    room_name: Optional[str] = None
    user_email: Optional[str] = None
    user_name: Optional[str] = None

    class Config:
        orm_mode = True

@router.post("/", response_model=BookingResponse)
def create_booking(booking_in: BookingCreate, db: Session = Depends(deps.get_db), current_user: User = Depends(deps.get_current_active_user)):
    # Find room by name (since flutter might send name for simplicity, or we adapt flutter to send id)
    room = db.query(KostRoom).filter(KostRoom.name == booking_in.room_name).first()
    if not room:
        # Fallback for mock data testing
        room = db.query(KostRoom).first()
        if not room:
            raise HTTPException(status_code=404, detail="Room not found")

    booking = Booking(
        user_id=current_user.id,
        room_id=room.id,
        start_date=booking_in.start_date,
        status="PENDING"
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    
    return _to_booking_response(booking)

@router.get("/me", response_model=List[BookingResponse])
def get_my_bookings(db: Session = Depends(deps.get_db), current_user: User = Depends(deps.get_current_active_user)):
    bookings = db.query(Booking).filter(Booking.user_id == current_user.id).all()
    return [_to_booking_response(b) for b in bookings]

@router.get("/pending", response_model=List[BookingResponse])
def get_pending_bookings(db: Session = Depends(deps.get_db), current_user: User = Depends(deps.get_current_active_user)):
    # Simple admin check
    if current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    bookings = db.query(Booking).filter(Booking.status == "PENDING").all()
    return [_to_booking_response(b) for b in bookings]

class StatusUpdate(BaseModel):
    status: str

@router.post("/{booking_id}/status", response_model=BookingResponse)
def update_booking_status(booking_id: int, status_update: StatusUpdate, db: Session = Depends(deps.get_db), current_user: User = Depends(deps.get_current_active_user)):
    if current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    booking.status = status_update.status
    db.commit()
    db.refresh(booking)
    return _to_booking_response(booking)

def _to_booking_response(booking: Booking) -> BookingResponse:
    return BookingResponse(
        id=booking.id,
        user_id=booking.user_id,
        room_id=booking.room_id,
        booking_date=booking.booking_date,
        start_date=booking.start_date,
        status=booking.status,
        room_name=booking.room.name if booking.room else "Unknown Room",
        user_email=booking.user.email if booking.user else "",
        user_name=booking.user.profile.nama_lengkap if booking.user and booking.user.profile else ""
    )
