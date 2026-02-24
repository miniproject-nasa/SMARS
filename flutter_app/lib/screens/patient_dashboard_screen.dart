import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'notes_module_screen.dart';
import 'chatbot_screen.dart';
import 'patient_home_screen.dart';
import 'profile_screen.dart';
import 'games_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  static const primaryBlue = Color(0xFF3B5998); 
  
  late List<DateTime> _calendarDates;
  late DateTime _selectedDate;

  bool _isEditingDetails = false;
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _aadharCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  List<dynamic> _tasks = [];
  bool _isLoadingTasks = true;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _setupCalendar();
    _fetchProfileData();
    _fetchTasksForSelectedDate();
  }

  void _setupCalendar() {
    DateTime today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _calendarDates = List.generate(24, (index) {
      return _selectedDate.subtract(const Duration(days: 3)).add(Duration(days: index));
    });
  }

  Future<void> _fetchProfileData() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() {
        _mobileCtrl.text = profile['mobile'] ?? "";
        _dobCtrl.text = profile['dob'] ?? "";
        _aadharCtrl.text = profile['aadhar'] ?? "";
        _addressCtrl.text = profile['address'] ?? "";
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _fetchTasksForSelectedDate() async {
    setState(() => _isLoadingTasks = true);
    try {
      final tasks = await ApiService.getTasks(_selectedDate);
      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _saveProfileDetails() async {
    setState(() => _isEditingDetails = false);
    await ApiService.updateProfile({
      "mobile": _mobileCtrl.text,
      "dob": _dobCtrl.text,
      "aadhar": _aadharCtrl.text,
      "address": _addressCtrl.text,
    });
  }

  Future<void> _toggleTaskStatus(int index) async {
    final task = _tasks[index];
    setState(() => _tasks[index]['done'] = !_tasks[index]['done']); 
    try {
      await ApiService.toggleTask(task['_id']);
    } catch (e) {
      setState(() => _tasks[index]['done'] = !_tasks[index]['done']); 
    }
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _dobCtrl.dispose();
    _aadharCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  double get taskProgress {
    if (_tasks.isEmpty) return 0;
    int doneCount = _tasks.where((t) => t['done'] == true).length;
    return doneCount / _tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 25),
              _isLoadingProfile 
                ? const Center(child: CircularProgressIndicator()) 
                : _buildDetailedProfileCard(),
              const SizedBox(height: 25),
              const Text("Your Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildInteractiveDateStrip(),
              const SizedBox(height: 25),
              _buildTaskAndActionLayout(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primaryBlue.withOpacity(0.1),
            backgroundImage: const AssetImage("assets/profile.png"),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("You are", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
              Text("Ashiq Kareem", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryBlue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Progress", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              Text("${(taskProgress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: taskProgress,
            backgroundColor: Colors.grey.shade100,
            color: primaryBlue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Patient Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              GestureDetector(
                onTap: () {
                  if (_isEditingDetails) {
                    _saveProfileDetails();
                  } else {
                    setState(() => _isEditingDetails = true);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isEditingDetails ? Colors.green.withOpacity(0.1) : primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(_isEditingDetails ? Icons.check : Icons.edit, size: 14, color: _isEditingDetails ? Colors.green : primaryBlue),
                      const SizedBox(width: 4),
                      Text(_isEditingDetails ? "Save" : "Edit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isEditingDetails ? Colors.green : primaryBlue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoDetailRow("Name:", "Ashiq Kareem"), 
          _infoDetailRow("Mobile:", _mobileCtrl.text, ctrl: _mobileCtrl),
          _infoDetailRow("Dob:", _dobCtrl.text, ctrl: _dobCtrl),
          _infoDetailRow("Aadhar:", _aadharCtrl.text, ctrl: _aadharCtrl),
          _infoDetailRow("Address:", _addressCtrl.text, ctrl: _addressCtrl, maxLines: 3),
        ],
      ),
    );
  }

  Widget _infoDetailRow(String label, String value, {TextEditingController? ctrl, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70, 
            child: Padding(
              padding: EdgeInsets.only(top: _isEditingDetails && ctrl != null ? 8.0 : 0),
              child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            )
          ),
          Expanded(
            child: _isEditingDetails && ctrl != null
                ? TextField(
                    controller: ctrl,
                    maxLines: maxLines,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  )
                : Text(ctrl?.text ?? value, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveDateStrip() {
    const days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _calendarDates.length,
        itemBuilder: (context, index) {
          DateTime date = _calendarDates[index];
          bool active = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _fetchTasksForSelectedDate();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: active ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: active ? primaryBlue : Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(days[date.weekday - 1], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white70 : Colors.black54)),
                  Text(date.day.toString().padLeft(2, '0'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: active ? Colors.white : Colors.black87)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskAndActionLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Todays Tasks", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                if (_isLoadingTasks) const Center(child: CircularProgressIndicator()),
                if (!_isLoadingTasks && _tasks.isEmpty) const Text("No tasks for today", style: TextStyle(color: Colors.grey)),
                if (!_isLoadingTasks) 
                  ...List.generate(_tasks.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24, width: 24,
                            child: Checkbox(
                              value: _tasks[index]['done'] ?? false,
                              onChanged: (v) => _toggleTaskStatus(index),
                              activeColor: primaryBlue,
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tasks[index]['title'],
                              style: TextStyle(
                                fontSize: 12,
                                color: _tasks[index]['done'] == true ? Colors.grey : Colors.black87,
                                decoration: _tasks[index]['done'] == true ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _actionTile("Take Todays\nNote", Icons.receipt_long, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesModuleScreen()))),
              const SizedBox(height: 12),
              _actionTile("Summarize\nRaaziq", Icons.edit_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()))),
              const SizedBox(height: 12),
              _gameActionTile("Daily game\ntime left", "14", "MIN", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionTile(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _gameActionTile(String text, String val, String unit, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            Column(
              children: [
                Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text(unit, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: primaryBlue, elevation: 4, shape: const CircleBorder(),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesModuleScreen())),
      child: const Icon(Icons.add, color: Colors.white, size: 30),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: Colors.white, notchMargin: 8, padding: EdgeInsets.zero, shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(Icons.home_filled, "Home", true, () {}),
            _navIcon(Icons.forum_outlined, "Chatbot", false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()))),
            const SizedBox(width: 40),
            _navIcon(Icons.warning_amber_rounded, "Alert", false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHomeScreen()))),
            _navIcon(Icons.psychology_outlined, "Games", false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? primaryBlue : Colors.black54, size: 22),
          Text(text, style: TextStyle(color: active ? primaryBlue : Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}