import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import '../utils/session_manager.dart';
import '../services/api_service.dart';
import 'splash_decider_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes; // 🟢 ADDED: For web compatibility

  // 🔹 STATE DATA
  String _name = "";
  String _patientId = "";
  String _mobile = "";
  String _dob = "";
  String _aadhar = "";
  String _address = "";
  String _profilePicUrl = "";

  // 🔹 CONTROLLERS
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _aadharCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // 🟢 NEW: Load profile from database
  Future<void> _loadProfile() async {
    try {
      final profileData = await ApiService.getProfile();
      setState(() {
        _name = profileData['name'] ?? 'Patient Name';
        _patientId = profileData['patientId'] ?? '';
        _mobile = profileData['mobile'] ?? '';
        _dob = profileData['dob'] ?? '';
        _aadhar = profileData['aadhar'] ?? '';
        _address = profileData['address'] ?? '';
        _profilePicUrl = profileData['profilePicUrl'] ?? '';
        _initializeControllers();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
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

  // 🟢 NEW: Pick image from gallery or camera (web compatible)
  void _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 200,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: ProfileScreen.primaryBlue,
              ),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setState(() {
                    _selectedImage = image;
                    _selectedImageBytes =
                        bytes; // 🟢 ADDED: Store bytes for web
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.image,
                color: ProfileScreen.primaryBlue,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setState(() {
                    _selectedImage = image;
                    _selectedImageBytes =
                        bytes; // 🟢 ADDED: Store bytes for web
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEdit() async {
    if (_isEditing) {
      // SAVE DATA
      _saveProfile();
    } else {
      setState(() => _isEditing = !_isEditing);
    }
  }

  // 🟢 NEW: Save profile to backend
  void _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      // Update local state
      _name = _nameCtrl.text;
      _mobile = _mobileCtrl.text;
      _dob = _dobCtrl.text;
      _aadhar = _aadharCtrl.text;
      _address = _addressCtrl.text;

      final profileData = {
        'name': _name,
        'mobile': _mobile,
        'dob': _dob,
        'aadhar': _aadhar,
        'address': _address,
      };

      // Upload with picture if selected
      if (_selectedImageBytes != null) {
        await ApiService.updateProfileWithPicture(
          profileData,
          imageBytes: _selectedImageBytes,
          imageFileName: _selectedImage?.name ?? 'profile_photo.jpg',
        );
        _selectedImage = null;
        _selectedImageBytes = null;
        // Reload profile to get updated picture URL
        await _loadProfile();
      } else {
        await ApiService.updateProfile(profileData);
      }

      setState(() {
        _isEditing = !_isEditing;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: ProfileScreen.primaryBlue,
          title: const Text("Profile", style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: ProfileScreen.primaryBlue,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _toggleEdit,
            child: Text(
              _isEditing ? (_isSaving ? "Saving..." : "Save") : "Edit",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
                // 🟢 UPDATED: Use Uint8List for web compatibility
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _selectedImageBytes != null
                      ? MemoryImage(_selectedImageBytes!)
                      : (_profilePicUrl.isNotEmpty
                                ? NetworkImage(_profilePicUrl)
                                : const AssetImage("assets/profile.png"))
                            as ImageProvider,
                ),
                if (_isEditing)
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: ProfileScreen.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔹 NAME
            if (_isEditing)
              TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ProfileScreen.primaryBlue,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Full Name",
                ),
              )
            else
              Text(
                _name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ProfileScreen.primaryBlue,
                ),
              ),

            const SizedBox(height: 6),
            // 🟢 UPDATED: Display patient ID from database
            Text(
              "Patient ID: $_patientId",
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),

            /// 🔹 INFO CARDS
            _buildEditableTile(
              "Mobile",
              _mobile,
              _mobileCtrl,
              TextInputType.phone,
            ),
            _buildEditableTile(
              "Date of Birth",
              _dob,
              _dobCtrl,
              TextInputType.datetime,
            ),
            _buildEditableTile(
              "Aadhar",
              _aadhar,
              _aadharCtrl,
              TextInputType.number,
            ),
            _buildEditableTile(
              "Address",
              _address,
              _addressCtrl,
              TextInputType.streetAddress,
              maxLines: 3,
            ),

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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Logout",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await SessionManager.clearSession();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SplashDeciderScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  /// 🔹 DYNAMIC INFO TILE
  Widget _buildEditableTile(
    String title,
    String value,
    TextEditingController controller,
    TextInputType keyboardType, {
    int maxLines = 1,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: _isEditing
            ? Border.all(color: ProfileScreen.primaryBlue, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _isEditing
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  minLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ],
      ),
    );
  }
}
