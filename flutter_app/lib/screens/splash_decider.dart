import 'package:flutter/material.dart';
import '../utils/session_manager.dart';
import 'login_screen.dart';
import 'patient_dashboard.dart';
import 'caregiver_dashboard.dart';

class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    decideRoute();
  }

  Future<void> decideRoute() async {
    final session = await SessionManager.getSession();

    if (session.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } else if (session['role'] == 'patient') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CaregiverDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
