from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.endpoints import auth, verify, rooms, bookings
from app.models.base import Base
from app.db.session import engine

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.PROJECT_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, set this to the actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(verify.router, prefix=f"{settings.API_V1_STR}/verify", tags=["verify"])
app.include_router(rooms.router, prefix=f"{settings.API_V1_STR}/rooms", tags=["rooms"])
app.include_router(bookings.router, prefix=f"{settings.API_V1_STR}/bookings", tags=["bookings"])

@app.get("/")
def read_root():
    return {"message": "Welcome to Kostraktor Backend API"}
