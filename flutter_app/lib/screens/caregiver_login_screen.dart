import 'package:flutter/material.dart';
import 'package:smars/screens/caregiver_dashboard.dart';

class CaregiverLoginScreen extends StatelessWidget {
  CaregiverLoginScreen({super.key});

  final patientMobileController = TextEditingController();
  final tokenController = TextEditingController();

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              //const Text("Login", style: TextStyle(color: Colors.black54)),
              //const SizedBox(height: 10),
              const Text(
                "Caregiver Sign In",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 80),

              // Patient Mobile Number
              TextField(
                controller: patientMobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Patient Mobile Number",
                  hintStyle: TextStyle(color: Color(0xFF385399)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryBlue),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Token (alphanumeric)
              TextField(
                controller: tokenController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  hintText: "Token",
                  hintStyle: TextStyle(color: Color(0xFF385399)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryBlue),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaregiverDashboard(),
                      ),
                    );
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
