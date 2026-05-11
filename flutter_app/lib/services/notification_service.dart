import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Ask permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _messaging.getToken();

    debugPrint('FCM TOKEN: $token');

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        "Notification received: "
        "${message.notification?.title}",
      );
    });

    // Notification click
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("Notification clicked");
    });
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
