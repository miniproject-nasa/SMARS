import 'package:flutter/material.dart';
import 'patient_login_screen.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: primaryBlue),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: primaryBlue),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: primaryBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),

                const SizedBox(height: 60),

                // Full Name
                TextField(
                  controller: nameController,
                  decoration: inputStyle("Full Name"),
                ),

                const SizedBox(height: 30),

                // Date of Birth
                TextField(
                  controller: dobController,
                  readOnly: true,
                  onTap: pickDate,
                  decoration: inputStyle("Date of Birth"),
                ),

                const SizedBox(height: 30),

                // Mobile Number
                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: inputStyle("Mobile Number"),
                ),

                const SizedBox(height: 30),

                // OTP
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: inputStyle("OTP"),
                ),

                const SizedBox(height: 60),

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
                    onPressed: () {},
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => PatientLoginScreen()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
