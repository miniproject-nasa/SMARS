import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'login_screen.dart';
import 'package:smars/utils/session_manager.dart';
import 'dart:async';

Timer? refreshTimer;

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  bool isLoading = true;
  bool sosActive = false;
  String patientId = '';
  String timestamp = '';
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    fetchSOS();
    refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetchSOS(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchSOS() async {
    final data = await ApiService.getSOSStatus();
    final locationData = await ApiService.getLocation();

    setState(() {
      sosActive = data['active'];
      patientId = data['patientId'] ?? '';
      timestamp = data['timestamp'] ?? '';
      latitude = locationData['latitude'];
      longitude = locationData['longitude'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMARS – Caregiver'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Caregiver Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // 🚨 SOS STATUS CARD
                  Card(
                    color: sosActive
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    child: ListTile(
                      leading: Icon(
                        sosActive ? Icons.warning : Icons.check_circle,
                        color: sosActive ? Colors.red : Colors.green,
                      ),
                      title: Text(
                        sosActive ? '🚨 SOS ACTIVE' : 'No SOS',
                        style: const TextStyle(fontSize: 18),
                      ),
                      subtitle: sosActive
                          ? Text('Patient: $patientId\nTime: $timestamp')
                          : const Text('All is normal'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🗺️ LIVE LOCATION MAP (OpenStreetMap)
                  const Text(
                    'Live Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 250,
                    child: latitude == null || longitude == null
                        ? const Center(child: Text('No location data'))
                        : FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(latitude!, longitude!),
                              initialZoom: 15,
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
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: fetchSOS,
                    child: const Text('Refresh Status'),
                  ),

                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await SessionManager.clearSession();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
