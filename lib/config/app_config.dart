/// Konfigurasi Aplikasi Kostraktor
/// File ini berisi pengaturan yang bisa diubah oleh admin
class AppConfig {
  // 📱 NOMOR WHATSAPP ADMIN
  // =====================================
  // Format: 62XXXXXXXXXX (dengan kode negara Indonesia 62)
  // Contoh: 6281234567890 untuk nomor 081234567890
  // PENTING: Ganti dengan nomor WhatsApp admin yang aktif!
  // JANGAN gunakan tanda +, spasi, atau karakter lain
  static const String adminWhatsAppNumber =
      '6282123456789'; // 👈 GANTI NOMOR INI dengan nomor admin sebenarnya

  // 🏪 INFORMASI KOSAN
  // =====================================
  static const String kosanName = 'Kostraktor';
  static const String kosanAddress = 'Pasar Rebo, Jakarta Timur';
  static const String managementName = 'PT KOSTRAKTOR JAYA UTAMA';

  // 🏦 INFORMASI BANK
  // =====================================
  static const String bankName = 'Bank Mandiri';
  static const String bankAccountNumber = '123-00-998877-1';
  static const String bankAccountName = 'PT KOSTRAKTOR JAYA UTAMA';

  // ⏰ PENGATURAN PEMBAYARAN
  // =====================================
  static const int paymentTimeoutHours = 2; // Batas waktu pembayaran (jam)
  static const int paymentTimeoutSeconds =
      paymentTimeoutHours * 3600; // Dalam detik

  // 📧 TEMPLATE PESAN WHATSAPP
  // =====================================
  static const String paymentConfirmationTemplate =
      '''Halo Admin {kosanName}! 👋

Saya ingin konfirmasi pembayaran booking kos:

📝 *Data Booking:*
• Nama: {userName}
• No. HP: {userPhone}
• Tipe Kamar: {roomType}
• Total Bayar: {totalAmount}
• Kode Unik: {uniqueCode}

Saya sudah melakukan transfer. Mohon dicek ya! 🙏

_Pesan ini dikirim otomatis dari Aplikasi {kosanName}_''';

  static const String generalContactTemplate = '''Halo Admin {kosanName}! 👋

{customMessage}

_Pesan ini dikirim dari Aplikasi {kosanName}_''';

  // 🎨 PENGATURAN TEMA
  // =====================================
  static const String primaryColor = '#000000'; // Warna hitam utama
  static const String accentColor = '#FFD700'; // Warna emas
  static const String whatsappColor = '#25D366'; // Warna WhatsApp

  // 🔧 PENGATURAN DEVELOPMENT
  // =====================================
  static const bool debugMode = true; // Set false untuk production
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // 📍 PENGATURAN LOKASI
  // =====================================
  static const double defaultLatitude = -6.3019442; // Jakarta Timur
  static const double defaultLongitude = 106.8638308;
  static const int mapZoomLevel = 15;

  // 🔐 VALIDASI KONFIGURASI
  // =====================================
  static bool get isValidWhatsAppNumber {
    return adminWhatsAppNumber.startsWith('62') &&
        adminWhatsAppNumber.length >= 11 &&
        adminWhatsAppNumber.length <= 15 &&
        RegExp(r'^[0-9]+$').hasMatch(adminWhatsAppNumber);
  }

  static String get formattedWhatsAppNumber {
    if (!isValidWhatsAppNumber) {
      throw Exception(
        'Nomor WhatsApp tidak valid: $adminWhatsAppNumber\n'
        'Format yang benar: 62XXXXXXXXXX\n'
        'Contoh: 6281234567890',
      );
    }
    return adminWhatsAppNumber;
  }

  // 🌐 URL DAN ENDPOINT
  // =====================================
  static const String websiteUrl = 'https://kostraktor.com';
  static const String supportEmail = 'support@kostraktor.com';
  static const String privacyPolicyUrl = 'https://kostraktor.com/privacy';
  static const String termsOfServiceUrl = 'https://kostraktor.com/terms';
}

/// Helper class untuk format template pesan
class MessageTemplateHelper {
  static String formatPaymentConfirmation({
    required String userName,
    required String userPhone,
    required String roomType,
    required String totalAmount,
    required int uniqueCode,
  }) {
    return AppConfig.paymentConfirmationTemplate
        .replaceAll('{kosanName}', AppConfig.kosanName)
        .replaceAll('{userName}', userName)
        .replaceAll('{userPhone}', userPhone)
        .replaceAll('{roomType}', roomType)
        .replaceAll('{totalAmount}', totalAmount)
        .replaceAll('{uniqueCode}', uniqueCode.toString());
  }

  static String formatGeneralContact({required String customMessage}) {
    return AppConfig.generalContactTemplate
        .replaceAll('{kosanName}', AppConfig.kosanName)
        .replaceAll('{customMessage}', customMessage);
  }
}
