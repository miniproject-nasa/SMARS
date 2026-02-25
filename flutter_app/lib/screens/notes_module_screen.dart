import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class NotesModuleScreen extends StatefulWidget {
  const NotesModuleScreen({super.key});
  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);
  @override
  State<NotesModuleScreen> createState() => _NotesModuleScreenState();
}

class _NotesModuleScreenState extends State<NotesModuleScreen> {
  int selectedTab = 0;
  final tabs = ["Journal", "People", "Tasks"];
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _notes = [];
  List<dynamic> _photos = [];
  List<dynamic> _tasks = [];
  List<dynamic> _filteredList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDisplayName() {
    if (selectedTab == 0) return "Journal Entries";
    if (selectedTab == 1) return "People";
    return "Tasks";
  }

  // 🟢 IMPLEMENTED: Search filter for all tabs
  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredList = [];
      } else if (selectedTab == 0) {
        _filteredList = _notes
            .where(
              (note) =>
                  (note['title'] ?? '').toString().toLowerCase().contains(
                    query,
                  ) ||
                  (note['content'] ?? '').toString().toLowerCase().contains(
                    query,
                  ),
            )
            .toList();
      } else if (selectedTab == 1) {
        _filteredList = _photos
            .where(
              (photo) =>
                  (photo['name'] ?? '').toString().toLowerCase().contains(
                    query,
                  ) ||
                  (photo['relation'] ?? '').toString().toLowerCase().contains(
                    query,
                  ),
            )
            .toList();
      } else {
        _filteredList = _tasks
            .where(
              (task) =>
                  (task['title'] ?? '').toString().toLowerCase().contains(
                    query,
                  ) ||
                  (task['category'] ?? '').toString().toLowerCase().contains(
                    query,
                  ),
            )
            .toList();
      }
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final notes = await ApiService.getNotes();
      final contacts = await ApiService.getContacts();
      final tasks = await ApiService.getAllTasks();
      setState(() {
        _notes = notes;
        _photos = contacts;
        _tasks = tasks;
        _filterList();
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openAddSheet() {
    _searchController.clear();
    if (selectedTab == 0)
      _showNoteSheet();
    else if (selectedTab == 1)
      _showPhotoSheet();
    else
      _showTaskSheet();
  }

  void _showNoteSheet({Map<String, dynamic>? existingNote}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddNoteSheet(
        existingNote: existingNote,
        onSave: (title, content, imageBytes, filename) async {
          try {
            if (existingNote != null)
              await ApiService.updateNote(
                existingNote['_id'],
                title,
                content,
                imageBytes: imageBytes,
                filename: filename,
              );
            else
              await ApiService.createNote(
                title,
                content,
                imageBytes: imageBytes,
                filename: filename,
              );
            _fetchData();
          } catch (e) {
            debugPrint("Error saving note: $e");
          }
        },
      ),
    );
  }

  void _showPhotoSheet({Map<String, dynamic>? existingContact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPhotoSheet(
        existingContact: existingContact,
        onSave: (name, phone, desc, imageBytes, filename) async {
          try {
            if (existingContact != null)
              await ApiService.updateContact(
                id: existingContact['_id'],
                name: name,
                relation: desc,
                phone: phone,
                imageBytes: imageBytes,
                imageFileName: filename,
              );
            else
              await ApiService.createContact(
                name: name,
                relation: desc,
                phone: phone,
                imageBytes: imageBytes,
                imageFileName: filename,
              );
            _fetchData();
          } catch (e) {
            debugPrint("Error saving contact: $e");
          }
        },
      ),
    );
  }

  void _showTaskSheet({Map<String, dynamic>? existingTask}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskSheet(
        existingTask: existingTask,
        onSave: (title, priority, date, recurrence, category) async {
          try {
            final taskData = {
              'title': title,
              'priority': priority,
              'date': date.toIso8601String(),
              'recurrence': recurrence,
              'category': category,
            };
            if (existingTask != null)
              await ApiService.updateTask(existingTask['_id'], taskData);
            else
              await ApiService.createTask(taskData);
            _fetchData();
          } catch (e) {
            debugPrint("Error saving task: $e");
          }
        },
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
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCurrentView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NotesModuleScreen.primaryBlue,
        elevation: 6,
        onPressed: _openAddSheet,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Text(
            "My Workspace",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
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
          final isSelected = selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() {
              selectedTab = index;
              _searchController.clear();
              _filterList();
            }),
            child: Column(
              children: [
                Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? NotesModuleScreen.primaryBlue
                        : Colors.grey,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: NotesModuleScreen.primaryBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search ${_getDisplayName().toLowerCase()}...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (_) => _filterList(),
      ),
    );
  }

  List<dynamic> _getDisplayList() {
    if (_searchController.text.isEmpty) {
      if (selectedTab == 0) return _notes;
      if (selectedTab == 1) return _photos;
      return _tasks;
    }
    return _filteredList;
  }

  Widget _buildCurrentView() {
    final displayList = _getDisplayList();

    if (selectedTab == 0) {
      if (displayList.isEmpty)
        return const Center(child: Text("No entries yet."));
      return ListView.builder(
        padding: const EdgeInsets.only(
          right: 10,
          left: 10,
          bottom: 80,
          top: 10,
        ),
        itemCount: displayList.length,
        itemBuilder: (context, i) => _buildNoteCard(i, displayList[i]),
      );
    } else if (selectedTab == 1) {
      if (displayList.isEmpty)
        return const Center(child: Text("No contacts yet."));
      return GridView.builder(
        padding: const EdgeInsets.only(
          right: 10,
          left: 10,
          bottom: 80,
          top: 10,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.85,
        ),
        itemCount: displayList.length,
        itemBuilder: (context, i) => _buildPhotoCard(i, displayList[i]),
      );
    } else {
      if (displayList.isEmpty)
        return const Center(child: Text("No tasks yet."));
      return ListView.builder(
        padding: const EdgeInsets.only(
          right: 10,
          left: 10,
          bottom: 80,
          top: 10,
        ),
        itemCount: displayList.length,
        itemBuilder: (context, i) => _buildTaskCard(i, displayList[i]),
      );
    }
  }

  // 🟢 NOTE CARD WITH TAP TO VIEW DETAILS
  Widget _buildNoteCard(int index, dynamic note) {
    final date = DateTime.parse(
      note["createdAt"] ?? DateTime.now().toIso8601String(),
    ).toLocal();
    final hasImage = note["imageUrl"] != null && note["imageUrl"].isNotEmpty;

    return GestureDetector(
      onTap: () => _showNoteDetailsDialog(note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  note["imageUrl"],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note["title"] ?? "Untitled",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NotesModuleScreen.primaryBlue,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) async {
                          if (value == 'edit')
                            _showNoteSheet(existingNote: note);
                          else if (value == 'delete') {
                            try {
                              await ApiService.deleteNote(note['_id']);
                              _fetchData();
                            } catch (e) {
                              debugPrint("Error deleting note: $e");
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 10),
                                Text("Edit"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 10),
                                Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note["content"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 CONTACT CARD WITH EDIT/DELETE MENU
  Widget _buildPhotoCard(int index, dynamic photo) {
    final hasCustomPhoto =
        photo["imageUrl"] != null && photo["imageUrl"].isNotEmpty;
    return GestureDetector(
      onTap: () => _showContactDetailsDialog(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: hasCustomPhoto
                ? NetworkImage(photo["imageUrl"])
                : NetworkImage("https://i.pravatar.cc/150?u=${photo['_id']}"),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 8,
              right: 8,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                ),
                onSelected: (value) async {
                  if (value == 'edit')
                    _showPhotoSheet(existingContact: photo);
                  else if (value == 'delete') {
                    try {
                      await ApiService.deleteContact(photo['_id']);
                      _fetchData();
                    } catch (e) {
                      debugPrint("Error deleting contact: $e");
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.blue),
                        SizedBox(width: 10),
                        Text("Edit", style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Delete", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 TASK CARD WITH EDIT/DELETE
  Widget _buildTaskCard(int index, dynamic task) {
    final date = DateTime.parse(
      task["date"] ?? DateTime.now().toIso8601String(),
    ).toLocal();

    IconData categoryIcon = Icons.check_circle_outline;
    if (task["category"] == "Medication")
      categoryIcon = Icons.medical_services_outlined;
    if (task["category"] == "Appointment")
      categoryIcon = Icons.calendar_month_outlined;
    if (task["category"] == "Exercise") categoryIcon = Icons.directions_run;

    Color priorityColor = Colors.green;
    if (task["priority"] == "High") priorityColor = Colors.redAccent;
    if (task["priority"] == "Medium") priorityColor = Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          activeColor: NotesModuleScreen.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          value: task["done"] ?? false,
          onChanged: (v) async {
            setState(
              () =>
                  _tasks[_tasks.indexWhere(
                        (t) => t['_id'] == task['_id'],
                      )]["done"] =
                      v,
            );
            try {
              await ApiService.toggleTask(task['_id']);
              _filterList();
            } catch (e) {
              setState(
                () =>
                    _tasks[_tasks.indexWhere(
                          (t) => t['_id'] == task['_id'],
                        )]["done"] =
                        !v!,
              );
            }
          },
        ),
        title: Row(
          children: [
            Icon(categoryIcon, size: 18, color: NotesModuleScreen.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task["title"] ?? "Untitled",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: task["done"] == true
                      ? TextDecoration.lineThrough
                      : null,
                  color: task["done"] == true ? Colors.grey : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 26),
          child: Row(
            children: [
              Text(
                DateFormat('MMM dd').format(date),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 14, color: priorityColor),
                    const SizedBox(width: 4),
                    Text(
                      task["priority"] ?? "Low",
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) async {
            if (value == 'edit')
              _showTaskSheet(existingTask: task);
            else if (value == 'delete') {
              try {
                await ApiService.deleteTask(task['_id']);
                _fetchData();
              } catch (e) {
                debugPrint("Error deleting task: $e");
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 10),
                  Text("Edit"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Delete", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 FULL SCREEN IMAGE VIEWER WITH INTERACTIVE VIEWER
  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 1,
                maxScale: 4,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 FULL DETAILS DIALOG FOR NOTES
  void _showNoteDetailsDialog(dynamic note) {
    final date = DateTime.parse(
      note["createdAt"] ?? DateTime.now().toIso8601String(),
    ).toLocal();
    final hasImage = note["imageUrl"] != null && note["imageUrl"].isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showFullScreenImage(note["imageUrl"]);
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      note["imageUrl"],
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note["title"] ?? "Untitled",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: NotesModuleScreen.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      note["content"] ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: NotesModuleScreen.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🟢 FULL DETAILS DIALOG FOR CONTACTS
  void _showContactDetailsDialog(dynamic contact) {
    final hasImage =
        contact["imageUrl"] != null && contact["imageUrl"].isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showFullScreenImage(contact["imageUrl"]);
                },
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    contact["imageUrl"],
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.person, size: 80, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact["name"] ?? "Unknown",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: NotesModuleScreen.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contact["relation"] ?? "No description",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Close",
                      style: TextStyle(color: NotesModuleScreen.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 BOTTOM SHEETS

// 🟢 NOTE SHEET WITH CAMERA OPTION
class _AddNoteSheet extends StatefulWidget {
  final Map<String, dynamic>? existingNote;
  final Function(
    String title,
    String content,
    Uint8List? imageBytes,
    String? filename,
  )
  onSave;

  const _AddNoteSheet({this.existingNote, required this.onSave});
  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?["title"] ?? "",
    );
    _contentController = TextEditingController(
      text: widget.existingNote?["content"] ?? "",
    );
    _existingImageUrl = widget.existingNote?["imageUrl"];
  }

  // 🟢 PICK IMAGE FROM CAMERA OR GALLERY
  Future<void> _pickImage({required bool isCamera}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageFileName = pickedFile.name;
        _existingImageUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingNote != null ? "Edit Entry" : "New Entry",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: NotesModuleScreen.primaryBlue,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NotesModuleScreen.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    if (_titleController.text.trim().isNotEmpty &&
                        _contentController.text.trim().isNotEmpty) {
                      widget.onSave(
                        _titleController.text.trim(),
                        _contentController.text.trim(),
                        _imageBytes,
                        _imageFileName,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (_imageBytes != null ||
              (_existingImageUrl != null && _existingImageUrl!.isNotEmpty))
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : NetworkImage(_existingImageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                  onPressed: () => setState(() {
                    _imageBytes = null;
                    _existingImageUrl = null;
                  }),
                ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: "Title",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _contentController,
                autofocus: _imageBytes == null,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: "Start writing...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 18, height: 1.6),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.format_bold, color: Colors.black54),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.format_list_bulleted,
                    color: Colors.black54,
                  ),
                  onPressed: () {},
                ),
                // 🟢 CAMERA BUTTON
                IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    color: NotesModuleScreen.primaryBlue,
                    size: 28,
                  ),
                  onPressed: () => _pickImage(isCamera: true),
                ),
                // 🟢 GALLERY BUTTON
                IconButton(
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: NotesModuleScreen.primaryBlue,
                    size: 28,
                  ),
                  onPressed: () => _pickImage(isCamera: false),
                ),
                IconButton(
                  icon: const Icon(Icons.mic_none, color: Colors.black54),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🟢 CONTACT SHEET WITH CAMERA OPTION
class _AddPhotoSheet extends StatefulWidget {
  final Map<String, dynamic>? existingContact;
  final Function(
    String name,
    String phone,
    String desc,
    Uint8List? imageBytes,
    String? filename,
  )
  onSave;

  const _AddPhotoSheet({this.existingContact, required this.onSave});
  @override
  State<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends State<_AddPhotoSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _descController;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingContact?["name"] ?? "",
    );
    _phoneController = TextEditingController(
      text: widget.existingContact?["phone"] ?? "",
    );
    _descController = TextEditingController(
      text: widget.existingContact?["relation"] ?? "",
    );
    _existingImageUrl = widget.existingContact?["imageUrl"];
  }

  // 🟢 PICK IMAGE WITH CAMERA OPTION
  Future<void> _pickImage({required bool isCamera}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageFileName = pickedFile.name;
        _existingImageUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.existingContact != null
                ? "Edit Contact"
                : "New Contact Profile",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: NotesModuleScreen.primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: () => _pickImage(isCamera: false),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    image: _imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_imageBytes!),
                            fit: BoxFit.cover,
                          )
                        : (_existingImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_existingImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                  ),
                  child: (_imageBytes == null && _existingImageUrl == null)
                      ? const Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),
              // 🟢 CAMERA BUTTON
              GestureDetector(
                onTap: () => _pickImage(isCamera: true),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: NotesModuleScreen.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Tap photo for gallery, click camera for live photo",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Person's Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Short Description / Relationship",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NotesModuleScreen.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty &&
                    _phoneController.text.trim().isNotEmpty) {
                  widget.onSave(
                    _nameController.text.trim(),
                    _phoneController.text.trim(),
                    _descController.text.trim(),
                    _imageBytes,
                    _imageFileName,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(
                widget.existingContact != null
                    ? "Update Profile"
                    : "Save Profile",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🟢 TASK SHEET
class _AddTaskSheet extends StatefulWidget {
  final Map<String, dynamic>? existingTask;
  final Function(
    String title,
    String priority,
    DateTime date,
    String recurrence,
    String category,
  )
  onSave;

  const _AddTaskSheet({this.existingTask, required this.onSave});
  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  late TextEditingController _titleController;
  late String _priority;
  late DateTime _selectedDate;
  late String _recurrence;
  late String _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingTask?["title"] ?? "",
    );
    _priority = widget.existingTask?["priority"] ?? "Normal";
    _selectedDate = widget.existingTask != null
        ? DateTime.parse(widget.existingTask!["date"])
        : DateTime.now();
    _recurrence = widget.existingTask?["recurrence"] ?? "None";
    _category = widget.existingTask?["category"] ?? "General";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              widget.existingTask != null ? "Edit Task" : "Create Task",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: NotesModuleScreen.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "What needs to be done?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: NotesModuleScreen.primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('MMM dd').format(_selectedDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _priority,
                      isExpanded: true,
                      items: ["Low", "Normal", "High"]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _category,
                      isExpanded: true,
                      items:
                          ["General", "Medication", "Appointment", "Exercise"]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _recurrence,
                      isExpanded: true,
                      items: ["None", "Daily", "Weekly", "Monthly"]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value == "None" ? "Does not repeat" : value,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _recurrence = val!),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NotesModuleScreen.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                if (_titleController.text.trim().isNotEmpty)
                  widget.onSave(
                    _titleController.text.trim(),
                    _priority,
                    _selectedDate,
                    _recurrence,
                    _category,
                  );
                Navigator.pop(context);
              },
              child: Text(
                widget.existingTask != null ? "Update Task" : "Add Task",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
