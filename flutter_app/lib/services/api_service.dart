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

  // 📱 Send OTP for patient signup (mobile required)
  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/auth/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to send OTP');
    }
    return jsonDecode(response.body);
  }

  // 👤 Patient Registration (Sign Up: fullName, dateOfBirth, mobile, otp, password)
  static Future<void> registerPatientSignup({
    required String fullName,
    required String dateOfBirth,
    required String mobile,
    required String otp,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/auth/register/patient'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'mobile': mobile,
        'otp': otp,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Registration failed');
    }
  }

  // 👩‍⚕️ Caregiver Registration (username, password, dateOfBirth, patientToken, mobile, otp)
  static Future<void> registerCaregiverSignup({
    required String username,
    required String password,
    required String dateOfBirth,
    required String patientToken,
    required String mobile,
    required String otp,
  }) async {
    final Map<String, String> payload = {
      'username': username,
      'password': password,
      'dateOfBirth': dateOfBirth,
      'patientToken': patientToken,
      'mobile': mobile,
      'otp': otp,
    };
    final bodyString = jsonEncode(payload);
    final request = http.Request(
      'POST',
      Uri.parse('${AppConfig.backendBaseUrl}/api/auth/register/caregiver'),
    );
    request.headers['Content-Type'] = 'application/json; charset=utf-8';
    request.headers['Accept'] = 'application/json';
    request.bodyBytes = utf8.encode(bodyString);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Caregiver registration failed');
    }
  }
}
