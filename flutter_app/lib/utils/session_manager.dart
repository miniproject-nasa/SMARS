import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyLoggedIn = 'isLoggedIn';
  static const String _keyUsername = 'username';
  static const String _keyRole = 'role';
  static const String _keyPatientUsername = 'patientUsername';

  // Save patient session (persistent)
  static Future<void> savePatientSession({required String username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, 'patient');
  }

  // Save caregiver session (temporary)
  static Future<void> saveCaregiverSession({
    required String username,
    required String patientUsername,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, 'caregiver');
    await prefs.setString(_keyPatientUsername, patientUsername);
  }

  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;

    if (!loggedIn) return {};

    return {
      'username': prefs.getString(_keyUsername),
      'role': prefs.getString(_keyRole),
      'patientUsername': prefs.getString(_keyPatientUsername),
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyPatientUsername);
  }
}
