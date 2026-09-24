import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Handler untuk notifikasi background/terminated (harus top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Received: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Inisialisasi FCM — panggil ini di main() setelah Firebase.initializeApp()
  static Future<void> initialize() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permission (iOS & Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    // 3. Get FCM Token (untuk dikirim ke backend agar bisa target device ini)
    final token = await _messaging.getToken();
    debugPrint('[FCM] Device Token: $token');

    // 4. Listen token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed: $newToken');
      // TODO: kirim newToken ke backend via API
    });

    // 5. Handle message saat app dibuka dari notifikasi (terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    // 6. Handle message saat app dibuka dari notifikasi (background state)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    debugPrint('[FCM] Notification tapped, type: $type');
    // Navigasi berdasarkan type bisa ditambahkan di sini jika ada GlobalNavigatorKey
  }

  /// Mendapatkan FCM token saat ini — untuk dikirim ke server backend
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
