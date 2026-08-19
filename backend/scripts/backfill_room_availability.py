"""
Backfill script — fix kamar yang masih 'Tersedia' padahal sudah APPROVED.

Jalankan SEKALI setelah deploy:
    cd backend
    python -m scripts.backfill_room_availability

Aman untuk dijalankan berulang (idempotent).
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.session import SessionLocal
from app.models.booking import Booking
from app.models.kost import KostRoom
from app.models.user import User


def run():
    db = SessionLocal()
    try:
        approved = db.query(Booking).filter(Booking.status == "APPROVED").all()
        print(f"Found {len(approved)} APPROVED bookings to check...")

        rooms_fixed = 0
        users_fixed = 0

        for booking in approved:
            # Fix room.is_available
            room = db.query(KostRoom).filter(KostRoom.id == booking.room_id).first()
            if room and room.is_available:
                room.is_available = False
                rooms_fixed += 1
                print(f"  [ROOM FIX]  Room #{room.id} '{room.name}' → is_available=False")

            # Fix user.current_room_id
            user = db.query(User).filter(User.id == booking.user_id).first()
            if user and user.current_room_id is None:
                user.current_room_id = booking.room_id
                users_fixed += 1
                print(f"  [USER FIX]  User #{user.id} '{user.email}' → current_room_id={booking.room_id}")

        db.commit()
        print(f"\nDone! Fixed {rooms_fixed} rooms, {users_fixed} users.")

    except Exception as e:
        db.rollback()
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    run()
