import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/session_manager.dart';
import 'caregiver_login_screen.dart';
import '../services/api_service.dart';

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

  bool loading = true;

  Future<void> fetchLocation() async {
    try {
      final data = await ApiService.getLocation();

      setState(() {
        latitude = (data['latitude'] as num).toDouble();
        longitude = (data['longitude'] as num).toDouble();
        loading = false;
      });

      print("Caregiver Latitude: $latitude");
      print("Caregiver Longitude: $longitude");
    } catch (e) {
      print("Location Fetch Error: $e");

      setState(() {
        loading = false;
      });
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
                    icon: const Icon(Icons.logout, color: primaryBlue),
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
                    child: FlutterMap(
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

              const SizedBox(height: 18),

              /// 🔹 LOCATE BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: fetchLocation,
                  child: const Text(
                    "Locate",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      /// 🔹 SAME FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: () {},
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// 🔹 SAME BOTTOM NAV
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(Icons.home_outlined, "Home"),

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
                child: _navIcon(Icons.location_on, "Location"),
              ),
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
