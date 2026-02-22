import 'package:flutter/material.dart';
import 'caregiver_login_screen.dart';
import '../services/api_service.dart';

class CaregiverRegisterScreen extends StatefulWidget {
  const CaregiverRegisterScreen({super.key});

  @override
  State<CaregiverRegisterScreen> createState() => _CaregiverRegisterScreenState();
}

class _CaregiverRegisterScreenState extends State<CaregiverRegisterScreen> {
  final usernameController = TextEditingController();
  final dobController = TextEditingController();
  final tokenController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _otpLoading = false;

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

  Future<void> _onSendOtp() async {
    final mobile = mobileController.text.trim();
    if (mobile.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter mobile number first'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _otpLoading = true);
    try {
      final data = await ApiService.sendOtp(mobile);
      if (!mounted) return;
      final otp = data['otp'] as String?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            otp != null
                ? 'OTP sent. Your OTP: $otp'
                : 'OTP sent successfully. Check your message.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }

  Future<void> _onRegister() async {
    final username = usernameController.text.trim();
    final dob = dobController.text.trim();
    final patientToken = tokenController.text.trim();
    final mobile = mobileController.text.trim();
    final otp = otpController.text.trim();
    final password = passwordController.text.trim();

    final missing = <String>[];
    if (username.isEmpty) missing.add('Username');
    if (dob.isEmpty) missing.add('Date of birth');
    if (patientToken.isEmpty) missing.add('Patient token');
    if (mobile.isEmpty) missing.add('Phone number');
    if (otp.isEmpty) missing.add('OTP');
    if (password.isEmpty) missing.add('Password');

    if (missing.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Missing: ${missing.join(", ")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (password.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 6 characters'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.registerCaregiverSignup(
        username: username,
        password: password,
        dateOfBirth: dob,
        patientToken: patientToken,
        mobile: mobile,
        otp: otp,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registered successfully. Sign in with phone and password.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CaregiverLoginScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  "Caregiver Sign Up",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 60),

                TextField(
                  controller: usernameController,
                  decoration: inputStyle("Username"),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: dobController,
                  readOnly: true,
                  onTap: pickDate,
                  decoration: inputStyle("Date of Birth"),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: tokenController,
                  decoration: inputStyle("Patient Token"),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: inputStyle("Phone Number"),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _otpLoading ? null : _onSendOtp,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: const BorderSide(color: primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _otpLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Generate OTP"),
                  ),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: inputStyle("OTP"),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: inputStyle("Password"),
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
                    onPressed: _isLoading ? null : _onRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
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
                        MaterialPageRoute(builder: (_) => const CaregiverLoginScreen()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Sign In",
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
