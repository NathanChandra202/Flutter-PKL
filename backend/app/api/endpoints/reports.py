from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from pydantic import BaseModel, ConfigDict, ConfigDict
import os, uuid

from app.api import deps
from app.models.report import Report
from app.models.user import User

router = APIRouter()

class ReportCreate(BaseModel):
    title: str
    description: str
    category: Optional[str] = None

class ReportResponse(BaseModel):
    id: int
    user_id: int
    user_name: Optional[str] = None
    title: str
    description: str
    category: Optional[str] = None
    photo_url: Optional[str] = None
    status: str
    admin_response: Optional[str] = None
    created_at: datetime
    resolved_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
def _to_response(r: Report) -> ReportResponse:
    # Use fallback if user.profile is not available
    user_name = r.user.email
    if r.user and r.user.profile and r.user.profile.nama_lengkap:
        user_name = r.user.profile.nama_lengkap
        
    return ReportResponse(
        id=r.id, 
        user_id=r.user_id,
        user_name=user_name,
        title=r.title, 
        description=r.description, 
        category=r.category,
        photo_url=r.photo_url, 
        status=r.status, 
        admin_response=r.admin_response,
        created_at=r.created_at, 
        resolved_at=r.resolved_at,
    )

@router.post("/", response_model=ReportResponse)
def create_report(report_in: ReportCreate, db: Session = Depends(deps.get_db),
                   current_user: User = Depends(deps.get_current_active_user)):
    report = Report(user_id=current_user.id, title=report_in.title,
                     description=report_in.description, category=report_in.category)
    room_name = current_user.current_room.name if current_user.current_room else "Tidak diketahui"
    
    db.add(report)
    db.commit()
    db.refresh(report)

    # Trigger WA Notification (Simulasi/Bot)
    from app.services.wa_service import send_wa_notification
    wa_msg = (
        f"*[Laporan Baru]*\n"
        f"Kamar: {room_name}\n"
        f"Kategori: {report.category or 'Umum'}\n"
        f"Fasilitas/Masalah: {report.title}\n"
        f"Deskripsi: {report.description}\n"
        f"Status: Menunggu penanganan"
    )
    # The message is sent to the target, keeping the reporter's identity anonymous
    send_wa_notification(wa_msg, target="120363411504991593@g.us")

    return _to_response(report)

@router.post("/{report_id}/upload-photo")
async def upload_report_photo(report_id: int, photo: UploadFile = File(...),
                                db: Session = Depends(deps.get_db)):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    upload_dir = "uploads/reports"
    os.makedirs(upload_dir, exist_ok=True)
    ext = photo.filename.split(".")[-1] if photo.filename and "." in photo.filename else "jpg"
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = os.path.join(upload_dir, filename)
    with open(filepath, "wb") as f:
        f.write(await photo.read())
    report.photo_url = f"/uploads/reports/{filename}"
    db.commit()
    db.refresh(report)
    return {"photo_url": report.photo_url}

@router.get("/me", response_model=List[ReportResponse])
def get_my_reports(db: Session = Depends(deps.get_db),
                    current_user: User = Depends(deps.get_current_active_user)):
    reports = db.query(Report).filter(Report.user_id == current_user.id).order_by(Report.created_at.desc()).all()
    return [_to_response(r) for r in reports]

@router.get("/", response_model=List[ReportResponse])
def get_all_reports(status: Optional[str] = None, db: Session = Depends(deps.get_db),
                     current_user: User = Depends(deps.get_current_active_user)):
    if not current_user.role or current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    query = db.query(Report)
    if status:
        query = query.filter(Report.status == status)
    reports = query.order_by(Report.created_at.desc()).all()
    return [_to_response(r) for r in reports]

class ReportUpdate(BaseModel):
    status: str
    admin_response: Optional[str] = None

@router.post("/{report_id}/respond", response_model=ReportResponse)
def respond_report(report_id: int, update: ReportUpdate, db: Session = Depends(deps.get_db),
                    current_user: User = Depends(deps.get_current_active_user)):
    if not current_user.role or current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    report.status = update.status
    if update.admin_response:
        report.admin_response = update.admin_response
    if update.status == "RESOLVED":
        report.resolved_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(report)

    # Trigger WA Notification for Update (Simulasi/Bot)
    from app.services.wa_service import send_wa_notification
    status_ind = "✅ Selesai Diperbaiki" if update.status == "RESOLVED" else "Diproses"
    wa_msg = (
        f"*[Update Laporan]*\n"
        f"Fasilitas: {report.title}\n"
        f"Status Terbaru: {status_ind}\n"
        f"Tanggapan Admin: {report.admin_response or '-'}\n"
    )
    send_wa_notification(wa_msg, target="120363411504991593@g.us")

    return _to_response(report)
