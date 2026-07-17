# Kostraktor

app buat ngurus kost digital, dari cari kamar sampe jadi penghuni — semua di satu tempat. dibuat pake Flutter.

---

## jalanin dulu

```bash
flutter pub get
flutter run -d chrome
```

---

## akun buat nyoba

| role | email | password |
|---|---|---|
| calon penghuni | calon@kostraktor.com | 123456 |
| admin | admin@kostraktor.comksih | admin123 |

atau bisa daftar sendiri, email bebas apa aja

---

## cara pakainya

**kalau calon penghuni:**

- buka app, lihat-lihat unit dulu di home
- kalau mau sewa, klik unit terus klik ajukan sewa
- login dulu kalau belum
- isi data diri, terus verifikasi KTP sama selfie (ada tantangan acak kayak senyum atau berkedip, biar ga bisa pake foto orang lain)
- transfer ke rekening yang muncul, nominalnya harus tepat termasuk kode uniknya
- klik konfirmasi, udah — tinggal tunggu admin approve

**kalau admin:**

- login pake akun admin, langsung masuk ke panel
- pilih user dari antrian yang muncul
- cek datanya, isi nomor kamar
- klik approve — status user langsung berubah jadi penghuni aktif
- kalau ada masalah ya klik tolak

**kalau udah jadi penghuni aktif:**

- tab komunitas sama lapor kebuka
- bisa lapor kalau ada fasilitas rusak
- bisa pinjam alat (vacuum, bor, dll) lewat tombol peminjaman alat di komunitas
- hubungi manajemen langsung dari profil

---

## screen yang ada

```
splash             → loading
onboarding         → halaman pertama
login              → masuk / daftar
home               → list kamar
detail             → detail kamar
booking form       → isi data + verifikasi ktp & selfie
liveness           → foto ktp + selfie liveness
pembayaran         → info transfer & konfirmasi
komunitas          → jastip & notice board penghuni
peminjaman alat    → pinjam alat bersama
lapor & audit      → pengaduan fasilitas
profil             → status akun & logout
admin panel        → approve / reject booking
```

---

## hal yang perlu diketahui

- data belum tersambung ke server, masih nyimpen di memori — kalau app di-restart balik ke awal
- nomor WA penjaga kos ada di `countdown_screen.dart` sama `profile_screen.dart`, ganti sendiri sesuai nomor asli
- untuk production tinggal sambungin AuthProvider ke Firebase atau Supabase

---

> project PKL — Kostraktor, kost premium Jakarta Timur
