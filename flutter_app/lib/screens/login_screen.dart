import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'patient_dashboard.dart';
import 'caregiver_dashboard.dart';
import '../utils/session_manager.dart';
import 'patient_register_screen.dart';
import 'caregiver_register_screen.dart';

class LoginScreen extends StatelessWidget {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMARS Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final user = await ApiService.login(
                    usernameController.text.trim(),
                    passwordController.text.trim(),
                  );

                  if (user['role'] == 'patient') {
                    await SessionManager.savePatientSession(
                      username: user['username'],
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientDashboard(),
                      ),
                    );
                  } else {
                    await SessionManager.saveCaregiverSession(
                      username: user['username'],
                      patientUsername: user['patientUsername'],
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaregiverDashboard(),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Login'),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PatientRegisterScreen()),
                );
              },
              child: const Text('Register as Patient'),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CaregiverRegisterScreen()),
                );
              },
              child: const Text('Register as Caregiver'),
            ),
          ],
        ),
      ),
    );
  }
}
