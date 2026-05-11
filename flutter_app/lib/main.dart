import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/splash_decider_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Firebase for Android/iOS
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();

      print("✅ Firebase initialized");

      await NotificationService.initialize();
    } catch (e) {
      print("❌ Firebase error: $e");
    }
  }

  runApp(const SmarsApp());
}

class SmarsApp extends StatelessWidget {
  const SmarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'SMARS',

      home: const SplashDeciderScreen(),
    );
  }
}
