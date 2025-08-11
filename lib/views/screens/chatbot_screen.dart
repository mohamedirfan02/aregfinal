import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../fbo_services/chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool isLoading = false;
  bool showPreSendContent = true;
  void _sendMessage() async {
    String question = _messageController.text.trim();
    if (question.isEmpty) return;
    setState(() {
      messages.add({"role": "user", "message": question});
      isLoading = true;
      showPreSendContent = false; // 👈 Hide the content
    });
    _messageController.clear();
    _scrollToBottom();
    String response = await ChatbotService.sendMessage(question);
    // ⏳ Artificial delay to simulate thinking/typing transition
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      messages.add({"role": "bot", "message": response});
      isLoading = false;
    });
    _scrollToBottom();
  }
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Chatbot", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF006D04),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            /// 💬 Foreground - Chat Content
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isLoading) {
                        return _typingIndicator(context);
                      }
                      final message = messages[index];
                      bool isUser = message["role"] == "user";
                      return _chatBubble(context, message["message"] ?? "", isUser);
                    },
                  ),
                ),

                if (showPreSendContent)
                  Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Lottie.asset(
                            'assets/animations/bot_wait.json',
                            repeat: true,
                            animate: true,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.green[900]?.withOpacity(0.3)
                                      : const Color(0xFFEFFFCF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF6FA006),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lightbulb, color: Color(0xFF6FA006)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Tip: Ask anything about our services!",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                // Message Input Field
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode ? Colors.black54 : Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: "Write your message",
                              hintStyle: TextStyle(
                                color: isDarkMode ? Colors.white60 : Colors.black54,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/icon/send.png',
                            width: 30,
                            height: 30,
                            // You can add color if needed but usually leave as-is for PNGs
                          ),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(BuildContext context, String text, bool isUser) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    double maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    Color userBubbleColor = isDarkMode ? Colors.green[700]! : const Color(0xFFD7EB78);
    Color botBubbleColor = isDarkMode ? Colors.green[900]! : const Color(0xFF6FA006);

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser)
          const CircleAvatar(
            radius: 26,
            backgroundImage: AssetImage('assets/image/botimage.jpg'),
          ),
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? userBubbleColor : botBubbleColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isUser ? (isDarkMode ? Colors.black : Colors.black) : Colors.white,
              ),
            ),
          ),
        ),
        if (isUser)
          const CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage('assets/icon/user.png'),
          ),
      ],
    );
  }

  Widget _typingIndicator(BuildContext context) {
    double maxBubbleWidth = MediaQuery.of(context).size.width * 0.4;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundImage: AssetImage('assets/gif/bot.gif'),
        ),
        Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Image.asset(
            'assets/gif/load.gif',
            width: 40,
            height: 25,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

}
