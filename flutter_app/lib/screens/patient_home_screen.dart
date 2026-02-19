import 'package:flutter/material.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Emergency Alert"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          const SizedBox(height: 40),

          /// 🔴 BIG SOS BUTTON
          Center(
            child: GestureDetector(
              onTap: () {
                _showSentDialog(context);
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: primaryBlue, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: const Center(
                  child: Text(
                    "SOS",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Tap to send emergency alert",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),

          const SizedBox(height: 40),

          /// 🔹 ACTION BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [

                /// CALL CAREGIVER
                _actionButton(Icons.call, "Call Caregiver", () {}),

                const SizedBox(height: 16),

                /// SHARE LOCATION
                _actionButton(Icons.location_on, "Share Location", () {}),

                const SizedBox(height: 16),

                /// RESTART
                _actionButton(Icons.refresh, "Restart Alert", () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 BUTTON WIDGET
  static Widget _actionButton(
      IconData icon, String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  /// 🔹 CONFIRMATION DIALOG
  static void _showSentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Alert Sent"),
        content: const Text(
            "Your caregiver has been notified and your location is being shared."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}
