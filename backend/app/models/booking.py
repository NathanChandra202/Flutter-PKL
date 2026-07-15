from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from app.models.base import Base

class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    room_id = Column(Integer, ForeignKey("kost_rooms.id"))
    
    booking_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    start_date = Column(DateTime)
    
    status = Column(String, default="PENDING") # PENDING, APPROVED, REJECTED
    
    # Relationships
    user = relationship("User")
    room = relationship("KostRoom", back_populates="bookings")
