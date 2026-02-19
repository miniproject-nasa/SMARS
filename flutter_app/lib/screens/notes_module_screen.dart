import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: NotesModuleScreen(),
  ));
}

class NotesModuleScreen extends StatefulWidget {
  const NotesModuleScreen({super.key});

  @override
  State<NotesModuleScreen> createState() => _NotesModuleScreenState();
}

class _NotesModuleScreenState extends State<NotesModuleScreen> {
  int selectedTab = 0;
  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);
  final tabs = ["Notes", "Photos", "Tasks"];
  
  final TextEditingController _inputController = TextEditingController();

  // 🔹 DATA SOURCE: These lists now drive the UI
  final List<Map<String, String>> _notes = [
    {"date": "02 Feb 2026", "text": "Project brainstorming session went well."},
    {"date": "01 Feb 2026", "text": "Remember to check the new memory game designs."},
  ];

  final List<Map<String, String>> _photos = [
    {"name": "Rahul", "url": "https://i.pravatar.cc/150?u=11"},
    {"name": "Aswin", "url": "https://i.pravatar.cc/150?u=22"},
    {"name": "Raziq", "url": "https://i.pravatar.cc/150?u=33"},
  ];

  final List<Map<String, dynamic>> _tasks = [
    {"title": "Morning Yoga", "done": true},
    {"title": "Passport office", "done": false},
    {"title": "Call Son", "done": false},
  ];

  // 🔹 LOGIC: Adding new data based on current tab
  void _saveNewItem() {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      if (selectedTab == 0) {
        _notes.insert(0, {
          "date": "Today",
          "text": _inputController.text,
        });
      } else if (selectedTab == 1) {
        _photos.add({
          "name": _inputController.text,
          "url": "https://i.pravatar.cc/150?u=${Random().nextInt(100)}",
        });
      } else {
        _tasks.insert(0, {"title": _inputController.text, "done": false});
      }
    });

    _inputController.clear();
    Navigator.pop(context);
  }

  // 🔹 UI: The Dynamic Input Sheet
  void _showEntrySheet() {
    String title = "New ${tabs[selectedTab].substring(0, tabs[selectedTab].length - (selectedTab == 1 ? 1 : 1))}";
    if (selectedTab == 1) title = "Add Contact";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue)),
            const SizedBox(height: 15),
            TextField(
              controller: _inputController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Enter details here...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _saveNewItem,
                child: const Text("Save to Workspace", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabSelector(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  key: ValueKey<int>(selectedTab),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildCurrentView(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        elevation: 6,
        onPressed: _showEntrySheet,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
          const Text("My Workspace", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          bool active = selectedTab == index;
          final icons = [Icons.edit_note, Icons.camera_alt, Icons.checklist];
          return GestureDetector(
            onTap: () => setState(() => selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: MediaQuery.of(context).size.width * 0.28,
              height: 85,
              decoration: BoxDecoration(
                color: active ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [if (active) BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[index], color: active ? Colors.white : primaryBlue, size: 28),
                  const SizedBox(height: 4),
                  Text(tabs[index], style: TextStyle(color: active ? Colors.white : primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search ${tabs[selectedTab]}...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (selectedTab == 0) {
      return ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, i) => _NoteCard(_notes[i]["date"]!, _notes[i]["text"]!),
      );
    } else if (selectedTab == 1) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.8),
        itemCount: _photos.length,
        itemBuilder: (context, i) => Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: NetworkImage(_photos[i]["url"]!), fit: BoxFit.cover),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(_photos[i]["name"]!, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: CheckboxListTile(
            activeColor: primaryBlue,
            title: Text(_tasks[i]["title"], style: TextStyle(decoration: _tasks[i]["done"] ? TextDecoration.lineThrough : null)),
            value: _tasks[i]["done"],
            onChanged: (v) => setState(() => _tasks[i]["done"] = v),
          ),
        ),
      );
    }
  }
}

class _NoteCard extends StatelessWidget {
  final String date, text;
  const _NoteCard(this.date, this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}