import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handler background/terminated — HARUS top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [FCM Background] Message received: ${message.data}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Local notification plugin
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Channel ID untuk notifikasi kos
  static const _channelId = 'kostraktor_channel';
  static const _channelName = 'Kostraktor Notifikasi';

  /// Inisialisasi FCM + Local Notifications
  static Future<void> initialize() async {
    // 1. Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 3. Inisialisasi flutter_local_notifications
    await _initLocalNotifications();

    // 4. Log FCM token
    final token = await _messaging.getToken();
    debugPrint('📱 [FCM] Device Token:\n$token');

    // 5. Refresh token listener
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 [FCM] Token refreshed: $newToken');
    });

    // 6. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔥 [FCM] Foreground Message Received: ${message.data}');
      debugPrint('   Title : ${message.notification?.title}');
      debugPrint('   Body  : ${message.notification?.body}');

      final type = message.data['type'];
      final hasNotification = message.notification != null;

      if (type == 'rental_expiry' || (type == null && hasNotification)) {
        _showLocalNotification(
          title: message.notification?.title ?? 'Masa Sewa Habis',
          body: message.notification?.body ??
              'Masa sewa kamu telah berakhir. Segera hubungi admin.',
        );
      }
    });

    // 7. App dibuka dari notif (terminated)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('🚀 [FCM] App opened from terminated: ${message.data}');
      }
    });

    // 8. App dibuka dari notif (background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('📂 [FCM] App opened from background: ${message.data}');
    });
  }

  /// Inisialisasi flutter_local_notifications
  static Future<void> _initLocalNotifications() async {
    // Android: gunakan icon launcher default
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);

    // Buat notification channel khusus Kostraktor (Android 8+)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi penting dari Kostraktor',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  /// Tampilkan notifikasi di status bar HP
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifikasi penting dari Kostraktor',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title,
      body,
      notifDetails,
    );
    debugPrint('🔔 [Local Notif] Shown: $title');
  }

  /// Tampilkan dialog di dalam app menggunakan navigatorKey
  static void _showRentalExpiryDialog({
    required GlobalKey<NavigatorState>? navigatorKey,
    required String title,
    required String body,
  }) {
    final context = navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('⚠️ [FCM] Tidak bisa show dialog: context = null');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF07132B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07132B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dapatkan FCM token device
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
