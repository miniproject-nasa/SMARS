import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/game_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _dailyLimitController;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _achievements = {};

  @override
  void initState() {
    super.initState();
    _dailyLimitController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final dailyTimeData = await GameService.getDailyGameTime();
      final settingsData = await GameService.getUserSettings();
      final achievementsData = await GameService.getUserAchievements();

      setState(() {
        _settings = {...dailyTimeData, ...settingsData, ...achievementsData};
        _achievements = achievementsData;
        _dailyLimitController.text =
            (settingsData['dailyGameLimit'] ?? 1800000) ~/ 60000;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load settings: $e";
      });
    }
  }

  Future<void> _saveDailyLimit() async {
    final limitStr = _dailyLimitController.text.trim();

    if (limitStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number")),
      );
      return;
    }

    try {
      final limit = int.parse(limitStr);

      if (limit < 5 || limit > 480) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Daily limit must be between 5 and 480 minutes"),
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      // Call backend to update settings (in milliseconds)
      final response = await GameService.updateUserSettings(
        dailyGameLimit: limit * 60000,
      );

      setState(() {
        _isSaving = false;
        _settings.addAll(response);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Daily limit updated to $limit minutes"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Game Settings"),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Game Settings"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Limit Section
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.deepPurple),
                        const SizedBox(width: 12),
                        const Text(
                          "Daily Game Time Limit",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dailyLimitController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Minutes",
                              hintText: "5 - 480",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.schedule),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveDailyLimit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  "Set",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Current limit: ${(_settings['dailyLimit'] ?? 1800000) ~/ 60000} minutes",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
