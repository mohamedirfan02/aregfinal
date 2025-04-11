import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../fbo_services/chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> messages = [];
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();

  /// ✅ Handle user input & API call
  void _sendMessage() async {
    String question = _messageController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "message": question});
      isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom(); // Auto scroll to bottom

    String response = await ChatbotService.sendMessage(question);

    setState(() {
      messages.add({"role": "bot", "message": response});
      isLoading = false;
    });

    _scrollToBottom();
  }

  /// ✅ Auto-scroll to bottom when new message appears
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text("Chatbot"),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // ✅ Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length + (isLoading ? 1 : 0), // Add typing indicator if loading
              itemBuilder: (context, index) {
                if (index == messages.length && isLoading) {
                  return _typingIndicator();
                }

                final message = messages[index];
                bool isUser = message["role"] == "user";
                return _chatBubble(message["message"] ?? "", isUser);
              },
            ),
          ),

          // ✅ Message Input Field
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.green[700],
                  radius: 25,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ WhatsApp-style Chat Bubble
  Widget _chatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[700] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 5, spreadRadius: 1),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16),
        ),
      ),
    );
  }

  /// ✅ Instagram-style Typing Indicator
  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 5, spreadRadius: 1),
          ],
        ),
        child:  Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitThreeBounce(
              color: Colors.green,
              size: 10,
            ),
          ],
        ),
      ),
    );
  }
}
