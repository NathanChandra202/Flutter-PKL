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

    # Durasi sewa & tanggal selesai
    duration_months = Column(Integer, default=1, nullable=False)
    end_date = Column(DateTime, nullable=True)  # NULL untuk booking lama

    # Perpanjangan sewa
    is_renewal_requested = Column(Boolean, default=False)
    pending_renewal_months = Column(Integer, nullable=True)

    # Document URLs
    ktp_image_url = Column(String, nullable=True)
    selfie_image_url = Column(String, nullable=True)
    bukti_bayar_url = Column(String, nullable=True)
    referensi_transaksi = Column(String, nullable=True)
    
    # Relationships
    user = relationship("User")
    room = relationship("KostRoom", back_populates="bookings")
