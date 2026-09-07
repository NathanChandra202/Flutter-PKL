# 🔐 SuperAdmin Setup Guide

## Perbedaan Role: Admin vs SuperAdmin

| Fitur | Admin | SuperAdmin |
|-------|-------|------------|
| Dashboard Overview | ✅ | ✅ |
| Kelola Booking | ✅ | ✅ |
| Kelola Kamar | ✅ | ✅ |
| Kelola Jastip | ✅ | ✅ |
| Kelola Alat | ✅ | ✅ |
| Kelola Ulasan | ✅ | ✅ |
| Audit Laporan | ✅ | ✅ |
| Pengaturan Kost | ✅ | ✅ |
| **Kelola User** | ❌ | ✅ |

### Fitur Khusus SuperAdmin: Kelola User
- Lihat semua user yang terdaftar
- Ubah role user (Admin, User, Owner, SuperAdmin)
- Aktifkan/nonaktifkan akun user
- Manage user permissions

---

## 🚀 Cara Setup SuperAdmin

### Opsi 1: Jalankan Seed Script (Recommended)

```bash
cd backend
python seed_data.py
```

Script ini akan membuat:
- ✅ Role: Admin, User, Owner, SuperAdmin
- ✅ SuperAdmin account: superadmin@kostraktor.com / superadmin123
- ✅ Admin account: admin@kostraktor.com / admin123
- ✅ Test user: user@test.com / test123

### Opsi 2: Setup SuperAdmin Saja

Jika sudah ada database dan hanya ingin tambah SuperAdmin:

```bash
cd backend
python setup_superadmin.py
```

Script ini akan:
- Create SuperAdmin role jika belum ada
- Create akun superadmin@kostraktor.com
- Atau update user yang sudah ada menjadi SuperAdmin

---

## 🔑 Akun Login

### SuperAdmin (Full Access)
```
Email: superadmin@kostraktor.com
Password: superadmin123
```

### Admin (Tanpa Kelola User)
```
Email: admin@kostraktor.com
Password: admin123
```

### User Biasa
```
Email: user@test.com
Password: test123
```

---

## 📋 Testing Checklist

### Test SuperAdmin Features:

1. **Login sebagai SuperAdmin**
   - [ ] Buka http://localhost:3000 (admin dashboard)
   - [ ] Login dengan superadmin@kostraktor.com / superadmin123
   - [ ] Verifikasi role "SuperAdmin" muncul di dashboard

2. **Cek Menu Kelola User**
   - [ ] Verifikasi menu "Kelola User" muncul di sidebar
   - [ ] Klik menu "Kelola User"
   - [ ] Lihat list semua user

3. **Test Kelola User Functions**
   - [ ] Ubah role user biasa
   - [ ] Aktifkan/nonaktifkan akun
   - [ ] Verifikasi perubahan tersimpan

4. **Test Admin vs SuperAdmin**
   - [ ] Logout dari SuperAdmin
   - [ ] Login sebagai Admin (admin@kostraktor.com)
   - [ ] Verifikasi menu "Kelola User" TIDAK muncul
   - [ ] Verifikasi menu lain tetap bisa diakses

---

## 🔧 Troubleshooting

### SuperAdmin tidak bisa login
```bash
# Reset database dan seed ulang
cd backend
python reset_db.py
python seed_data.py
```

### Menu "Kelola User" tidak muncul
1. Cek role di database:
```bash
cd backend
python -c "from app.db.session import SessionLocal; from app.models.user import User; db = SessionLocal(); user = db.query(User).filter(User.email=='superadmin@kostraktor.com').first(); print(f'Role: {user.role.name if user and user.role else None}')"
```

2. Pastikan Next.js admin sudah restart setelah perubahan

3. Clear browser cache dan cookies

### Backend error saat create SuperAdmin
```bash
# Check apakah role SuperAdmin ada
cd backend
python -c "from app.db.session import SessionLocal; from app.models.role import Role; db = SessionLocal(); roles = db.query(Role).all(); print([r.name for r in roles])"
```

---

## 🎯 Next Steps

1. **Run seed script:**
   ```bash
   cd backend
   python seed_data.py
   ```

2. **Restart backend:**
   ```bash
   python -m uvicorn app.main:app --reload
   ```

3. **Restart Next.js admin:**
   ```bash
   cd kostraktor-admin
   npm run dev
   ```

4. **Login dan test:**
   - Buka http://localhost:3000
   - Login dengan superadmin@kostraktor.com / superadmin123
   - Cek menu "Kelola User" muncul

---

## 📝 Developer Notes

### Backend Changes Made:
1. ✅ `backend/seed_data.py` - Added SuperAdmin role and account creation
2. ✅ `backend/setup_superadmin.py` - Standalone script untuk setup SuperAdmin
3. ✅ `backend/app/api/endpoints/users.py` - Already has SuperAdmin-only endpoints

### Frontend (Next.js Admin):
Menu "Kelola User" sudah ada di:
- `kostraktor-admin/app/(dashboard)/layout.tsx` - Navigation with SuperAdmin check
- `kostraktor-admin/app/(dashboard)/users/page.tsx` - User management page
- `kostraktor-admin/lib/api.ts` - API functions for user management

### Role Hierarchy:
```
SuperAdmin > Admin > Owner > User
```

Only SuperAdmin can:
- Access `/users` endpoint
- Change user roles
- Activate/deactivate accounts
- View all user details
