import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/wilson_ai_service.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/quick_suggestions.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<WilsonChatMessage> _messages = [];
  final WilsonAIService _wilsonAI = WilsonAIService();
  
  late AnimationController _animationController;
  bool _isTyping = false;
  String? _currentSessionId;
  String? _userProfilePicture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.forward();

    // Add welcome message
    _addWelcomeMessage();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String? picture;
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['profileImageBase64'] != null) {
          final base64Image = data['profileImageBase64'] as String;
          final imageType = data['profileImageType'] ?? 'image/jpeg';
          picture = 'data:$imageType;base64,$base64Image';
        } else {
          picture = data['profilePicture'] ?? data['photoURL'];
        }
      }
      picture ??= user.photoURL;

      if (mounted) setState(() => _userProfilePicture = picture);
    } catch (e) {
      debugPrint('Error loading user profile for chat: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final welcomeMessages = [
      'Hello! 👋 I\'m Wilson, your AI cybersecurity expert for Africa. I understand M-Pesa, local scams, and digital threats across the continent. Ready to make your digital life safer?',
      'Hi there! 🛡️ Wilson here - your personal cybersecurity assistant. I specialize in African digital security challenges, from mobile money protection to social media safety. How can I help you today?',
      'Welcome! 🌍 I\'m Wilson from Rethicssec. I\'m trained specifically on African cybersecurity challenges - mobile banking, local scams, WiFi security, and more. What security topic interests you?',
    ];
    
    final random = DateTime.now().millisecondsSinceEpoch % welcomeMessages.length;
    
    final welcomeMessage = WilsonChatMessage(
      id: 'welcome',
      text: welcomeMessages[random],
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );
    
    setState(() {
      _messages.add(welcomeMessage);
      _currentSessionId = _wilsonAI.generateSessionId();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // African pattern background
          Positioned.fill(
            child: const AfricanPatternBackground(opacity: 0.03),
          ),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom app bar
                _buildCustomAppBar(),
                
                // Chat messages
                Expanded(
                  child: _messages.isEmpty 
                      ? _buildEmptyState()
                      : _buildMessageList(),
                ),
                
                // Quick suggestions (shown when no messages)
                if (_messages.length <= 1)
                  QuickSuggestions(
                    onSuggestionTap: _handleSuggestionTapWithCustomResponse,
                  ),
                
                // Chat input
                ChatInputField(
                  controller: _messageController,
                  onSend: _handleSendMessage,
                  isLoading: _isTyping,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient.scale(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // AI Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.secondaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 24,
            ),
          )
              .animate()
              .scale(delay: 300.ms, duration: 600.ms)
              .then()
              .shimmer(duration: 2000.ms),
          
          const SizedBox(width: 16),
          
          // AI Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wilson AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(
                          onPlay: (controller) => controller.repeat(),
                        )
                        .fadeIn(duration: 1000.ms)
                        .then()
                        .fadeOut(duration: 1000.ms),
                    
                    const SizedBox(width: 8),
                    
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // More options
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'How can Wilson help you today?',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Ask me anything about cybersecurity, online safety, or digital threats.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return ChatMessageBubble(
            message: WilsonChatMessage(
              id: 'typing',
              text: 'Wilson is thinking...',
              isUser: false,
              timestamp: DateTime.now(),
              type: ChatMessageType.typing,
            ),
          );
        }
        
        return ChatMessageBubble(
          message: _messages[index],
          userPhoto: _userProfilePicture,
        );
      },
    );
  }

  void _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = WilsonChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Always ask the live AI (Wilson via the Cloudflare Worker / Claude).
    await _getWilsonResponse(text);
  }
  
  void _handleSuggestionTapWithCustomResponse(String suggestion, {String? customResponse}) {
    // Route suggestion chips through the live AI too (ignore any canned response).
    _handleSendMessage(suggestion);
  }
  
  void _handleSuggestionTap(String suggestion) {
    _handleSendMessage(suggestion);
  }

  Future<void> _getWilsonResponse(String userMessage) async {
    try {
      // Build conversation history starting from the first USER message, so the
      // API never receives a leading assistant message (the welcome greeting),
      // which the Claude Messages API rejects.
      final textMessages =
          _messages.where((msg) => msg.type == ChatMessageType.text).toList();
      final firstUserIndex = textMessages.indexWhere((msg) => msg.isUser);
      final history = firstUserIndex == -1
          ? <WilsonChatMessage>[]
          : textMessages.sublist(firstUserIndex);

      final conversationMessages = history
          .map((msg) => ChatMessage(
                role: msg.isUser ? 'user' : 'assistant',
                content: msg.text,
              ))
          .toList();

      final response = await _wilsonAI.chatWithWilson(
        messages: conversationMessages,
        sessionId: _currentSessionId,
      );

      final aiMessage = WilsonChatMessage(
        id: response.messageId,
        text: response.response,
        isUser: false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(response.timestamp),
        type: ChatMessageType.text,
      );

      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });

      _scrollToBottom();
    } catch (e) {
      // Honest error only — no fabricated/canned answers.
      final aiMessage = WilsonChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            "I'm having trouble reaching the server right now. Please check your internet connection and try again in a moment.",
        isUser: false,
        timestamp: DateTime.now(),
        type: ChatMessageType.text,
      );

      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });

      _scrollToBottom();
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('How to Use'),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Send Feedback'),
              onTap: () {
                Navigator.pop(context);
                _sendFeedback();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'How to Use Wilson AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: 400,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Wilson AI is your personal cybersecurity assistant. Here\'s how to get the most out of it:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                Icons.chat_bubble_outline,
                'Ask Questions',
                'Type any cybersecurity question and Wilson will provide helpful, Africa-focused answers.',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.lightbulb_outline,
                'Get Suggestions',
                'Use the quick suggestion buttons for common security topics.',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.security,
                'Report Threats',
                'Describe suspicious messages, emails, or websites for analysis.',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.school_outlined,
                'Learn Best Practices',
                'Ask about password security, mobile safety, and online protection.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Example questions:\n'
                  '• "How can I secure my M-Pesa account?"\n'
                  '• "Is this email a scam?"\n'
                  '• "How to create strong passwords?"\n'
                  '• "Safe WiFi practices in cafes"',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.secondaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.feedback,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Send Feedback'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us improve Wilson AI! Your feedback matters to us.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us about your experience with Wilson AI, suggest improvements, or report any issues...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text('Rate your experience:'),
                const Spacer(),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        // Handle rating
                      },
                      child: Icon(
                        Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle feedback submission
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Thank you for your feedback!'),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class WilsonChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;

  const WilsonChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.type,
  });
}

enum ChatMessageType {
  text,
  typing,
  error,
}