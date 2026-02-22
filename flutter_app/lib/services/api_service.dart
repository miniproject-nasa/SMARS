import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  // ---------------------------
  // 🚨 SOS TRIGGER (Patient)
  // ---------------------------
  static Future<bool> triggerSOS() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/sos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patientId': 'PATIENT_001'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------
  // 🚨 GET SOS STATUS (Caregiver)
  // ---------------------------
  static Future<Map<String, dynamic>> getSOSStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/api/sos/status'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch SOS status');
      }
    } catch (e) {
      throw Exception('Unable to fetch SOS status');
    }
  }

  // ---------------------------
  // 📍 GET LOCATION (Caregiver)
  // ---------------------------
  static Future<Map<String, dynamic>> getLocation() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/api/sos/location'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch location');
      }
    } catch (e) {
      throw Exception('Unable to fetch location');
    }
  }

  // ---------------------------
  // 🔐 LOGIN (Patient / Caregiver)
  // ---------------------------
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 👤 Patient Registration (Sign Up page: fullName, dateOfBirth, mobile, otp)
  static Future<void> registerPatientSignup({
    required String fullName,
    required String dateOfBirth,
    required String mobile,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/auth/register/patient'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'mobile': mobile,
        'otp': otp,
      }),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Registration failed');
    }
  }

  // 👩‍⚕️ Caregiver Registration
  static Future<void> registerCaregiver(
    String username,
    String password,
    String patientUsername,
  ) async {
    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/auth/register/caregiver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'patientUsername': patientUsername,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message']);
    }
  }
}
