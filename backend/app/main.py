# pyrefly: ignore [missing-import]
import os
import threading
# pyrefly: ignore [missing-import]
from fastapi import FastAPI
# pyrefly: ignore [missing-import]
from fastapi.middleware.cors import CORSMiddleware
# pyrefly: ignore [missing-import]
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.api.endpoints import auth, verify, rooms, bookings, jastip, tools, reviews, reports
from app.api.endpoints import settings as settings_router
from app.models.base import Base
from app.models.report import Report  # Import to register the model
from app.models.setting import Setting
from app.db.session import engine

# Create tables
Base.metadata.create_all(bind=engine)

def _preload_models():
    """
    Pre-load DeepFace AI models (VGG-Face + RetinaFace) in a background thread
    saat server pertama nyala. Tujuannya agar request verifikasi pertama
    dari user tidak kena 'cold start' (loading model yang bisa makan 60-120 detik).
    """
    try:
        import numpy as np
        from deepface import DeepFace
        print("[STARTUP] Pre-loading DeepFace models... (ini bisa 60-120 detik pertama kali)")
        
        # Buat dummy 1x1 pixel image agar DeepFace download & cache model-nya
        dummy = np.zeros((224, 224, 3), dtype=np.uint8)
        import tempfile, cv2
        tmp = tempfile.NamedTemporaryFile(suffix=".jpg", delete=False)
        cv2.imwrite(tmp.name, dummy)
        tmp.close()
        
        try:
            # Panggil verify dgn enforce_detection=False agar tidak error meski gambar kosong
            DeepFace.verify(
                img1_path=tmp.name,
                img2_path=tmp.name,
                model_name="VGG-Face",
                distance_metric="cosine",
                enforce_detection=False,
                detector_backend="skip",
            )
        except Exception:
            pass  # Hasil tidak penting, yang penting model sudah ter-load ke cache
        finally:
            os.remove(tmp.name)
        
        print("[STARTUP] ✅ DeepFace models pre-loaded. Server siap untuk verifikasi wajah.")
    except Exception as e:
        print(f"[STARTUP] ⚠️ Model pre-load gagal (tidak masalah, akan load saat request pertama): {e}")

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
app.include_router(jastip.router, prefix=f"{settings.API_V1_STR}/jastip", tags=["jastip"])
app.include_router(tools.router, prefix=f"{settings.API_V1_STR}/tools", tags=["tools"])
app.include_router(reviews.router, prefix=f"{settings.API_V1_STR}/reviews", tags=["reviews"])
app.include_router(reports.router, prefix=f"{settings.API_V1_STR}/reports", tags=["reports"])
app.include_router(settings_router.router, prefix=f"{settings.API_V1_STR}/settings", tags=["settings"])

os.makedirs("uploads/rooms", exist_ok=True)
os.makedirs("uploads/ktp", exist_ok=True)
os.makedirs("uploads/selfies", exist_ok=True)
os.makedirs("uploads/bookings", exist_ok=True)
os.makedirs("uploads/reports", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


@app.on_event("startup")
def on_startup():
    # Jalankan pre-load di background thread agar server tidak nge-block saat nyala
    thread = threading.Thread(target=_preload_models, daemon=True)
    thread.start()

@app.get("/")
def read_root():
    return {"message": "Welcome to Kostraktor Backend API"}
