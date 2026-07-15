from datetime import datetime, timedelta, timezone
import warnings
from jose import jwt
from passlib.context import CryptContext
from typing import Any, Union

from app.core.config import settings

# Suppress passlib bcrypt version warning (bcrypt >= 4.x vs passlib 1.7.x)
warnings.filterwarnings("ignore", ".*error reading bcrypt version.*")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def _truncate(password: str) -> str:
    """bcrypt silently truncates passwords >72 bytes; we enforce this explicitly."""
    encoded = password.encode("utf-8")
    return encoded[:72].decode("utf-8", errors="ignore")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(_truncate(plain_password), hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(_truncate(password))

def create_access_token(subject: Union[str, Any], expires_delta: timedelta = None) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {"exp": expire, "sub": str(subject)}
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt
