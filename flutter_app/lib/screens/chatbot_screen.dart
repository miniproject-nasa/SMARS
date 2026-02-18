import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  final TextEditingController messageController = TextEditingController();

  List<Map<String, dynamic>> messages = [
    {"text": "Hi Ashiq Kareem, Welcome!", "isBot": true},
    {
      "text": "He is your friend and colleague at your work.",
      "isBot": true
    },
    {"text": "Hello, I need Help", "isBot": false},
    {"text": "Who is Raziq?", "isBot": false},
  ];

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "text": messageController.text,
        "isBot": false,
      });
    });

    messageController.clear();

    // Fake bot response for UI
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        messages.add({
          "text": "I will help you remember that.",
          "isBot": true,
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Chatbot"),
      ),

      body: Column(
        children: [

          /// 🔹 CHAT AREA
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[index];
                final isBot = msg["isBot"];

                return Align(
                  alignment:
                      isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 260),
                    decoration: BoxDecoration(
                      color: isBot ? Colors.white : primaryBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(
                        color: isBot ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔹 INPUT BAR
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message here",
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
