import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  //const PatientHomeScreen({super.key});

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  Future<void> _triggerSOSWithLocation() async {
    try {
      // STEP 1 — Send SOS
      bool sosSuccess = await ApiService.triggerSOS();

      // STEP 2 — Get location permission
      LocationPermission permission;

      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // STEP 3 — Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("LATITUDE: ${position.latitude}");
      print("LONGITUDE: ${position.longitude}");

      // STEP 4 — Send location
      bool locationSuccess = await ApiService.updateLocation(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      _showSentDialog(context, sosSuccess && locationSuccess);
    } catch (e) {
      print("SOS Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text(
          "Emergency Alert",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔴 BIG SOS BUTTON
            GestureDetector(
              onTap: _triggerSOSWithLocation,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: primaryBlue, width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "SOS",
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Tap to call caregiver & share location",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 CONFIRMATION DIALOG
  void _showSentDialog(BuildContext context, bool success) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(success ? "Alert Sent" : "Failed"),
        content: Text(
          success
              ? "Your caregiver has been alerted and your location was shared."
              : "Failed to send SOS alert.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
  }
}
