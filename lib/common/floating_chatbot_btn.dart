import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:areg_app/common/app_colors.dart';
import '../../fbo_services/chatbot_service.dart';

class DraggableChatbotButton extends StatefulWidget {
  const DraggableChatbotButton({super.key});

  @override
  _DraggableChatbotButtonState createState() => _DraggableChatbotButtonState();
}

class _DraggableChatbotButtonState extends State<DraggableChatbotButton>
    with TickerProviderStateMixin {
  Offset? position; // Make it nullable to calculate default position
  bool isDragging = false;
  static const double buttonSize = 60.0;
  static const double padding = 16.0;

  late AnimationController _animationController;
  late Animation<Offset> _animation;
  AnimationController? _rotationController;
  Animation<double>? _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize rotation animation
    try {
      _rotationController = AnimationController(
        duration: const Duration(seconds: 8), // 8 seconds for one full rotation
        vsync: this,
      )..repeat(); // Continuously repeat the rotation

      _rotationAnimation = Tween<double>(
        begin: 0.0,
        end: 2 * 3.14159, // Full 360 degrees in radians
      ).animate(CurvedAnimation(
        parent: _rotationController!,
        curve: Curves.linear,
      ));
    } catch (e) {
      _rotationController = null;
      _rotationAnimation = null;
    }
  }

  // Calculate default bottom-right position
  Offset _getDefaultPosition(Size screenSize, EdgeInsets safeArea) {
    final double maxX = screenSize.width - (buttonSize + 20) - padding;
    // Use total screen height minus app bar height and some bottom padding
    final double maxY = screenSize.height - kToolbarHeight - (buttonSize + 40) - 80; // Extra padding from bottom
    return Offset(maxX, maxY);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // Set default position if not already set
    position ??= _getDefaultPosition(screenSize, safeArea);

    // Initialize animation with current position
    _animation = Tween<Offset>(
      begin: position!,
      end: position!,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Calculate safe draggable area
    final double maxX = screenSize.width - (buttonSize + 20) - padding; // Account for ring size
    final double maxY = screenSize.height - kToolbarHeight - (buttonSize + 40) - 80; // Account for app bar and extra padding
    final double minX = padding;
    final double minY = kToolbarHeight + padding; // Start below app bar

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final currentPosition = isDragging ? position! : _animation.value;

          return Positioned(
            left: currentPosition.dx,
            top: currentPosition.dy,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  isDragging = true;
                });
                _animationController.stop();
              },
              onPanUpdate: (details) {
                setState(() {
                  // Update position in real-time during drag
                  double newX = (position!.dx + details.delta.dx).clamp(minX, maxX);
                  double newY = (position!.dy + details.delta.dy).clamp(minY, maxY);
                  position = Offset(newX, newY);
                });
              },
              onPanEnd: (details) {
                setState(() {
                  isDragging = false;
                });

                // Optional: Add magnetic snap to edges
                _snapToNearestEdge(screenSize, safeArea);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: isDragging ? 0 : 200),
                transform: Matrix4.identity()..scale(isDragging ? 1.1 : 1.0),
                child: _buildButton(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _snapToNearestEdge(Size screenSize, EdgeInsets safeArea) {
    final double maxX = screenSize.width - (buttonSize + 20) - padding;
    final double maxY = screenSize.height - kToolbarHeight - (buttonSize + 40) - 80;
    final double minX = padding;
    final double minY = kToolbarHeight + padding;

    // Determine which edge is closest
    double centerX = position!.dx + (buttonSize + 20) / 2;
    double centerY = position!.dy + (buttonSize + 40) / 2;

    Offset targetPosition = position!;

    // Snap to left or right edge
    if (centerX < screenSize.width / 2) {
      targetPosition = Offset(minX, position!.dy);
    } else {
      targetPosition = Offset(maxX, position!.dy);
    }

    // Animate to target position
    _animation = Tween<Offset>(
      begin: position!,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    position = targetPosition;
    _animationController.reset();
    _animationController.forward();
  }

  Widget _buildButton() {
    // If rotation animation is available, use it; otherwise, show static button
    if (_rotationAnimation != null) {
      return AnimatedBuilder(
        animation: _rotationAnimation!,
        builder: (context, child) {
          return _buildButtonWithRing(_rotationAnimation!.value);
        },
      );
    } else {
      // Fallback to static button without rotation
      return _buildButtonWithRing(0.0);
    }
  }

  Widget _buildButtonWithRing(double rotationAngle) {
    return SizedBox(
      width: buttonSize + 20, // Extra space for the ring
      height: buttonSize + 40, // Extra height for text below
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring (only if rotation is available)
              if (_rotationAnimation != null)
                Transform.rotate(
                  angle: rotationAngle,
                  child: Container(
                    width: buttonSize + 16,
                    height: buttonSize + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2,
                        color: AppColors.primaryColor.withOpacity(0.6),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 2,
                          left: (buttonSize + 16) / 2 - 3,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: (buttonSize + 16) / 2 - 3,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor.withOpacity(0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.3),
                                  blurRadius: 3,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 2,
                          top: (buttonSize + 16) / 2 - 2,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor.withOpacity(0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.2),
                                  blurRadius: 2,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Main button (center/sun)
              Material(
                elevation: isDragging ? 8 : 4,
                shape: const CircleBorder(),
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDragging
                          ? [AppColors.primaryColor.withOpacity(0.8), AppColors.primaryColor]
                          : [AppColors.white, AppColors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(isDragging ? 0.5 : 0.3),
                        blurRadius: isDragging ? 12 : 8,
                        offset: Offset(0, isDragging ? 6 : 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: isDragging ? null : _showChatbotPopup,
                    borderRadius: BorderRadius.circular(30),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icon/enzopik.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.chat_bubble_outline,
                            color: isDragging ? Colors.white : AppColors.primaryColor,
                            size: 28,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chat Bot',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
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
              padding: const EdgeInsets.all(5),
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