import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CaregiverRegisterScreen extends StatelessWidget {
  CaregiverRegisterScreen({super.key});

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final patientUsernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver Registration')),
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
            TextField(
              controller: patientUsernameController,
              decoration: const InputDecoration(labelText: 'Patient Username'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Register'),
              onPressed: () async {
                try {
                  await ApiService.registerCaregiver(
                    usernameController.text.trim(),
                    passwordController.text.trim(),
                    patientUsernameController.text.trim(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caregiver registered')),
                  );

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
