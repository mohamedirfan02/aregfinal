import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:areg_app/common/app_colors.dart';
import '../../fbo_services/chatbot_service.dart';

// 1. Draggable Floating Chatbot Button Widget
class DraggableChatbotButton extends StatefulWidget {
  const DraggableChatbotButton({super.key});

  @override
  _DraggableChatbotButtonState createState() => _DraggableChatbotButtonState();
}

class _DraggableChatbotButtonState extends State<DraggableChatbotButton> {
  Offset position = const Offset(20, 100); // Initial position

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: _buildButton(true),
        childWhenDragging: Container(), // Hide original while dragging
        onDragEnd: (details) {
          setState(() {
            // Keep button within screen bounds
            double newX = details.offset.dx;
            double newY = details.offset.dy;

            // Ensure button stays within screen bounds
            newX = newX.clamp(0.0, screenSize.width - 60);
            newY = newY.clamp(0.0, screenSize.height - 60);

            position = Offset(newX, newY);
          });
        },
        child: _buildButton(false),
      ),
    );
  }

  Widget _buildButton(bool isDragging) {
    return Material(
      elevation: isDragging ? 8 : 4,
      shape: const CircleBorder(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.white, AppColors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: isDragging ? null : _showChatbotPopup,
          borderRadius: BorderRadius.circular(30),
          child: ClipOval(
            child: Image.asset(
              'assets/icon/enzopik.png', // Replace with your image path
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  void _showChatbotPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const ChatbotPopup();
      },
    );
  }
}

// 2. Chatbot Popup Dialog
class ChatbotPopup extends StatefulWidget {
  const ChatbotPopup({super.key});

  @override
  _ChatbotPopupState createState() => _ChatbotPopupState();
}

class _ChatbotPopupState extends State<ChatbotPopup> {
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
      showPreSendContent = false;
    });

    _messageController.clear();
    _scrollToBottom();

    String response = await ChatbotService.sendMessage(question);
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        height: screenHeight * 0.8,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text(
                    "AI Assistant",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Chat Content
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
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

                  // Pre-send content
                  if (showPreSendContent)
                    Column(
                      children: [
                        SizedBox(
                          height: 120,
                          child: Center(
                            child: Lottie.asset(
                              'assets/animations/bot_wait.json',
                              repeat: true,
                              animate: true,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppColors.primaryColor : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb, color: AppColors.secondaryColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Ask anything about our services!",
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

                  // Message Input
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                              onSubmitted: (value) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: Image.asset(
                              'assets/icon/send.png',
                              width: 30,
                              height: 30,
                            ),
                            onPressed: _sendMessage,
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
      ),
    );
  }

  Widget _chatBubble(BuildContext context, String text, bool isUser) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    double maxBubbleWidth = MediaQuery.of(context).size.width * 0.6;

    Color userBubbleColor = isDarkMode ? Colors.green[700]! : AppColors.secondaryColor;
    Color botBubbleColor = isDarkMode ? Colors.green[900]! : AppColors.secondaryColor;

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser)
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/image/botimage.jpg'),
          ),
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUser ? userBubbleColor : botBubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? (isDarkMode ? Colors.black : Colors.white) : Colors.white,
              ),
            ),
          ),
        ),
        if (isUser)
          const CircleAvatar(
            radius: 14,
            backgroundImage: AssetImage('assets/icon/user.png'),
          ),
      ],
    );
  }

  Widget _typingIndicator(BuildContext context) {
    double maxBubbleWidth = MediaQuery.of(context).size.width * 0.3;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage('assets/gif/bot.gif'),
        ),
        Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(
            'assets/gif/load.gif',
            width: 35,
            height: 20,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

