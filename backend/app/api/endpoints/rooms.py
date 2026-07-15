from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.models.kost import KostRoom

router = APIRouter()

class RoomResponse(BaseModel):
    id: int
    name: str
    description: str
    price_per_month: float
    is_available: bool

    class Config:
        orm_mode = True
        from_attributes = True

@router.get("/", response_model=List[RoomResponse])
def get_rooms(db: Session = Depends(deps.get_db)):
    rooms = db.query(KostRoom).filter(KostRoom.is_available == True).all()
    return rooms

@router.post("/seed")
def seed_rooms(db: Session = Depends(deps.get_db)):
    # Check if rooms already exist
    existing = db.query(KostRoom).first()
    if existing:
        return {"message": "Rooms already seeded", "count": db.query(KostRoom).count()}
    
    rooms = [
        KostRoom(
            name="Tipe Standard",
            description="Fasilitas: Kasur, Lemari, Kipas Angin, Kamar Mandi Luar. Wifi up to 20Mbps. Cocok untuk mahasiswa.",
            price_per_month=850000,
            is_available=True
        ),
        KostRoom(
            name="Tipe AC Reguler",
            description="Fasilitas: AC, Kasur Springbed, Meja Belajar, Kamar Mandi Dalam. Wifi up to 50Mbps.",
            price_per_month=1200000,
            is_available=True
        ),
        KostRoom(
            name="Tipe AC Premium",
            description="Fasilitas: AC, Smart TV, Springbed Premium, Kulkas Mini, Kamar Mandi Dalam (Water Heater).",
            price_per_month=1800000,
            is_available=True
        )
    ]
    
    for room in rooms:
        db.add(room)
    db.commit()
    
    return {"message": f"Seeded {len(rooms)} rooms successfully"}
