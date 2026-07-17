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
        
        if existing_admin:
            # Delete existing admin to recreate with fresh password
            db.delete(existing_admin)
            db.commit()
            print("Deleted existing admin user")
        
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
        
        # Create test user
        user_role = db.query(Role).filter(Role.name == "User").first()
        if not user_role:
            user_role = Role(name="User")
            db.add(user_role)
            db.commit()
            db.refresh(user_role)
        
        test_email = "user@test.com"
        existing_test = db.query(User).filter(User.email == test_email).first()
        
        if existing_test:
            db.delete(existing_test)
            db.commit()
            print("Deleted existing test user")
        
        test_user = User(
            email=test_email,
            password_hash=get_password_hash("test123"),
            role_id=user_role.id
        )
        db.add(test_user)
        db.commit()
        db.refresh(test_user)
        
        test_profile = UserProfile(user_id=test_user.id, nama_lengkap="Test User")
        db.add(test_profile)
        db.commit()
        print(f"Test user created: {test_email} / test123")
            
    finally:
        db.close()

if __name__ == "__main__":
    print("Seeding database...")
    seed_db()
    print("Database seeded.")
