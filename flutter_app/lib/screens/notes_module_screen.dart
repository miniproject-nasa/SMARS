import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:image_picker/image_picker.dart'; 
import '../services/api_service.dart';

class NotesModuleScreen extends StatefulWidget {
  const NotesModuleScreen({super.key});
  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);
  @override State<NotesModuleScreen> createState() => _NotesModuleScreenState();
}

class _NotesModuleScreenState extends State<NotesModuleScreen> {
  int selectedTab = 0;
  final tabs = ["Journal", "People", "Tasks"];

  List<dynamic> _notes = [];
  List<dynamic> _photos = [];
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override void initState() { super.initState(); _fetchData(); }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final notes = await ApiService.getNotes();
      final contacts = await ApiService.getContacts();
      final tasks = await ApiService.getAllTasks();
      setState(() { _notes = notes; _photos = contacts; _tasks = tasks; });
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally { setState(() => _isLoading = false); }
  }

  void _openAddSheet() {
    if (selectedTab == 0) _showNoteSheet();
    else if (selectedTab == 1) _showPhotoSheet();
    else _showTaskSheet();
  }

  void _showNoteSheet({Map<String, dynamic>? existingNote}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => _AddNoteSheet(
        existingNote: existingNote,
        onSave: (title, content, imageBytes, filename) async {
          if (existingNote != null) await ApiService.updateNote(existingNote['_id'], title, content, imageBytes: imageBytes, filename: filename);
          else await ApiService.createNote(title, content, imageBytes: imageBytes, filename: filename);
          _fetchData(); 
        },
      ),
    );
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => _AddPhotoSheet(
        onSave: (name, desc, imageBytes, filename) async {
          await ApiService.createContact(name: name, relation: desc, phone: "N/A", imageBytes: imageBytes, imageFileName: filename);
          _fetchData();
        },
      ),
    );
  }

  void _showTaskSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskSheet(
        onSave: (title, priority, date, recurrence, category) async {
          await ApiService.createTask({
            "title": title, "priority": priority, "date": date.toIso8601String(), 
            "recurrence": recurrence, "category": category, "done": false
          });
          _fetchData();
        },
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(), _buildTabSelector(), const SizedBox(height: 20), _buildSearchBar(), const SizedBox(height: 10),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: NotesModuleScreen.primaryBlue))
                : AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Padding(key: ValueKey<int>(selectedTab), padding: const EdgeInsets.symmetric(horizontal: 18), child: _buildCurrentView())),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: NotesModuleScreen.primaryBlue, elevation: 6, onPressed: _openAddSheet, child: const Icon(Icons.add, color: Colors.white, size: 30)),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        const Text("My Workspace", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          bool active = selectedTab == index;
          final icons = [Icons.book_outlined, Icons.portrait, Icons.checklist_rtl];
          return GestureDetector(
            onTap: () => setState(() => selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), width: MediaQuery.of(context).size.width * 0.28, height: 85,
              decoration: BoxDecoration(color: active ? NotesModuleScreen.primaryBlue : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [if (active) BoxShadow(color: NotesModuleScreen.primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icons[index], color: active ? Colors.white : NotesModuleScreen.primaryBlue, size: 28), const SizedBox(height: 4), Text(tabs[index], style: TextStyle(color: active ? Colors.white : NotesModuleScreen.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13))]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(decoration: InputDecoration(hintText: "Search ${tabs[selectedTab]}...", prefixIcon: const Icon(Icons.search, color: Colors.grey), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
    );
  }

  Widget _buildCurrentView() {
    if (selectedTab == 0) {
      if (_notes.isEmpty) return const Center(child: Text("No entries yet."));
      return ListView.builder(padding: const EdgeInsets.only(bottom: 80, top: 10), itemCount: _notes.length, itemBuilder: (context, i) => _buildNoteCard(i));
    } else if (selectedTab == 1) {
      if (_photos.isEmpty) return const Center(child: Text("No contacts yet."));
      return GridView.builder(padding: const EdgeInsets.only(bottom: 80, top: 10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.85), itemCount: _photos.length, itemBuilder: (context, i) => _buildPhotoCard(i));
    } else {
      if (_tasks.isEmpty) return const Center(child: Text("No tasks yet."));
      return ListView.builder(padding: const EdgeInsets.only(bottom: 80, top: 10), itemCount: _tasks.length, itemBuilder: (context, i) => _buildTaskCard(i));
    }
  }

  // 🟢 APPLE JOURNAL STYLE NOTE CARD
  Widget _buildNoteCard(int index) {
    final note = _notes[index];
    final date = DateTime.parse(note["createdAt"] ?? DateTime.now().toIso8601String()).toLocal();
    final hasImage = note["imageUrl"] != null && note["imageUrl"].isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) 
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(note["imageUrl"], width: double.infinity, height: 200, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('EEEE, dd MMM yyyy').format(date).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.grey, letterSpacing: 1.2)),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, color: Colors.grey),
                      onSelected: (value) async {
                        if (value == 'edit') _showNoteSheet(existingNote: note);
                        else if (value == 'delete') { await ApiService.deleteNote(note['_id']); _fetchData(); }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 10), Text("Edit")])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 10), Text("Delete", style: TextStyle(color: Colors.red))])),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 5),
                Text(note["title"] ?? "Untitled", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                Text(note["content"] ?? "", style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index) {
    final photo = _photos[index];
    final hasCustomPhoto = photo["imageUrl"] != null && photo["imageUrl"].isNotEmpty;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: hasCustomPhoto ? NetworkImage(photo["imageUrl"]) : NetworkImage("https://i.pravatar.cc/150?u=${photo['_id']}"), fit: BoxFit.cover), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.transparent])),
        padding: const EdgeInsets.all(12), alignment: Alignment.bottomLeft,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(photo["name"] ?? "Unknown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 4), Text(photo["relation"] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))]),
      ),
    );
  }

  // 🟢 ADVANCED TASK CARD
  Widget _buildTaskCard(int index) {
    final task = _tasks[index];
    final date = DateTime.parse(task["date"] ?? DateTime.now().toIso8601String()).toLocal();
    final isRecurring = task["recurrence"] != null && task["recurrence"] != "None";
    
    IconData categoryIcon = Icons.check_circle_outline;
    if (task["category"] == "Medication") categoryIcon = Icons.medical_services_outlined;
    if (task["category"] == "Appointment") categoryIcon = Icons.calendar_month_outlined;
    if (task["category"] == "Exercise") categoryIcon = Icons.directions_run;

    Color priorityColor = Colors.green;
    if (task["priority"] == "High") priorityColor = Colors.redAccent;
    if (task["priority"] == "Medium") priorityColor = Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          activeColor: NotesModuleScreen.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          value: task["done"] ?? false,
          onChanged: (v) async {
            setState(() => _tasks[index]["done"] = v); 
            try { await ApiService.toggleTask(task['_id']); } 
            catch (e) { setState(() => _tasks[index]["done"] = !v!); }
          },
        ),
        title: Row(
          children: [
            Icon(categoryIcon, size: 18, color: NotesModuleScreen.primaryBlue),
            const SizedBox(width: 8),
            Expanded(child: Text(task["title"] ?? "Untitled", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, decoration: task["done"] == true ? TextDecoration.lineThrough : null, color: task["done"] == true ? Colors.grey : Colors.black87))),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 26),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]), const SizedBox(width: 4),
              Text(DateFormat('MMM dd').format(date), style: TextStyle(color: Colors.grey[600], fontSize: 13)), 
              if (isRecurring) ...[
                const SizedBox(width: 12),
                Icon(Icons.repeat, size: 14, color: Colors.grey[600]), const SizedBox(width: 4),
                Text(task["recurrence"], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.flag, size: 14, color: priorityColor), const SizedBox(width: 4), Text(task["priority"] ?? "Low", style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.bold))])),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================================
// 🔹 BOTTOM SHEETS 
// ====================================================================================

// 🟢 APPLE JOURNAL STYLE NOTE SHEET
class _AddNoteSheet extends StatefulWidget {
  final Map<String, dynamic>? existingNote;
  final Function(String title, String content, Uint8List? imageBytes, String? filename) onSave; 

  const _AddNoteSheet({this.existingNote, required this.onSave});
  @override State<_AddNoteSheet> createState() => _AddNoteSheetState();
}
class _AddNoteSheetState extends State<_AddNoteSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _existingImageUrl;

  @override void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?["title"] ?? "");
    _contentController = TextEditingController(text: widget.existingNote?["content"] ?? "");
    _existingImageUrl = widget.existingNote?["imageUrl"];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() { _imageBytes = bytes; _imageFileName = pickedFile.name; _existingImageUrl = null; });
    }
  }

  @override Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("New Entry", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NotesModuleScreen.primaryBlue)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: NotesModuleScreen.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: () { 
                if (_titleController.text.trim().isNotEmpty && _contentController.text.trim().isNotEmpty) {
                  widget.onSave(_titleController.text.trim(), _contentController.text.trim(), _imageBytes, _imageFileName); 
                  Navigator.pop(context); 
                }
              },
              child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            )
          ]),
        ),
        const Divider(height: 1),
        
        // Journal Image Display Area
        if (_imageBytes != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty))
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: double.infinity, height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _imageBytes != null ? MemoryImage(_imageBytes!) as ImageProvider : NetworkImage(_existingImageUrl!),
                    fit: BoxFit.cover,
                  )
                ),
              ),
              IconButton(icon: const Icon(Icons.cancel, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 10)]), onPressed: () => setState(() { _imageBytes = null; _existingImageUrl = null; })),
            ],
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(controller: _titleController, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87), decoration: const InputDecoration(hintText: "Title", border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey))),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
        
        Expanded(child: Padding(padding: const EdgeInsets.all(20), child: TextField(controller: _contentController, autofocus: _imageBytes == null, maxLines: null, keyboardType: TextInputType.multiline, decoration: const InputDecoration(hintText: "Start writing...", hintStyle: TextStyle(color: Colors.grey, fontSize: 18), border: InputBorder.none), style: const TextStyle(fontSize: 18, height: 1.6)))),
        
        // Journal Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(color: Colors.grey[50], border: Border(top: BorderSide(color: Colors.grey.shade300))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.format_bold, color: Colors.black54), onPressed: () {}), // Visual mock
              IconButton(icon: const Icon(Icons.format_list_bulleted, color: Colors.black54), onPressed: () {}), // Visual mock
              IconButton(icon: const Icon(Icons.photo_library_outlined, color: NotesModuleScreen.primaryBlue, size: 28), onPressed: _pickImage), // Functional
              IconButton(icon: const Icon(Icons.mic_none, color: Colors.black54), onPressed: () {}), // Visual mock
            ],
          ),
        )
      ]),
    );
  }
}

// 🟢 PHOTO/CONTACT SHEET (UNCHANGED)
class _AddPhotoSheet extends StatefulWidget {
  final Function(String name, String desc, Uint8List? imageBytes, String? filename) onSave; 
  const _AddPhotoSheet({required this.onSave});
  @override State<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}
class _AddPhotoSheetState extends State<_AddPhotoSheet> {
  final _nameController = TextEditingController(); final _descController = TextEditingController();
  Uint8List? _imageBytes; String? _imageFileName;

  Future<void> _pickImage() async {
    final picker = ImagePicker(); final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) { final bytes = await pickedFile.readAsBytes(); setState(() { _imageBytes = bytes; _imageFileName = pickedFile.name; }); }
  }

  @override Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("New Contact Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: NotesModuleScreen.primaryBlue)), const SizedBox(height: 20),
        GestureDetector(onTap: _pickImage, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle, image: _imageBytes != null ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover) : null), child: _imageBytes == null ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey) : null)), const SizedBox(height: 10), const Text("Tap to upload photo", style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 20),
        TextField(controller: _nameController, decoration: InputDecoration(labelText: "Person's Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))), const SizedBox(height: 15),
        TextField(controller: _descController, maxLines: 3, decoration: InputDecoration(labelText: "Short Description / Relationship", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))), const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: NotesModuleScreen.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: () { if (_nameController.text.trim().isNotEmpty) { widget.onSave(_nameController.text.trim(), _descController.text.trim(), _imageBytes, _imageFileName); Navigator.pop(context); } }, child: const Text("Save Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ]),
    );
  }
}

// 🟢 ADVANCED TASK SHEET
class _AddTaskSheet extends StatefulWidget {
  final Function(String title, String priority, DateTime date, String recurrence, String category) onSave;
  const _AddTaskSheet({required this.onSave});
  @override State<_AddTaskSheet> createState() => _AddTaskSheetState();
}
class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController(); 
  String _priority = "Normal"; 
  DateTime _selectedDate = DateTime.now();
  String _recurrence = "None";
  String _category = "General";

  @override Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Center(child: Text("Create Task", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: NotesModuleScreen.primaryBlue))), const SizedBox(height: 20),
        TextField(controller: _titleController, autofocus: true, decoration: InputDecoration(hintText: "What needs to be done?", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))), const SizedBox(height: 20),
        
        Row(children: [
          Expanded(child: InkWell(onTap: () async { DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100)); if (picked != null) setState(() => _selectedDate = picked); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(15)), child: Row(children: [const Icon(Icons.calendar_today, size: 18, color: NotesModuleScreen.primaryBlue), const SizedBox(width: 10), Text(DateFormat('MMM dd').format(_selectedDate), style: const TextStyle(fontSize: 14))])))), const SizedBox(width: 10),
          Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(15)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _priority, isExpanded: true, items: ["Low", "Normal", "High"].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), onChanged: (val) => setState(() => _priority = val!)))))
        ]), const SizedBox(height: 15),

        // NEW: CATEGORY & RECURRENCE ROW
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(15)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _category, isExpanded: true, items: ["General", "Medication", "Appointment", "Exercise"].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), onChanged: (val) => setState(() => _category = val!))))), const SizedBox(width: 10),
          Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(15)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _recurrence, isExpanded: true, items: ["None", "Daily", "Weekly", "Monthly"].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value == "None" ? "Does not repeat" : value))).toList(), onChanged: (val) => setState(() => _recurrence = val!)))))
        ]), const SizedBox(height: 30),

        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: NotesModuleScreen.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: () { if (_titleController.text.trim().isNotEmpty) widget.onSave(_titleController.text.trim(), _priority, _selectedDate, _recurrence, _category); Navigator.pop(context); }, child: const Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ]),
    );
  }
}