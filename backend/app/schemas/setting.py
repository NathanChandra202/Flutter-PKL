from pydantic import BaseModel
from typing import Optional

class SettingBase(BaseModel):
    value: Optional[str] = None

class SettingCreate(SettingBase):
    pass

class SettingUpdate(SettingBase):
    pass

class SettingOut(SettingBase):
    id: int
    key: str

    class Config:
        from_attributes = True
