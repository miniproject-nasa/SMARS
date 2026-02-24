import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyUsername = 'username';
  static const String _keyRole = 'role';
  static const String _keyPatientUsername = 'patientUsername';
  static const String _keyMobile = 'mobile';

  // Save patient session (persistent)
  static Future<void> savePatientSession({
    required String userId,
    required String username,
    required String mobile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, 'patient');
    await prefs.setString(_keyMobile, mobile);
  }

  // Save caregiver session
  static Future<void> saveCaregiverSession({
    required String userId,
    required String username,
    required String patientUsername,
    required String mobile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, 'caregiver');
    await prefs.setString(_keyPatientUsername, patientUsername);
    await prefs.setString(_keyMobile, mobile);
  }

  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;

    if (!loggedIn) return {};

    return {
      'userId': prefs.getString(_keyUserId),
      'username': prefs.getString(_keyUsername),
      'role': prefs.getString(_keyRole),
      'patientUsername': prefs.getString(_keyPatientUsername),
      'mobile': prefs.getString(_keyMobile),
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyPatientUsername);
    await prefs.remove(_keyMobile);
  }
}
