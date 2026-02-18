import 'package:flutter/material.dart';
import 'notes_module_screen.dart';
import 'chatbot_screen.dart';
import 'patient_home_screen.dart';
// import 'notes_module_screen.dart';


class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔹 HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage("assets/profile.png"),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("You are",
                          style: TextStyle(fontSize: 14, color: Colors.black54)),
                      Text(
                        "Ashiq Kareem",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 18),

              /// 🔹 INFO CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name:   Ashiq Kareem"),
                    Text("Mobile: 9745215821"),
                    Text("Dob:     26/08/1999"),
                    Text("Aadhar:  967081948207"),
                    Text(
                        "Address: Parambil (H.O), Vattoli Bazar (P.O), Thamarassery, Kozhikode"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 DATE STRIP
              SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: List.generate(6, (index) {
                    bool isSelected = index == 3;
                    final days = ["SUN","MON","TUE","WED","THU","FRI"];
                    final dates = ["27","28","29","30","31","01"];

                    return Container(
                      width: 64,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(days[index],
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : Colors.black54)),
                          Text(dates[index],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isSelected ? Colors.white : Colors.black)),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 TASK + SIDE CARDS
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// LEFT TASK CARD
                  Expanded(
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Todays Tasks",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          ...[
                            "Visit Neighbour",
                            "Passport office",
                            "Morning Yoga",
                            "Morning Medicines",
                            "Call Son",
                            "Wash Clothes"
                          ].map((t) => CheckboxListTile(
                                value: false,
                                onChanged: (_) {},
                                title: Text(t),
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ))
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// RIGHT SIDE CARDS
                  Column(
                    children: [
                      _smallCard("Take Todays Note", Icons.calendar_today),
                      const SizedBox(height: 12),
                      _smallCard("Summarize Raziq", Icons.edit),
                      const SizedBox(height: 12),
                      _smallCard("14 MIN\nDaily game time left", Icons.timer),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),

      /// 🔹 BOTTOM NAV
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
          onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotesModuleScreen()),
    );
  },
  child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [

  /// HOME (do nothing)
  _navIcon(Icons.home, "Home"),

  /// CHATBOT
  GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
      );
    },
    child: _navIcon(Icons.chat_bubble_outline, "Chatbot"),
  ),

  const SizedBox(width: 40),

  /// ALERT
  GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
      );
    },
    child: _navIcon(Icons.warning_amber_outlined, "Alert"),
  ),

  /// GAMES (empty for now)
  _navIcon(Icons.psychology_outlined, "Games"),
],

          ),
        ),
      ),
    );
  }

  /// 🔹 WIDGETS

  static Widget _navIcon(IconData icon, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: primaryBlue),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: primaryBlue))
      ],
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  static Widget _smallCard(String text, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryBlue),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
