import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  final TextEditingController messageController = TextEditingController();
  bool _isSending = false;

  List<Map<String, dynamic>> messages = [];

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      messages.add({"text": text, "isBot": false});
      _isSending = true;
    });

    messageController.clear();

    try {
      final headers = await ApiService.getAuthHeaders();

      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/chat/rag'),
        headers: headers,
        body: jsonEncode({'question': text}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer']?.toString() ?? 'I could not generate an answer.';
        setState(() {
          messages.add({"text": answer, "isBot": true});
        });
      } else {
        setState(() {
          messages.add({
            "text": "Sorry, I could not get an answer (code ${response.statusCode}).",
            "isBot": true,
          });
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add({
          "text": "Network error: $e",
          "isBot": true,
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
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
                  onTap: _isSending ? null : sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSending ? Colors.grey : primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
