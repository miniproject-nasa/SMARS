import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'caregiver_location_screen.dart';
import '../utils/session_manager.dart';
import 'caregiver_login_screen.dart';
import '../services/api_service.dart';
import 'notes_module_screen.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  bool _isLoadingProfile = true;
  bool _isEditingDetails = false;

  String _patientUsername = "";

  String _profileName = "Patient";
  String _profilePatientId = "";
  String _profilePicUrl = "";

  final TextEditingController _nameCtrl = TextEditingController();

  final TextEditingController _mobileCtrl = TextEditingController();

  final TextEditingController _dobCtrl = TextEditingController();

  final TextEditingController _aadharCtrl = TextEditingController();

  final TextEditingController _addressCtrl = TextEditingController();

  bool _sosActive = false;
  String _sosPatientId = "";

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await _fetchSOSStatus();

    final patientUsername = await SessionManager.getPatientUsername();

    if (patientUsername != null) {
      _patientUsername = patientUsername;

      await _fetchPatientProfile();
    }
  }

  Future<void> _fetchPatientProfile() async {
    try {
      final profile = await ApiService.getCaregiverPatientProfile(
        _patientUsername,
      );

      setState(() {
        _profileName = profile['name'] ?? '';
        _profilePatientId = profile['patientId'] ?? '';

        _profilePicUrl = profile['profilePicUrl'] ?? '';

        _nameCtrl.text = profile['name'] ?? '';

        _mobileCtrl.text = profile['mobile'] ?? '';

        _dobCtrl.text = profile['dob'] ?? '';

        _aadharCtrl.text = profile['aadhar'] ?? '';

        _addressCtrl.text = profile['address'] ?? '';

        _isLoadingProfile = false;
      });
    } catch (e) {
      print("Profile Fetch Error: $e");

      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _saveProfileDetails() async {
    try {
      await ApiService.updateCaregiverPatientProfile(_patientUsername, {
        "name": _nameCtrl.text,
        "mobile": _mobileCtrl.text,
        "dob": _dobCtrl.text,
        "aadhar": _aadharCtrl.text,
        "address": _addressCtrl.text,
      });

      setState(() {
        _profileName = _nameCtrl.text;
        _isEditingDetails = false;
      });

      await _fetchPatientProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile Updated"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Update failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([_fetchPatientProfile(), _fetchSOSStatus()]);

    if (mounted) {
      setState(() {});
    }
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
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: primaryBlue.withOpacity(0.1),

                    backgroundImage: _profilePicUrl.isNotEmpty
                        ? NetworkImage(_profilePicUrl)
                        : const AssetImage("assets/profile.jpg")
                              as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Caregiver of",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Text(
                          _profileName,
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
                      if (_sosActive) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Emergency Alert"),
                            content: const Text(
                              "Patient has triggered an SOS alert.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Close"),
                              ),

                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);

                                  await ApiService.resetSOS();

                                  await _fetchSOSStatus();
                                },
                                child: const Text(
                                  "Mark as Seen",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        await _fetchSOSStatus();
                      }
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
              const SizedBox(height: 25),

              _isLoadingProfile
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDetailedProfileCard(),
            ],
          ),
        ),
      ),

      /// 🔹 FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotesModuleScreen()),
          );

          if (result == true) {
            await _loadDashboardData();
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
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
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CaregiverLocationScreen(),
                    ),
                  );

                  if (result == true) {
                    await _loadDashboardData();
                  }
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

  Widget _buildDetailedProfileCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Patient Details",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              Text(
                "ID: $_profilePatientId",
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              if (_isEditingDetails) {
                _saveProfileDetails();
              } else {
                setState(() {
                  _isEditingDetails = true;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isEditingDetails ? "Save" : "Edit",
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _infoRow("Name", _nameCtrl),
          _infoRow("Mobile", _mobileCtrl),
          _infoRow("DOB", _dobCtrl),
          _infoRow("Aadhar", _aadharCtrl),
          _infoRow("Address", _addressCtrl, maxLines: 3),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(color: Colors.black54),
            ),
          ),

          Expanded(
            child: _isEditingDetails
                ? TextField(controller: ctrl, maxLines: maxLines)
                : Text(
                    ctrl.text,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }
}
