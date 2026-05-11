import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/splash_decider_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // Initialize notifications
  await NotificationService.initialize();

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
