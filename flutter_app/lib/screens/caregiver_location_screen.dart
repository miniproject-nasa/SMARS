import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/session_manager.dart';
import 'caregiver_login_screen.dart';
import '../services/api_service.dart';
import 'notes_module_screen.dart';
import 'caregiver_dashboard.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CaregiverLocationScreen extends StatefulWidget {
  const CaregiverLocationScreen({super.key});

  @override
  State<CaregiverLocationScreen> createState() =>
      _CaregiverLocationScreenState();
}

class _CaregiverLocationScreenState extends State<CaregiverLocationScreen> {
  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  double? latitude;
  double? longitude;

  String _profileName = "";
  String _profilePatientId = "";
  String _profilePicUrl = "";

  String _patientUsername = "";

  bool loading = true;

  Future<void> fetchLocation() async {
    try {
      final data = await ApiService.getLocation();

      setState(() {
        latitude = (data['latitude'] as num).toDouble();
        longitude = (data['longitude'] as num).toDouble();
        loading = false;
      });

      print("Patient Latitude: $latitude");
      print("Patient Longitude: $longitude");
    } catch (e) {
      print("Location Fetch Error: $e");

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _copyCoordinates() async {
    if (latitude == null || longitude == null) return;

    final coords =
        '${latitude!.toStringAsFixed(6)}, '
        '${longitude!.toStringAsFixed(6)}';

    await Clipboard.setData(ClipboardData(text: coords));

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Coordinates copied")));
    }
  }

  Future<void> _openInMaps() async {
    if (latitude == null || longitude == null) {
      return;
    }

    try {
      final Uri mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query='
        '$latitude,$longitude',
      );

      final launched = await launchUrl(
        mapUri,

        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Could not open maps")));
        }
      }
    } catch (e) {
      print("Map Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Map error: $e")));
      }
    }
  }

  Future<void> fetchPatientProfile() async {
    try {
      final profile = await ApiService.getProfile();

      setState(() {
        _profileName = profile["fullName"] ?? profile["name"] ?? "";

        _profilePatientId = profile["patientId"] ?? "";

        _profilePicUrl = profile["profilePicUrl"] ?? "";
      });

      //print("PROFILE: $profile");
    } catch (e) {
      print("Profile Fetch Error: $e");
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
  void initState() {
    super.initState();
    fetchLocation();
    fetchPatientProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 HEADER (same style as dashboards)
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

              /// 🔹 MAP CARD
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),

                    child: (loading || latitude == null || longitude == null)
                        ? const Center(child: CircularProgressIndicator())
                        : FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(latitude!, longitude!),
                              initialZoom: 11,
                            ),

                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.smars',
                              ),

                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(latitude!, longitude!),
                                    width: 40,
                                    height: 30,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: primaryBlue,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 8,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Patient Location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Latitude: "
                      "${latitude?.toStringAsFixed(6) ?? '--'}",
                    ),

                    Text(
                      "Longitude: "
                      "${longitude?.toStringAsFixed(6) ?? '--'}",
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _copyCoordinates,
                            icon: const Icon(Icons.copy),
                            label: const Text("Copy"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _openInMaps,
                            icon: const Icon(Icons.map),
                            label: const Text("Open Maps"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 18),

              // /// 🔹 LOCATE BUTTON
              // SizedBox(
              //   width: double.infinity,
              //   height: 56,
              //   child: ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: primaryBlue,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(14),
              //       ),
              //     ),
              //     onPressed: fetchLocation,
              //     child: const Text(
              //       "Locate",
              //       style: TextStyle(
              //         fontSize: 18,
              //         fontWeight: FontWeight.w600,
              //         color: Colors.white,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),

      /// 🔹 FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotesModuleScreen()),
          );
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
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CaregiverDashboard(),
                    ),
                  );
                },
                child: _navIcon(Icons.home_outlined, "Home"),
              ),

              const SizedBox(width: 40),

              _navIcon(Icons.location_on, "Location"),
            ],
          ),
        ),
      ),
    );
  }

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
}
