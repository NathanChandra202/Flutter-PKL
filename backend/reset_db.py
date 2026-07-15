from sqlalchemy import text
from app.db.session import engine
from app.models.kost import KostRoom
from app.models.booking import Booking

with engine.connect() as conn:
    print("Dropping KostRoom CASCADE...")
    conn.execute(text("DROP TABLE IF EXISTS bookings CASCADE;"))
    conn.execute(text("DROP TABLE IF EXISTS kost_rooms CASCADE;"))
    conn.commit()

print("Recreating tables...")
from app.models.base import Base
Base.metadata.create_all(bind=engine)
print("Tables recreated.")
