"""
Script untuk membuat akun SuperAdmin
Jalankan: python setup_superadmin.py
"""
from sqlalchemy.orm import Session
from app.db.session import SessionLocal, engine
from app.models.role import Role
from app.models.user import User, UserProfile
from app.core.security import get_password_hash
from app.models.base import Base

def setup_superadmin():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Create SuperAdmin role if not exists
        superadmin_role = db.query(Role).filter(Role.name == "SuperAdmin").first()
        if not superadmin_role:
            superadmin_role = Role(name="SuperAdmin")
            db.add(superadmin_role)
            db.commit()
            db.refresh(superadmin_role)
            print("✅ SuperAdmin role created")
        else:
            print("ℹ️  SuperAdmin role already exists")
        
        # Create SuperAdmin user
        superadmin_email = "superadmin@kostraktor.com"
        existing = db.query(User).filter(User.email == superadmin_email).first()
        
        if existing:
            # Update existing user to SuperAdmin role
            existing.role_id = superadmin_role.id
            existing.password_hash = get_password_hash("superadmin123")
            db.commit()
            print(f"✅ Updated existing user to SuperAdmin: {superadmin_email}")
        else:
            # Create new SuperAdmin user
            superadmin_user = User(
                email=superadmin_email,
                password_hash=get_password_hash("superadmin123"),
                role_id=superadmin_role.id
            )
            db.add(superadmin_user)
            db.commit()
            db.refresh(superadmin_user)
            
            # Check if profile exists
            existing_profile = db.query(UserProfile).filter(
                UserProfile.user_id == superadmin_user.id
            ).first()
            
            if not existing_profile:
                profile = UserProfile(
                    user_id=superadmin_user.id, 
                    nama_lengkap="Super Admin"
                )
                db.add(profile)
                db.commit()
            
            print(f"✅ SuperAdmin created: {superadmin_email} / superadmin123")
        
        print("\n" + "="*60)
        print("SuperAdmin Account:")
        print(f"  Email: superadmin@kostraktor.com")
        print(f"  Password: superadmin123")
        print("="*60)
            
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("Setting up SuperAdmin account...")
    setup_superadmin()
    print("\n✅ Setup complete!")
