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
        # Create roles (including SuperAdmin)
        roles = ["Admin", "User", "Owner", "SuperAdmin"]
        for role_name in roles:
            existing_role = db.query(Role).filter(Role.name == role_name).first()
            if not existing_role:
                new_role = Role(name=role_name)
                db.add(new_role)
        db.commit()

        # Create or update admin user
        admin_role = db.query(Role).filter(Role.name == "Admin").first()
        admin_email = "admin@kostraktor.com"
        existing_admin = db.query(User).filter(User.email == admin_email).first()
        
        if existing_admin:
            # Update existing admin instead of deleting
            existing_admin.password_hash = get_password_hash("admin123")
            existing_admin.role_id = admin_role.id
            db.commit()
            print(f"Updated existing admin user: {admin_email}")
        else:
            admin_user = User(
                email=admin_email,
                password_hash=get_password_hash("admin123"),
                role_id=admin_role.id
            )
            db.add(admin_user)
            db.commit()
            db.refresh(admin_user)
            
            # create profile
            profile = UserProfile(user_id=admin_user.id, nama_lengkap="Admin Kostraktor")
            db.add(profile)
            db.commit()
            print(f"Admin user created: {admin_email} / admin123")
        
        # Create or update SuperAdmin user
        superadmin_role = db.query(Role).filter(Role.name == "SuperAdmin").first()
        superadmin_email = "superadmin@kostraktor.com"
        existing_superadmin = db.query(User).filter(User.email == superadmin_email).first()
        
        if existing_superadmin:
            # Update existing superadmin instead of deleting
            existing_superadmin.password_hash = get_password_hash("superadmin123")
            existing_superadmin.role_id = superadmin_role.id
            db.commit()
            print(f"Updated existing SuperAdmin user: {superadmin_email}")
        else:
            superadmin_user = User(
                email=superadmin_email,
                password_hash=get_password_hash("superadmin123"),
                role_id=superadmin_role.id
            )
            db.add(superadmin_user)
            db.commit()
            db.refresh(superadmin_user)
            
            superadmin_profile = UserProfile(user_id=superadmin_user.id, nama_lengkap="Super Admin")
            db.add(superadmin_profile)
            db.commit()
            print(f"SuperAdmin user created: {superadmin_email} / superadmin123")
        
        # Create or update test user
        user_role = db.query(Role).filter(Role.name == "User").first()
        if not user_role:
            user_role = Role(name="User")
            db.add(user_role)
            db.commit()
            db.refresh(user_role)
        
        test_email = "user@test.com"
        existing_test = db.query(User).filter(User.email == test_email).first()
        
        if existing_test:
            # Update existing test user instead of deleting
            existing_test.password_hash = get_password_hash("test123")
            existing_test.role_id = user_role.id
            db.commit()
            print(f"Updated existing test user: {test_email}")
        else:
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
