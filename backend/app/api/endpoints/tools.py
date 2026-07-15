from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.models.community import SharedTool
from app.models.user import User

router = APIRouter()

class ToolResponse(BaseModel):
    id: int
    name: str
    icon_name: str
    is_available: bool
    borrowed_by_name: Optional[str] = None
    borrowed_at: Optional[datetime] = None

    class Config:
        orm_mode = True
        from_attributes = True

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
        tool = SharedTool(**tool_data)
        db.add(tool)
    db.commit()
    return {"message": f"Seeded {len(INITIAL_TOOLS)} tools successfully"}

@router.get("/", response_model=List[ToolResponse])
def get_tools(db: Session = Depends(deps.get_db)):
    tools = db.query(SharedTool).all()
    return [_to_response(t) for t in tools]

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
        borrowed_by_name=borrower_name,
        borrowed_at=tool.borrowed_at
    )
