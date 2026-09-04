import os
import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session
from pydantic import BaseModel, ConfigDict, ConfigDict
from dateutil.relativedelta import relativedelta

from app.api import deps
from app.models.booking import Booking
from app.models.kost import KostRoom
from app.models.user import User

router = APIRouter()


# ─── Pydantic schemas ──────────────────────────────────────────────────────────

class BookingCreate(BaseModel):
    room_name: str
    start_date: datetime
    duration_months: int = 1


class StatusUpdate(BaseModel):
    status: str


class RenewalRequest(BaseModel):
    additional_months: int


class BookingResponse(BaseModel):
    id: int
    user_id: int
    room_id: int
    booking_date: datetime
    start_date: datetime
    status: str

    duration_months: Optional[int] = 1
    end_date: Optional[datetime] = None
    is_renewal_requested: Optional[bool] = False
    pending_renewal_months: Optional[int] = None

    room_name: Optional[str] = None
    user_email: Optional[str] = None
    user_name: Optional[str] = None

    ktp_image_url: Optional[str] = None
    selfie_image_url: Optional[str] = None
    bukti_bayar_url: Optional[str] = None
    referensi_transaksi: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
# ─── Helpers ───────────────────────────────────────────────────────────────────

def _to_booking_response(booking: Booking) -> BookingResponse:
    return BookingResponse(
        id=booking.id,
        user_id=booking.user_id,
        room_id=booking.room_id,
        booking_date=booking.booking_date,
        start_date=booking.start_date,
        status=booking.status,
        duration_months=booking.duration_months,
        end_date=booking.end_date,
        is_renewal_requested=booking.is_renewal_requested,
        pending_renewal_months=booking.pending_renewal_months,
        room_name=booking.room.name if booking.room else "Unknown Room",
        user_email=booking.user.email if booking.user else "",
        user_name=(
            booking.user.profile.nama_lengkap
            if booking.user and booking.user.profile
            else ""
        ),
        ktp_image_url=booking.ktp_image_url,
        selfie_image_url=booking.selfie_image_url,
        bukti_bayar_url=booking.bukti_bayar_url,
        referensi_transaksi=booking.referensi_transaksi,
    )


# ─── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/", response_model=BookingResponse)
def create_booking(
    booking_in: BookingCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    room = db.query(KostRoom).filter(KostRoom.name == booking_in.room_name).first()
    if not room:
        room = db.query(KostRoom).first()
        if not room:
            raise HTTPException(status_code=404, detail="Room not found")

    # Clamp duration to a sane range
    months = max(1, min(booking_in.duration_months, 120))
    end_date = booking_in.start_date + relativedelta(months=months)

    booking = Booking(
        user_id=current_user.id,
        room_id=room.id,
        start_date=booking_in.start_date,
        status="PENDING",
        duration_months=months,
        end_date=end_date,
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return _to_booking_response(booking)


@router.post("/{booking_id}/upload-documents")
async def upload_booking_documents(
    booking_id: int,
    ktp_image: UploadFile = File(None),
    selfie_image: UploadFile = File(None),
    bukti_bayar: UploadFile = File(None),
    db: Session = Depends(deps.get_db),
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    upload_dir = "uploads/bookings"
    os.makedirs(upload_dir, exist_ok=True)

    async def save_file(file: UploadFile, prefix: str) -> str:
        ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        filename = f"{prefix}_{uuid.uuid4()}.{ext}"
        filepath = os.path.join(upload_dir, filename)
        with open(filepath, "wb") as f:
            f.write(await file.read())
        return f"/uploads/bookings/{filename}"

    if ktp_image:
        booking.ktp_image_url = await save_file(ktp_image, "ktp")
    if selfie_image:
        booking.selfie_image_url = await save_file(selfie_image, "selfie")
    if bukti_bayar:
        booking.bukti_bayar_url = await save_file(bukti_bayar, "bukti")

    db.commit()
    db.refresh(booking)
    return {
        "ktp_image_url": booking.ktp_image_url,
        "selfie_image_url": booking.selfie_image_url,
        "bukti_bayar_url": booking.bukti_bayar_url,
    }


@router.get("/me", response_model=List[BookingResponse])
def get_my_bookings(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    bookings = db.query(Booking).filter(Booking.user_id == current_user.id).all()
    return [_to_booking_response(b) for b in bookings]


@router.get("/pending", response_model=List[BookingResponse])
def get_pending_bookings(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    if current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    bookings = db.query(Booking).filter(Booking.status == "PENDING").all()
    return [_to_booking_response(b) for b in bookings]


@router.get("/all", response_model=List[BookingResponse])
def get_all_bookings(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    if current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    bookings = db.query(Booking).order_by(Booking.booking_date.desc()).all()
    return [_to_booking_response(b) for b in bookings]


@router.post("/{booking_id}/status", response_model=BookingResponse)
def update_booking_status(
    booking_id: int,
    status_update: StatusUpdate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    if current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    old_status = booking.status
    booking.status = status_update.status

    room = booking.room
    booking_user = booking.user

    if status_update.status == "APPROVED":
        if room:
            room.is_available = False
        if booking_user:
            booking_user.current_room_id = booking.room_id

    elif status_update.status == "REJECTED":
        if old_status == "APPROVED":
            if room:
                room.is_available = True
            if booking_user:
                booking_user.current_room_id = None

    db.commit()
    db.refresh(booking)
    return _to_booking_response(booking)


@router.post("/{booking_id}/request-renewal")
def request_renewal(
    booking_id: int,
    renewal_in: RenewalRequest,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    """User mengajukan perpanjangan sewa."""
    booking = db.query(Booking).filter(
        Booking.id == booking_id,
        Booking.user_id == current_user.id,
    ).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.status != "APPROVED":
        raise HTTPException(
            status_code=400, detail="Hanya booking aktif yang bisa diperpanjang"
        )
    if renewal_in.additional_months < 1:
        raise HTTPException(status_code=400, detail="Durasi perpanjangan minimal 1 bulan")

    booking.is_renewal_requested = True
    booking.pending_renewal_months = renewal_in.additional_months
    db.commit()
    return {"message": "Permintaan perpanjangan terkirim, menunggu persetujuan admin"}


@router.post("/{booking_id}/approve-renewal")
def approve_renewal(
    booking_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    """Admin menyetujui perpanjangan sewa."""
    if current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking or not booking.is_renewal_requested:
        raise HTTPException(
            status_code=404, detail="Tidak ada permintaan perpanjangan untuk booking ini"
        )

    months = booking.pending_renewal_months or 1

    # Hitung dari end_date saat ini (atau dari sekarang kalau NULL)
    base_date = booking.end_date or datetime.now()
    booking.end_date = base_date + relativedelta(months=months)
    booking.duration_months = (booking.duration_months or 0) + months
    booking.is_renewal_requested = False
    booking.pending_renewal_months = None

    db.commit()
    return {
        "message": "Perpanjangan disetujui",
        "new_end_date": booking.end_date.isoformat(),
        "duration_months": booking.duration_months,
    }


@router.post("/checkout")
def checkout(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    """User melakukan check out — melepas kamar dan mereset status booking."""
    # Cari booking aktif milik user ini
    booking = (
        db.query(Booking)
        .filter(Booking.user_id == current_user.id, Booking.status == "APPROVED")
        .order_by(Booking.id.desc())
        .first()
    )
    if not booking:
        raise HTTPException(status_code=404, detail="Tidak ada booking aktif yang ditemukan")

    room = booking.room

    # Ubah status booking → CHECKED_OUT
    booking.status = "CHECKED_OUT"

    # Bebaskan kamar kembali
    if room:
        room.is_available = True

    # Lepas relasi user dengan kamar
    current_user.current_room_id = None

    db.commit()
    return {"message": "Check out berhasil. Kamar telah dibebaskan.", "booking_id": booking.id}

