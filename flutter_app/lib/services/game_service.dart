import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameService {
  static const String baseUrl = "http://172.16.7.36:5000/api/games";

  // 🟢 GET AUTH HEADERS
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 🟢 START GAME SESSION
  static Future<String> startGameSession(
    String gameType, {
    String difficulty = "easy",
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/start"),
        headers: headers,
        body: jsonEncode({"gameType": gameType, "difficulty": difficulty}),
      );

      if (response.statusCode != 201) {
        throw Exception(response.body);
      }

      final data = jsonDecode(response.body);
      return data["sessionId"];
    } catch (e) {
      throw Exception("Failed to start game: $e");
    }
  }

  // 🟢 END GAME SESSION (SAVE SCORE & STATS)
  static Future<Map<String, dynamic>> endGameSession({
    required String sessionId,
    required int score,
    required int level,
    required bool completed,
    required int mistakes,
    required int duration,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/end"),
        headers: headers,
        body: jsonEncode({
          "sessionId": sessionId,
          "score": score,
          "level": level,
          "completed": completed,
          "mistakes": mistakes,
          "duration": duration,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Failed to save game: $e");
    }
  }

  // 🟢 GET DAILY GAME TIME REMAINING
  static Future<Map<String, dynamic>> getDailyGameTime() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/daily-time"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Failed to get daily time: $e");
    }
  }

  // 🟢 GET GAME STATISTICS
  static Future<Map<String, dynamic>> getGameStats({String? gameType}) async {
    try {
      final headers = await _getHeaders();
      String url = "$baseUrl/stats";
      if (gameType != null) {
        url += "?gameType=$gameType";
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Failed to get stats: $e");
    }
  }

  // 🟢 GET USER SETTINGS
  static Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("http://172.16.7.36:5000/api/settings"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Failed to get settings: $e");
    }
  }

  // 🟢 UPDATE USER SETTINGS (Daily Limit)
  static Future<Map<String, dynamic>> updateUserSettings({
    required int dailyGameLimit,
    bool? enableNotifications,
    String? difficultySetting,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse("http://172.16.7.36:5000/api/settings"),
        headers: headers,
        body: jsonEncode({
          "dailyGameLimit": dailyGameLimit,
          if (enableNotifications != null)
            "enableNotifications": enableNotifications,
          if (difficultySetting != null) "difficultySetting": difficultySetting,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Failed to update settings: $e");
    }
  }

  // 🟢 GET USER ACHIEVEMENTS
  static Future<Map<String, dynamic>> getUserAchievements() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("http://172.16.7.36:5000/api/settings/achievements"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Failed to get achievements: $e");
    }
  }
}
