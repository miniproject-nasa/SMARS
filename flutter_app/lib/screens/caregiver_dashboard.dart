import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'caregiver_location_screen.dart';
import '../utils/session_manager.dart';
import 'caregiver_login_screen.dart';
import '../services/api_service.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  bool _sosActive = false;
  String _sosPatientId = "";

  @override
  void initState() {
    super.initState();
    _fetchSOSStatus();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await SessionManager.clearSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CaregiverLoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _fetchSOSStatus() async {
    try {
      final data = await ApiService.getSOSStatus();

      setState(() {
        _sosActive = data['active'] ?? false;
        _sosPatientId = data['patientId'] ?? '';
      });
    } catch (e) {
      print("Error fetching SOS: $e");
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage("assets/profile.png"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Caregiver of",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Text(
                          "Ashiq Kareem",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: primaryBlue,
                      size: 40,
                    ),
                    onPressed: _showLogoutDialog,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              /// 🔹 ALERT BUTTON
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sosActive ? Colors.red : primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await _fetchSOSStatus();
                    },
                    icon: Icon(
                      _sosActive
                          ? Icons.warning_amber_rounded
                          : Icons.notifications,
                      color: Colors.white,
                    ),
                    label: Text(
                      _sosActive ? "🚨 EMERGENCY ALERT" : "No Emergency",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      /// 🔹 FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// 🔹 BOTTOM NAV BAR
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(Icons.home, "Home"),

              const SizedBox(width: 40),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CaregiverLocationScreen(),
                    ),
                  );
                },
                child: _navIcon(Icons.location_on_outlined, "Location"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 REUSED HELPERS (same as patient)

  static Widget _navIcon(IconData icon, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: primaryBlue),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: primaryBlue)),
      ],
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
