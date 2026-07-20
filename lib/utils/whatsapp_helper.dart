import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class WhatsAppHelper {
  // Menggunakan nomor dari AppConfig untuk memudahkan konfigurasi
  static String get adminPhoneNumber => AppConfig.formattedWhatsAppNumber;

  /// Format nomor telepon untuk WhatsApp
  static String formatPhoneNumber(String phoneNumber) {
    // Hapus karakter non-digit
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Jika dimulai dengan 0, ganti dengan 62
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }

    // Jika tidak dimulai dengan 62, tambahkan 62
    if (!cleanNumber.startsWith('62')) {
      cleanNumber = '62$cleanNumber';
    }

    return cleanNumber;
  }

  /// Kirim pesan ke WhatsApp dengan berbagai metode fallback
  static Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
    required BuildContext context,
  }) async {
    final formattedNumber = formatPhoneNumber(phoneNumber);
    final encodedMessage = Uri.encodeComponent(message);

    // Daftar URL WhatsApp untuk dicoba
    final whatsappUrls = [
      // App WhatsApp langsung
      Uri.parse('whatsapp://send?phone=$formattedNumber&text=$encodedMessage'),
      // WhatsApp web/app hybrid
      Uri.parse('https://wa.me/$formattedNumber?text=$encodedMessage'),
      // API WhatsApp
      Uri.parse(
        'https://api.whatsapp.com/send?phone=$formattedNumber&text=$encodedMessage',
      ),
    ];

    // Coba setiap URL sampai ada yang berhasil
    for (final whatsappUrl in whatsappUrls) {
      try {
        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          return true;
        }
      } catch (e) {
        debugPrint('WhatsApp URL gagal: $whatsappUrl - Error: $e');
        continue;
      }
    }

    // Jika semua gagal, coba buka WhatsApp Web
    try {
      final webUrl = Uri.parse(
        'https://web.whatsapp.com/send?phone=$formattedNumber&text=$encodedMessage',
      );
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('WhatsApp Web gagal: $e');
    }

    return false;
  }

  /// Kirim pesan konfirmasi pembayaran ke admin
  static Future<void> contactAdminPaymentConfirmation({
    required BuildContext context,
    required String nama,
    required String phone,
    required String roomType,
    required String totalAmount,
    required int uniqueCode,
  }) async {
    final message = MessageTemplateHelper.formatPaymentConfirmation(
      userName: nama,
      userPhone: phone,
      roomType: roomType,
      totalAmount: totalAmount,
      uniqueCode: uniqueCode,
    );

    final success = await sendMessage(
      phoneNumber: adminPhoneNumber,
      message: message,
      context: context,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'WhatsApp berhasil dibuka! Silakan kirim pesan ke admin.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      _showErrorSnackBar(context, message);
    }
  }

  /// Kirim pesan umum ke admin
  static Future<void> contactAdminGeneral({
    required BuildContext context,
    String? customMessage,
  }) async {
    final message = MessageTemplateHelper.formatGeneralContact(
      customMessage:
          customMessage ??
          'Saya memiliki pertanyaan terkait aplikasi ${AppConfig.kosanName}.',
    );

    final success = await sendMessage(
      phoneNumber: adminPhoneNumber,
      message: message,
      context: context,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('WhatsApp berhasil dibuka!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      _showErrorSnackBar(context, message);
    }
  }

  /// Tampilkan error message dengan opsi salin nomor
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tidak dapat membuka WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan WhatsApp terinstal atau hubungi admin di:\n$adminPhoneNumber',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Salin Nomor',
          textColor: Colors.white,
          onPressed: () => copyToClipboard(adminPhoneNumber, context),
        ),
      ),
    );
  }

  /// Salin teks ke clipboard
  static void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$text disalin ke clipboard'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// Check apakah WhatsApp terinstal
  static Future<bool> isWhatsAppInstalled() async {
    try {
      final whatsappUrl = Uri.parse('whatsapp://');
      return await canLaunchUrl(whatsappUrl);
    } catch (e) {
      return false;
    }
  }

  /// Buat widget tombol WhatsApp yang bisa digunakan di berbagai screen
  static Widget buildWhatsAppButton({
    required BuildContext context,
    required VoidCallback onPressed,
    String? label,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    double? width,
    EdgeInsets? padding,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: backgroundColor ?? const Color(0xFF25D366),
            width: 2,
          ),
          foregroundColor: textColor ?? const Color(0xFF25D366),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon ?? Icons.chat_bubble_outline, size: 22),
        label: Text(
          label ?? 'Hubungi Admin via WhatsApp',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
