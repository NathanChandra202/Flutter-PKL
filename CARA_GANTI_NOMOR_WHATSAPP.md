# 📞 Cara Mengganti Nomor WhatsApp Admin

## 🎯 LANGKAH MUDAH UNTUK ADMIN

### 1. Buka File Konfigurasi
Buka file: `lib/config/app_config.dart`

### 2. Cari Baris Ini:
```dart
static const String adminWhatsAppNumber = '6281234567890'; // 👈 GANTI NOMOR INI
```

### 3. Ganti Nomor:
**Format yang BENAR**: `62XXXXXXXXXX` (dimulai dengan 62)

**Contoh**:
- Nomor asli: `081234567890`
- Yang diinput: `6281234567890`

**Contoh perubahan**:
```dart
// SEBELUM (contoh)
static const String adminWhatsAppNumber = '6281234567890';

// SESUDAH (ganti dengan nomor admin sebenarnya)
static const String adminWhatsAppNumber = '6285678901234';
```

### 4. Save File & Rebuild App
1. Save file `app_config.dart`
2. Jalankan `flutter clean`
3. Jalankan `flutter pub get`
4. Build ulang aplikasi: `flutter build apk --release`

## ✅ CONTOH NOMOR YANG BENAR

| Nomor Original | Input yang Benar |
|----------------|------------------|
| 081234567890   | 6281234567890   |
| 085678901234   | 6285678901234   |
| 087654321098   | 6287654321098   |
| 089876543210   | 6289876543210   |

## ❌ FORMAT YANG SALAH

| ❌ SALAH | ✅ BENAR |
|----------|----------|
| +6281234567890 | 6281234567890 |
| 081234567890   | 6281234567890 |
| 62 81234567890 | 6281234567890 |
| 62-81234567890 | 6281234567890 |

## 🔧 KONFIGURASI LAINNYA

Di file `app_config.dart` Anda juga bisa mengubah:

### Nama Kosan:
```dart
static const String kosanName = 'Kostraktor'; // Nama kosan Anda
```

### Informasi Bank:
```dart
static const String bankName = 'Bank Mandiri';
static const String bankAccountNumber = '123-00-998877-1';
static const String bankAccountName = 'PT KOSTRAKTOR JAYA UTAMA';
```

### Template Pesan WhatsApp:
```dart
static const String paymentConfirmationTemplate = '''Halo Admin {kosanName}! 👋
...
''';
```

## 🚨 PENTING!

1. **JANGAN** pakai tanda + di depan nomor
2. **JANGAN** pakai spasi atau strip
3. **HARUS** dimulai dengan 62 (kode Indonesia)
4. Nomor harus **11-15 digit** total
5. **Save dan rebuild** aplikasi setelah perubahan

## 📱 Test Nomor WhatsApp

Setelah mengganti nomor, test dengan cara:
1. Buka aplikasi
2. Pergi ke halaman Pembayaran
3. Klik tombol "Hubungi Admin via WhatsApp"
4. Pastikan WhatsApp terbuka dan nomor sudah benar

## 🆘 TROUBLESHOOTING

### "Nomor WhatsApp tidak valid"
- Periksa format nomor (harus dimulai dengan 62)
- Pastikan tidak ada spasi, tanda +, atau karakter lain
- Panjang nomor harus 11-15 digit

### "Error saat build"
- Jalankan `flutter clean`
- Jalankan `flutter pub get`
- Build ulang aplikasi

### "WhatsApp tidak terbuka"
- Pastikan nomor benar dan aktif
- Test kirim pesan manual ke nomor tersebut
- Pastikan WhatsApp terinstal di device

---

## ✨ SELESAI!

Fitur WhatsApp sudah siap dengan nomor admin yang baru! 🎉

**Butuh bantuan?** Hubungi developer yang menangani aplikasi ini.