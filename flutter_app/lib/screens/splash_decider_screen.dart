import 'package:flutter/material.dart';
import '../utils/session_manager.dart';
import 'home_landing_screen.dart';
import 'patient_dashboard_screen.dart';
import 'caregiver_dashboard.dart';

/// Shows a brief loading then redirects: if user is logged in, to dashboard;
/// otherwise to landing. Ensures "stay logged in" and auto-login on app reopen.
class SplashDeciderScreen extends StatelessWidget {
  const SplashDeciderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: SessionManager.getSession(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        final session = snapshot.data!;
        if (session.isEmpty) {
          return const HomeLandingScreen();
        }
        final role = session['role'];
        if (role == 'patient') {
          return const PatientDashboardScreen();
        }
        if (role == 'caregiver') {
          return const CaregiverDashboard();
        }
        return const HomeLandingScreen();
      },
    );
  }
}
