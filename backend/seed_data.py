import asyncio
import os
from sqlalchemy.orm import Session
from app.db.session import SessionLocal, engine
from app.models.role import Role
from app.models.user import User, UserProfile
from app.core.security import get_password_hash
from app.models.base import Base

def seed_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Create roles
        roles = ["Admin", "User", "Owner"]
        for role_name in roles:
            existing_role = db.query(Role).filter(Role.name == role_name).first()
            if not existing_role:
                new_role = Role(name=role_name)
                db.add(new_role)
        db.commit()

        # Create admin user
        admin_role = db.query(Role).filter(Role.name == "Admin").first()
        admin_email = "admin@kostraktor.com"
        existing_admin = db.query(User).filter(User.email == admin_email).first()
        
        if not existing_admin:
            admin_user = User(
                email=admin_email,
                password_hash=get_password_hash("admin123"),
                role_id=admin_role.id
            )
            db.add(admin_user)
            db.commit()
            db.refresh(admin_user)
            
            # create profile
            profile = UserProfile(user_id=admin_user.id, nama_lengkap="Admin")
            db.add(profile)
            db.commit()
            print(f"Admin user created: {admin_email} / admin123")
        else:
            print("Admin user already exists")
            
    finally:
        db.close()

if __name__ == "__main__":
    print("Seeding database...")
    seed_db()
    print("Database seeded.")
