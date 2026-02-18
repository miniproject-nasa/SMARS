import 'package:flutter/material.dart';
import 'patient_register_screen.dart';
// import 'patient_home_screen.dart';
import 'patient_dashboard_screen.dart';



class PatientLoginScreen extends StatelessWidget {
  PatientLoginScreen({super.key});

  final mobileController = TextEditingController();
  final otpController = TextEditingController();

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
              const SizedBox(height: 10),

              const Text(
                "Log In",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 80),

              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Mobile Number",
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

              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "OTP",
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientDashboardScreen()),
                    );
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientRegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Sign Up",
                    style: TextStyle(color: primaryBlue),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
