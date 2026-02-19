import 'package:flutter/material.dart';
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
  int selectedDateIndex = 3;

  final List<Map<String, dynamic>> _tasks = [
    {"title": "Visit Neighbour", "done": false},
    {"title": "Passport office", "done": false},
    {"title": "Morning Yoga", "done": true},
    {"title": "Morning Medicines", "done": true},
    {"title": "Call Son", "done": false},
    {"title": "Wash Clothes", "done": false},
  ];

  double get taskProgress {
    int doneCount = _tasks.where((t) => t['done']).length;
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
              _buildDetailedProfileCard(),
              const SizedBox(height: 25),
              const Text("Your Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildInteractiveDateStrip(),
              const SizedBox(height: 25),
              _buildTaskAndActionLayout(context),
              const SizedBox(height: 20),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
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
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.push_pin_outlined, color: Colors.grey.shade400, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's Progress", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  Text("${(taskProgress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
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
              const SizedBox(height: 20),
              _infoDetailRow("Name:", "Ashiq Kareem"),
              _infoDetailRow("Mobile:", "9745215821"),
              _infoDetailRow("Dob:", "26/08/1999"),
              _infoDetailRow("Aadhar:", "967081948207"),
              _infoDetailRow("Address:", "Parambil (H.O), Vattoli Bazar (P.O),\nThamarassery, 673617, Kozhikode"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildInteractiveDateStrip() {
    final days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    final dates = ["27", "28", "29", "30", "31", "01", "02"];

    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          bool active = selectedDateIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedDateIndex = index),
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
                  Text(days[index], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white70 : Colors.black54)),
                  Text(dates[index], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: active ? Colors.white : Colors.black87)),
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
                ...List.generate(_tasks.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24, width: 24,
                          child: Checkbox(
                            value: _tasks[index]['done'],
                            onChanged: (v) => setState(() => _tasks[index]['done'] = v),
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
                              decoration: _tasks[index]['done'] ? TextDecoration.lineThrough : null,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
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
      backgroundColor: primaryBlue,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesModuleScreen())),
      child: const Icon(Icons.add, color: Colors.white, size: 30),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      notchMargin: 8,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
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
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? primaryBlue : Colors.black54, size: 22),
          Text(text, style: TextStyle(color: active ? primaryBlue : Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}