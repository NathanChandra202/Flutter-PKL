from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.models.kost import KostRoom

router = APIRouter()

class RoomBase(BaseModel):
    name: str
    description: str
    price_per_month: float
    is_available: bool = True
    image_url: Optional[str] = None
    facilities: Optional[str] = None
    room_type: Optional[str] = None

class RoomCreate(RoomBase):
    pass

class RoomUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price_per_month: Optional[float] = None
    is_available: Optional[bool] = None
    image_url: Optional[str] = None
    facilities: Optional[str] = None
    room_type: Optional[str] = None

class RoomResponse(RoomBase):
    id: int

    class Config:
        orm_mode = True
        from_attributes = True

@router.get("/", response_model=List[RoomResponse])
def get_rooms(all: bool = False, db: Session = Depends(deps.get_db)):
    if all:
        rooms = db.query(KostRoom).order_by(KostRoom.id).all()
    else:
        rooms = db.query(KostRoom).filter(KostRoom.is_available == True).order_by(KostRoom.id).all()
    return rooms

@router.post("/", response_model=RoomResponse)
def create_room(room_in: RoomCreate, db: Session = Depends(deps.get_db)):
    new_room = KostRoom(
        name=room_in.name,
        description=room_in.description,
        price_per_month=room_in.price_per_month,
        is_available=room_in.is_available,
        image_url=room_in.image_url,
        facilities=room_in.facilities,
        room_type=room_in.room_type
    )
    db.add(new_room)
    db.commit()
    db.refresh(new_room)
    return new_room

@router.put("/{room_id}", response_model=RoomResponse)
def update_room(room_id: int, room_in: RoomUpdate, db: Session = Depends(deps.get_db)):
    room = db.query(KostRoom).filter(KostRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    update_data = room_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(room, field, value)
        
    db.commit()
    db.refresh(room)
    return room

@router.delete("/{room_id}")
def delete_room(room_id: int, db: Session = Depends(deps.get_db)):
    room = db.query(KostRoom).filter(KostRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    # Soft delete
    room.is_available = False
    db.commit()
    return {"message": "Room successfully deleted (disabled)"}

@router.post("/seed")
def seed_rooms(db: Session = Depends(deps.get_db)):
    existing = db.query(KostRoom).first()
    if existing:
        return {"message": "Rooms already seeded", "count": db.query(KostRoom).count()}

    rooms = [
        KostRoom(
            name="Tipe Standard",
            description="Fasilitas: Kasur, Lemari, Kipas Angin, Kamar Mandi Luar. Wifi up to 20Mbps. Cocok untuk mahasiswa.",
            price_per_month=850000,
            is_available=True,
            image_url="https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png",
            facilities="Kasur, Lemari, Kipas Angin, Kamar Mandi Luar, Wifi 20Mbps",
            room_type="Putra"
        ),
        KostRoom(
            name="Tipe AC Reguler",
            description="Fasilitas: AC, Kasur Springbed, Meja Belajar, Kamar Mandi Dalam. Wifi up to 50Mbps.",
            price_per_month=1200000,
            is_available=True,
            image_url="https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png",
            facilities="AC, Kasur Springbed, Meja Belajar, Kamar Mandi Dalam, Wifi 50Mbps",
            room_type="Campur"
        ),
        KostRoom(
            name="Tipe AC Premium",
            description="Fasilitas: AC, Smart TV, Springbed Premium, Kulkas Mini, Kamar Mandi Dalam (Water Heater).",
            price_per_month=1800000,
            is_available=True,
            image_url="https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png",
            facilities="AC, Smart TV, Springbed Premium, Kulkas Mini, Kamar Mandi Dalam",
            room_type="Putri"
        )
    ]

    for room in rooms:
        db.add(room)
    db.commit()

    return {"message": f"Seeded {len(rooms)} rooms successfully"}
