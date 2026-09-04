from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, ConfigDict

from app.api import deps
from app.models.community import SharedTool
from app.models.user import User

router = APIRouter()

class ToolCreate(BaseModel):
    name: str
    icon_name: str

class ToolStatusUpdate(BaseModel):
    status: str

class ToolResponse(BaseModel):
    id: int
    name: str
    icon_name: str
    is_available: bool
    status: str
    submitted_by_user_id: Optional[int] = None
    borrowed_by_name: Optional[str] = None
    borrowed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
INITIAL_TOOLS = [
    {"name": "Vacuum Cleaner", "icon_name": "cleaning_services"},
    {"name": "Tangga Lipat", "icon_name": "straighten"},
    {"name": "Bor Listrik", "icon_name": "handyman"},
    {"name": "Troli Galon", "icon_name": "shopping_cart"},
]

@router.post("/seed")
def seed_tools(db: Session = Depends(deps.get_db)):
    existing = db.query(SharedTool).first()
    if existing:
        return {"message": "Tools already seeded", "count": db.query(SharedTool).count()}
    
    for tool_data in INITIAL_TOOLS:
        tool = SharedTool(**tool_data, status="APPROVED")
        db.add(tool)
    db.commit()
    return {"message": f"Seeded {len(INITIAL_TOOLS)} tools successfully"}

@router.get("/", response_model=List[ToolResponse])
def get_tools(db: Session = Depends(deps.get_db)):
    tools = db.query(SharedTool).filter(SharedTool.status == "APPROVED").all()
    return [_to_response(t) for t in tools]

@router.post("/", response_model=ToolResponse)
def create_tool(
    tool_in: ToolCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    is_admin = current_user.role and current_user.role.name in ["Admin", "SuperAdmin"]
    tool = SharedTool(
        name=tool_in.name,
        icon_name=tool_in.icon_name,
        is_available=True,
        status="APPROVED" if is_admin else "PENDING",
        submitted_by_user_id=current_user.id,
    )
    db.add(tool)
    db.commit()
    db.refresh(tool)
    return _to_response(tool)

@router.get("/pending", response_model=List[ToolResponse])
def get_pending_tools(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    if current_user.role is None or current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    tools = db.query(SharedTool).filter(SharedTool.status == "PENDING").all()
    return [_to_response(t) for t in tools]

@router.post("/{tool_id}/review", response_model=ToolResponse)
def review_tool(
    tool_id: int,
    status_update: ToolStatusUpdate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
):
    if current_user.role is None or current_user.role.name not in ["Admin", "SuperAdmin"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    tool = db.query(SharedTool).filter(SharedTool.id == tool_id).first()
    if not tool:
        raise HTTPException(status_code=404, detail="Tool not found")
        
    tool.status = status_update.status
    db.commit()
    db.refresh(tool)
    return _to_response(tool)

@router.post("/{tool_id}/borrow", response_model=ToolResponse)
def borrow_tool(
    tool_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
):
    tool = db.query(SharedTool).filter(SharedTool.id == tool_id).first()
    if not tool:
        raise HTTPException(status_code=404, detail="Tool not found")
    if not tool.is_available:
        raise HTTPException(status_code=400, detail="Tool is currently being borrowed")
    
    tool.is_available = False
    tool.borrowed_by_user_id = current_user.id
    tool.borrowed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(tool)
    return _to_response(tool)

@router.post("/{tool_id}/return", response_model=ToolResponse)
def return_tool(
    tool_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
):
    tool = db.query(SharedTool).filter(SharedTool.id == tool_id).first()
    if not tool:
        raise HTTPException(status_code=404, detail="Tool not found")
    if tool.is_available:
        raise HTTPException(status_code=400, detail="Tool is already available")
    
    tool.is_available = True
    tool.borrowed_by_user_id = None
    tool.borrowed_at = None
    db.commit()
    db.refresh(tool)
    return _to_response(tool)

def _to_response(tool: SharedTool) -> ToolResponse:
    borrower_name = None
    if tool.borrowed_by:
        profile = tool.borrowed_by.profile
        borrower_name = profile.nama_lengkap if profile else tool.borrowed_by.email
    
    return ToolResponse(
        id=tool.id,
        name=tool.name,
        icon_name=tool.icon_name,
        is_available=tool.is_available,
        status=tool.status,
        submitted_by_user_id=tool.submitted_by_user_id,
        borrowed_by_name=borrower_name,
        borrowed_at=tool.borrowed_at
    )
