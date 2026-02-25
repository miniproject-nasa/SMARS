import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'dart:typed_data';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Exposed for widgets that need auth headers (e.g., chatbot).
  // Public (no leading underscore) so it can be used from other files.
  static Future<Map<String, String>> getAuthHeaders() async {
    return _getHeaders();
  }

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

  static Future<Map<String, dynamic>> getSOSStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/api/sos/status'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch SOS status');
    } catch (e) {
      throw Exception('Unable to fetch SOS status');
    }
  }

  static Future<Map<String, dynamic>> getLocation() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/api/sos/location'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch location');
    } catch (e) {
      throw Exception('Unable to fetch location');
    }
  }

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
      if (response.statusCode == 200) return jsonDecode(response.body);
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Login failed');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

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

  static Future<void> registerPatientSignup({
    required String fullName,
    required String dateOfBirth,
    required String mobile,
    required String otp,
    required String password,
    String? address,
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
        'address': address ?? '',
      }),
    );
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Registration failed');
    }
  }

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
    final request = http.Request(
      'POST',
      Uri.parse('${AppConfig.backendBaseUrl}/api/auth/register/caregiver'),
    );
    request.headers['Content-Type'] = 'application/json; charset=utf-8';
    request.headers['Accept'] = 'application/json';
    request.bodyBytes = utf8.encode(jsonEncode(payload));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Caregiver registration failed');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/api/profile'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    print("BACKEND ERROR (Profile): ${response.body}");
    throw Exception('Failed to load profile');
  }

  // 🟢 FIXED: Upload profile picture with profile data - Fixed multipart encoding
  static Future<void> updateProfileWithPicture(
    Map<String, dynamic> data, {
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/profile');
      final request = http.MultipartRequest('PUT', uri);

      // Add authentication headers
      final headers = await _getHeaders();
      headers.forEach((key, value) {
        request.headers[key] = value;
      });

      // Add all text fields - make sure field names match backend expectations
      request.fields['name'] = data['name']?.toString() ?? '';
      request.fields['mobile'] = data['mobile']?.toString() ?? '';
      request.fields['dob'] = data['dob']?.toString() ?? '';
      request.fields['address'] = data['address']?.toString() ?? '';
      request.fields['aadhar'] = data['aadhar']?.toString() ?? '';

      // Add profile picture file if provided
      if (imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'profilePic',
            imageBytes,
            filename: imageFileName ?? 'profile_photo.jpg',
          ),
        );
      }

      print(
        '📤 Sending profile update with ${imageBytes != null ? 'image' : 'no image'}',
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('✓ Response status: ${response.statusCode}');
      print('✓ Response body: ${response.body}');

      if (response.statusCode != 200) {
        print("BACKEND ERROR (Update Profile): ${response.body}");
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error updating profile: $e");
      throw Exception('Error updating profile: $e');
    }
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final updatePayload = {
        'name': data['name'] ?? '',
        'mobile': data['mobile'] ?? '',
        'dob': data['dob'] ?? '',
        'address': data['address'] ?? '',
        'aadhar': data['aadhar'] ?? '',
      };

      final response = await http.put(
        Uri.parse('${AppConfig.backendBaseUrl}/api/profile'),
        headers: await _getHeaders(),
        body: jsonEncode(updatePayload),
      );

      if (response.statusCode != 200) {
        print("BACKEND ERROR (Update Profile): ${response.body}");
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print("Error updating profile: $e");
      throw Exception('Error updating profile: $e');
    }
  }

  static Future<List<dynamic>> getTasks(DateTime date) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.backendBaseUrl}/api/tasks?date=${date.toIso8601String()}',
      ),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    print("BACKEND ERROR (Tasks): ${response.body}");
    throw Exception('Failed to load tasks');
  }

  static Future<List<dynamic>> getAllTasks() async {
    final response = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/api/tasks'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    print("BACKEND ERROR (All Tasks): ${response.body}");
    throw Exception('Failed to load tasks');
  }

  static Future<void> toggleTask(String id) async {
    final response = await http.put(
      Uri.parse('${AppConfig.backendBaseUrl}/api/tasks/$id/toggle'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      print("BACKEND ERROR (Toggle Task): ${response.body}");
      throw Exception('Failed to toggle task');
    }
  }

  static Future<void> createTask(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/tasks'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      print("BACKEND ERROR (Create Task): ${response.body}");
      throw Exception('Failed to create task');
    }
  }

  // 🟢 NEW: UPDATE TASK
  static Future<void> updateTask(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConfig.backendBaseUrl}/api/tasks/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      print("BACKEND ERROR (Update Task): ${response.body}");
      throw Exception('Failed to update task');
    }
  }

  // 🟢 NEW: DELETE TASK
  static Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.backendBaseUrl}/api/tasks/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      print("BACKEND ERROR (Delete Task): ${response.body}");
      throw Exception('Failed to delete task');
    }
  }

  static Future<List<dynamic>> getNotes() async {
    final response = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/api/notes'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    print("BACKEND ERROR (Get Notes): ${response.body}");
    throw Exception('Failed to load notes');
  }

  static Future<void> createNote(
    String title,
    String content, {
    Uint8List? imageBytes,
    String? filename,
  }) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/notes');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _getHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.fields['title'] = title;
    request.fields['content'] = content;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: filename ?? 'note_image.jpg',
        ),
      );
    }

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 201)
      throw Exception('Failed to create note');
  }

  static Future<void> updateNote(
    String id,
    String title,
    String content, {
    Uint8List? imageBytes,
    String? filename,
  }) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/notes/$id');
    final request = http.MultipartRequest('PUT', uri);
    final headers = await _getHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.fields['title'] = title;
    request.fields['content'] = content;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: filename ?? 'note_image.jpg',
        ),
      );
    }

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200)
      throw Exception('Failed to update note');
  }

  static Future<void> deleteNote(String id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.backendBaseUrl}/api/notes/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete note');
  }

  // ---------------------------
  // 📞 CONTACTS
  // ---------------------------
  static Future<List<dynamic>> getContacts() async {
    final response = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/api/contacts'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    print("BACKEND ERROR (Get Contacts): ${response.body}");
    throw Exception('Failed to load contacts');
  }

  // 🟢 NEW MULTIPART REQUEST FOR CLOUDINARY
  static Future<void> createContact({
    required String name,
    required String relation,
    required String phone,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/contacts');
      final request = http.MultipartRequest('POST', uri);

      // Add Headers
      final headers = await _getHeaders();
      headers.remove(
        'Content-Type',
      ); // MultipartRequest sets its own Content-Type boundary
      request.headers.addAll(headers);

      // Add Text Fields
      request.fields['name'] = name;
      request.fields['relation'] = relation;
      request.fields['phone'] = phone;

      // Add Image File (if selected)
      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo', // This matches 'upload.single("photo")' in Node.js
            imageBytes,
            filename: imageFileName ?? 'contact_photo.jpg',
          ),
        );
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        print("BACKEND ERROR (Create Contact): ${response.body}");
        throw Exception('Failed to create contact');
      }
    } catch (e) {
      throw Exception('Error creating contact: $e');
    }
  }

  // 🟢 NEW: UPDATE CONTACT
  static Future<void> updateContact({
    required String id,
    required String name,
    required String relation,
    required String phone,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/contacts/$id');
      final request = http.MultipartRequest('PUT', uri);

      // Add Headers
      final headers = await _getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Add Text Fields
      request.fields['name'] = name;
      request.fields['relation'] = relation;
      request.fields['phone'] = phone;

      // Add Image File (if selected)
      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            imageBytes,
            filename: imageFileName ?? 'contact_photo.jpg',
          ),
        );
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        print("BACKEND ERROR (Update Contact): ${response.body}");
        throw Exception('Failed to update contact');
      }
    } catch (e) {
      throw Exception('Error updating contact: $e');
    }
  }

  // 🟢 NEW: DELETE CONTACT
  static Future<void> deleteContact(String id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.backendBaseUrl}/api/contacts/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      print("BACKEND ERROR (Delete Contact): ${response.body}");
      throw Exception('Failed to delete contact');
    }
  }
}
