from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.setting import Setting
from app.schemas.setting import SettingOut, SettingUpdate

router = APIRouter()

@router.get("/{key}", response_model=SettingOut)
def get_setting(key: str, db: Session = Depends(get_db)):
    """
    Get a setting by its key.
    """
    setting = db.query(Setting).filter(Setting.key == key).first()
    if not setting:
        # If the setting does not exist, return a default empty string rather than 404
        # to avoid breaking frontend/mobile clients that expect a value.
        return SettingOut(id=0, key=key, value="")
    return setting

@router.put("/{key}", response_model=SettingOut)
def update_setting(key: str, setting_in: SettingUpdate, db: Session = Depends(get_db)):
    """
    Update or create a setting by its key.
    """
    setting = db.query(Setting).filter(Setting.key == key).first()
    if setting:
        setting.value = setting_in.value
    else:
        setting = Setting(key=key, value=setting_in.value)
        db.add(setting)
    
    db.commit()
    db.refresh(setting)
    return setting
