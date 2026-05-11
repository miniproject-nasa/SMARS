import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint(
        'Permission: '
        '${settings.authorizationStatus}',
      );

      String? token = await _messaging.getToken();

      debugPrint('FCM TOKEN: $token');

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          "Notification received: "
          "${message.notification?.title}",
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint("Notification clicked");
      });
    } catch (e) {
      debugPrint("Notification init error: $e");
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint("FCM token error: $e");
      return null;
    }
  }
}
