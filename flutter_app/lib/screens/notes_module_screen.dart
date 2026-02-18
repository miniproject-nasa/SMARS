import 'package:flutter/material.dart';

class NotesModuleScreen extends StatefulWidget {
  const NotesModuleScreen({super.key});

  @override
  State<NotesModuleScreen> createState() => _NotesModuleScreenState();
}

class _NotesModuleScreenState extends State<NotesModuleScreen> {
  int selectedTab = 0;

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  final tabs = ["Notes", "Photos", "Tasks"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [

              /// 🔹 BACK BUTTON
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// 🔹 TAB BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  bool active = selectedTab == index;
                  return GestureDetector(
                    onTap: () => setState(() => selectedTab = index),
                    child: Container(
                      width: 100,
                      height: 90,
                      decoration: BoxDecoration(
                        color: active ? primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryBlue),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            index == 0
                                ? Icons.edit_note
                                : index == 1
                                    ? Icons.camera_alt
                                    : Icons.checklist,
                            color: active ? Colors.white : primaryBlue,
                            size: 30,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tabs[index],
                            style: TextStyle(
                                color: active ? Colors.white : primaryBlue,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              /// 🔹 SEARCH BAR
              TextField(
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 CONTENT AREA
              Expanded(
                child: selectedTab == 0
                    ? _notesView()
                    : selectedTab == 1
                        ? _photosView()
                        : _tasksView(),
              ),
            ],
          ),
        ),
      ),

      /// 🔹 ADD BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// ============================
  /// NOTES VIEW
  /// ============================
  Widget _notesView() {
    return ListView(
      children: [
        _noteCard(
          "02 Jan 2025",
          "Today was a calm & pleasant day. I woke up feeling refreshed and enjoyed a warm cup of tea...",
        ),
        _noteCard(
          "01 Jan 2025",
          "It’s too bored to woke up today because I don’t have anything to do...",
        ),
      ],
    );
  }

  Widget _noteCard(String date, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }

  /// ============================
  /// PHOTOS VIEW
  /// ============================
  Widget _photosView() {
    final names = ["Rahul", "Aswin", "Raziq"];

    return GridView.builder(
      itemCount: names.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        return Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage("assets/profile.png"),
            ),
            const SizedBox(height: 6),
            Text(names[i])
          ],
        );
      },
    );
  }

  /// ============================
  /// TASKS VIEW
  /// ============================
  Widget _tasksView() {
    final tasks = [
      "Visit Neighbour",
      "Passport office",
      "Morning Yoga",
      "Morning Medicines",
      "Call Son",
      "Wash Clothes"
    ];

    return ListView(
      children: tasks
          .map((t) => CheckboxListTile(
                value: false,
                onChanged: (_) {},
                title: Text(t),
              ))
          .toList(),
    );
  }
}
