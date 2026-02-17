import 'package:flutter/material.dart';
// import 'screens/login_screen.dart';
// import 'screens/splash_decider.dart';
import 'screens/home_landing_screen.dart';

void main() {
  runApp(const SmarsApp());
}

class SmarsApp extends StatelessWidget {
  const SmarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMARS',
      home: const HomeLandingScreen(),
    );
  }
}
