# 📖 Panduan Sync Kode dengan Teman (Flutter Project)

## ❓ Problem: Fitur Teman Tidak Muncul Setelah Pull

Jika setelah `git pull`, fitur dari teman (misal: popup WA) tidak muncul di aplikasi Anda, ikuti langkah-langkah berikut:

---

## ✅ **LANGKAH 1: Pastikan Teman Sudah Push Kodenya**

Minta teman Anda untuk:
```bash
# Di komputer teman
git add .
git commit -m "feat: tambah popup WA di home screen"
git push origin main
```

**PENTING:** Fitur tidak akan muncul di komputer Anda jika teman belum push ke GitHub!

---

## ✅ **LANGKAH 2: Pull Kode Terbaru**

```bash
# Stop aplikasi yang sedang running (Ctrl+C atau Stop button di IDE)

# Fetch update terbaru dari GitHub
git fetch origin

# Lihat commit terbaru di GitHub
git log origin/main --oneline -5

# Pull kode terbaru
git pull origin main

# Atau jika ada conflict
git pull origin main --no-rebase
```

---

## ✅ **LANGKAH 3: Full Clean & Rebuild (WAJIB!)**

Ini yang paling penting! Hot reload/restart TIDAK CUKUP setelah pull.

```bash
# 1. Stop aplikasi
# Tekan Ctrl+C atau klik Stop

# 2. Clean semua build cache
flutter clean

# 3. Get dependencies lagi
flutter pub get

# 4. (Optional) Upgrade packages
flutter pub upgrade

# 5. Build ulang dan run
flutter run
```

**JANGAN cuma hot reload (R) atau hot restart (Shift+R)!**

---

## ✅ **LANGKAH 4: Verifikasi Kode Sudah Ter-Update**

### Cek Git Log:
```bash
# Lihat commit terbaru
git log --oneline -5

# Pastikan commit teman sudah ada
```

### Cek File Manual:
```bash
# Buka file yang diubah teman, misal:
# lib/screens/home_screen.dart

# Search kode popup WA dengan Ctrl+F
```

---

## 🔍 **Troubleshooting**

### Problem 1: "Sudah pull tapi kode teman tidak ada"
**Solusi:**
```bash
# Cek apakah teman sudah push
git log origin/main --oneline -10

# Jika commit teman tidak ada, minta dia push dulu
```

### Problem 2: "Sudah pull dan clean tapi fitur tidak muncul"
**Solusi:**
```bash
# Pastikan tidak ada conflict yang belum di-resolve
git status

# Jika ada conflict, resolve dulu
# Lalu commit merge
git add .
git commit -m "Merge: resolve conflict"
```

### Problem 3: "Hot reload tidak update kode baru"
**Solusi:**
```bash
# JANGAN pakai hot reload setelah pull!
# HARUS full rebuild:

flutter clean
flutter pub get
flutter run

# Atau di IDE: Stop → Clean → Rebuild → Run
```

### Problem 4: "Aplikasi crash setelah pull"
**Solusi:**
```bash
# Check dependencies
flutter pub get

# Check error di console
flutter analyze

# Delete node_modules equivalent
rm -rf .dart_tool
rm -rf build
flutter pub get
flutter run
```

---

## 📝 **Checklist Sync Kode:**

- [ ] Teman sudah `git push origin main`
- [ ] Saya sudah `git pull origin main`
- [ ] Saya sudah `flutter clean`
- [ ] Saya sudah `flutter pub get`
- [ ] Saya sudah STOP aplikasi sebelum rebuild
- [ ] Saya sudah `flutter run` (BUKAN hot reload)
- [ ] Saya cek `git log` untuk confirm commit teman ada
- [ ] Saya cek file manual untuk pastikan kode sudah ada

---

## 🚀 **Best Practice untuk Team Development**

### Sebelum Coding:
```bash
git pull origin main     # Pull dulu sebelum coding
flutter clean            # Clean dulu
flutter pub get          # Get dependencies
flutter run              # Run untuk test
```

### Setelah Coding:
```bash
git add .
git commit -m "feat: deskripsi fitur yang dibuat"
git push origin main     # Push agar teman bisa pull
```

### Ketika Mau Test Fitur Teman:
```bash
git pull origin main     # Pull kode teman
flutter clean            # WAJIB clean
flutter pub get          # Update dependencies
flutter run              # Full rebuild
```

---

## ⚠️ **KESALAHAN UMUM**

❌ **JANGAN:** Hot reload (R) setelah git pull  
✅ **LAKUKAN:** Full rebuild dengan `flutter run`

❌ **JANGAN:** Continue run setelah git pull  
✅ **LAKUKAN:** Stop → Clean → Run

❌ **JANGAN:** Pull tanpa commit local changes  
✅ **LAKUKAN:** Commit dulu atau stash

❌ **JANGAN:** Assume teman sudah push  
✅ **LAKUKAN:** Confirm dengan `git log origin/main`

---

## 💡 **Tips**

1. **Selalu komunikasi dengan team:** "Sudah push belum?"
2. **Gunakan branch untuk fitur besar:** Biar tidak bentrok
3. **Pull sebelum push:** Biar tidak conflict
4. **Clean after pull:** Biar kode benar-benar update
5. **Test after pull:** Pastikan aplikasi masih jalan

---

## 🎯 **Specific: Popup WA di Home Screen**

Jika popup WA yang dimaksud, kemungkinan ada di:
- `lib/screens/home_screen.dart` → Floating button atau dialog
- `lib/widgets/` → Custom popup widget
- `lib/main.dart` → Initial dialog saat app launch

**Cara cek:**
```bash
# Search all files
grep -r "popup\|dialog.*wa\|whatsapp" lib/

# Atau di Windows PowerShell
Select-String -Path "lib\**\*.dart" -Pattern "popup|WhatsApp" -CaseSensitive
```

Jika tidak ada, artinya **teman belum push kode itu ke GitHub!**

---

## 📞 **Minta Teman Push dengan Benar**

Kirim pesan ini ke teman:
```
"Mas/Mbak, popup WA nya sudah di-push belum? 
Coba jalanin command ini:

git status
git add .
git commit -m "feat: tambah popup WA"
git push origin main

Terus kasih tau ya kalau udah push, biar aku pull lagi."
```

---

**Good luck! 🚀**
