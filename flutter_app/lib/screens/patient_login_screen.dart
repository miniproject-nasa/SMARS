import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED IMPORT
import 'patient_register_screen.dart';
import 'patient_dashboard_screen.dart';
import '../services/api_service.dart';
import '../utils/session_manager.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  Future<void> _onLogin() async {
    final mobile = mobileController.text.trim();
    final password = passwordController.text.trim();

    if (mobile.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter mobile number and password'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.login(mobile, password);

      if (!mounted) return;

      final role = data['role'] as String?;
      if (role == 'patient') {
        await SessionManager.savePatientSession(username: mobile);
        
        // SAVE TOKEN FOR BACKEND API CALLS
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) {
          await prefs.setString('auth_token', data['token']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please use the patient login.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              const SizedBox(height: 10),
              const Text("Log In", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: primaryBlue)),
              const SizedBox(height: 80),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Mobile Number", hintStyle: TextStyle(color: Color(0xFF385399)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryBlue)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryBlue)),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password", hintStyle: TextStyle(color: Color(0xFF385399)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryBlue)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryBlue)),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
                  onPressed: _isLoading ? null : _onLogin,
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientRegisterScreen())),
                  child: const Text("Don't have an account? Sign Up", style: TextStyle(color: primaryBlue)),
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