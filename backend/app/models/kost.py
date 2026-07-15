from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Float
from sqlalchemy.orm import relationship

from app.models.base import Base

class KostRoom(Base):
    __tablename__ = "kost_rooms"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    price_per_month = Column(Float)
    is_available = Column(Boolean, default=True)
    image_url = Column(String, nullable=True)
    facilities = Column(String, nullable=True)
    room_type = Column(String, default="Campur")
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    
    # Relationships
    owner = relationship("User")
    bookings = relationship("Booking", back_populates="room")
