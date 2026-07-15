from sqlalchemy import Column, Integer, String, Boolean, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from app.models.base import Base

class JastipListing(Base):
    __tablename__ = "jastip_listings"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    price = Column(String, nullable=False)
    wa_number = Column(String, nullable=False)
    
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    user = relationship("User")
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class SharedTool(Base):
    __tablename__ = "shared_tools"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    icon_name = Column(String, nullable=False, default="handyman")
    is_available = Column(Boolean, default=True)
    
    # Who is currently borrowing it
    borrowed_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    borrowed_by = relationship("User", foreign_keys=[borrowed_by_user_id])
    borrowed_at = Column(DateTime, nullable=True)
