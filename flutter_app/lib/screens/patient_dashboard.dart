import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'caregiver_dashboard.dart';
import 'login_screen.dart';
import 'package:smars/utils/session_manager.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMARS – Patient'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1️⃣ Welcome Section
            const Text(
              'Hello 👋',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'How can we help you today?',
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 24),

            // 2️⃣ SOS Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Sending SOS...')));

                bool success = await ApiService.triggerSOS();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SOS sent successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SOS failed. Try again.')),
                  );
                }
              },

              child: const Text(
                'SOS',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),

            const SizedBox(height: 24),

            // 3️⃣ Reminders Section
            const Text(
              'Today’s Reminders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.alarm),
                title: const Text('Take morning medicine'),
                subtitle: const Text('8:00 AM'),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.alarm),
                title: const Text('Doctor appointment'),
                subtitle: const Text('2:00 PM'),
              ),
            ),

            const SizedBox(height: 24),

            // 4️⃣ Location / Status (Placeholder)
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Current Status'),
                subtitle: const Text('You are safe at home'),
              ),
            ),
            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaregiverDashboard(),
                  ),
                );
              },
              child: const Text('Go to Caregiver Dashboard'),
            ),

            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await SessionManager.clearSession();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
