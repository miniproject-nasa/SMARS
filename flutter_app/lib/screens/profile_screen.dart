import 'package:flutter/material.dart';
import '../utils/session_manager.dart';
import 'splash_decider_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  // 🔹 STATE DATA
  String _name = "Ashiq Kareem";
  final String _patientId = "ASQKRM79"; 
  String _mobile = "9745215821";
  String _dob = "26/08/1999";
  String _aadhar = "967081948207";
  String _address = "Parambil (H.O), Vattoli Bazar (P.O), Thamarassery, Kozhikode";

  // 🔹 CONTROLLERS
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _aadharCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameCtrl = TextEditingController(text: _name);
    _mobileCtrl = TextEditingController(text: _mobile);
    _dobCtrl = TextEditingController(text: _dob);
    _aadharCtrl = TextEditingController(text: _aadhar);
    _addressCtrl = TextEditingController(text: _address);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _dobCtrl.dispose();
    _aadharCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // SAVE DATA
        _name = _nameCtrl.text;
        _mobile = _mobileCtrl.text;
        _dob = _dobCtrl.text;
        _aadhar = _aadharCtrl.text;
        _address = _addressCtrl.text;
      }
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: ProfileScreen.primaryBlue,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _toggleEdit,
            child: Text(
              _isEditing ? "Save" : "Edit",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 🔹 PROFILE PHOTO
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/profile.png"),
                ),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: ProfileScreen.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔹 NAME
            if (_isEditing)
              TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ProfileScreen.primaryBlue),
                decoration: const InputDecoration(border: InputBorder.none, hintText: "Full Name"),
              )
            else
              Text(
                _name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ProfileScreen.primaryBlue),
              ),

            const SizedBox(height: 6),
            Text("Patient ID: $_patientId", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 30),

            /// 🔹 INFO CARDS
            _buildEditableTile("Mobile", _mobile, _mobileCtrl, TextInputType.phone),
            _buildEditableTile("Date of Birth", _dob, _dobCtrl, TextInputType.datetime),
            _buildEditableTile("Aadhar", _aadhar, _aadharCtrl, TextInputType.number),
            _buildEditableTile("Address", _address, _addressCtrl, TextInputType.streetAddress, maxLines: 3),

            const SizedBox(height: 40),

            /// 🔹 LOGOUT BUTTON
            if (!_isEditing) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    await SessionManager.clearSession();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashDeciderScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ]
          ],
        ),
      ),
    );
  }

  /// 🔹 DYNAMIC INFO TILE
  Widget _buildEditableTile(String title, String value, TextEditingController controller, TextInputType keyboardType, {int maxLines = 1}) {
    return Container(
      width: double.infinity, // 🔴 FIX: This forces the box to full width always
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        // 🔴 FIX: Keep shadow in both modes so it doesn't look flat when viewing
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        // Only show border when editing
        border: _isEditing ? Border.all(color: ProfileScreen.primaryBlue, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey
            ),
          ),
          const SizedBox(height: 8),
          _isEditing
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  minLines: 1,
                  style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
        ],
      ),
    );
  }
}