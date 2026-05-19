import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';
import '../../core/utils/responsive.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import '../../services/supabase_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatController _controller = Get.find<ChatController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.currentConversationId.value = widget.conversationId;
    _controller.fetchMessages(widget.conversationId);
    _controller.markMessagesAsRead(widget.conversationId);

    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _controller.currentConversationId.value = null;
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final success = await _controller.sendMessage(
      widget.conversationId,
      _messageController.text.trim(),
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<MessageModel> get _messages {
    return _controller.messages[widget.conversationId] ?? [];
  }

  bool _isSentByMe(String senderId) {
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    return currentUserId != null && senderId == currentUserId.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.cardGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              
              _buildHeader(isDark, theme),
              
              Expanded(
                child: Obx(() {
                  if (_messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: Responsive.getPadding(context),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message, isDark, theme);
                    },
                  );
                }),
              ),
              
              _buildInputField(isDark, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: EnhancedTheme.premiumGradient),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: EnhancedTheme.oceanGradient,
            ),
            child: widget.otherUserAvatar != null
                ? ClipOval(
                    child: Image.network(
                      widget.otherUserAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.white);
                      },
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.otherUserName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    MessageModel message,
    bool isDark,
    ThemeData theme,
  ) {
    final isSent = _isSentByMe(message.senderId);
    final maxWidth = Responsive.isMobile(context)
        ? MediaQuery.of(context).size.width * 0.75
        : MediaQuery.of(context).size.width * 0.5;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: Responsive.getSpacing(context, mobile: 12),
          left: isSent ? Responsive.getSpacing(context, mobile: 40) : 0,
          right: !isSent ? Responsive.getSpacing(context, mobile: 40) : 0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.getSpacing(context, mobile: 16),
          vertical: Responsive.getSpacing(context, mobile: 12),
        ),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          gradient: isSent
              ? EnhancedTheme.premiumGradient
              : LinearGradient(
                  colors: [
                    isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
                    isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
                  ],
                ),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isSent ? const Radius.circular(4) : null,
            bottomLeft: !isSent ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: Responsive.getFontSize(context, mobile: 14),
                color: isSent
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isSent
                    ? Colors.white.withOpacity(0.7)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(bool isDark, ThemeData theme) {
    return Container(
      padding: Responsive.getPadding(context),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        boxShadow: EnhancedTheme.softShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: Responsive.getFontSize(context, mobile: 14),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Responsive.getSpacing(context, mobile: 20),
                      vertical: Responsive.getSpacing(context, mobile: 12),
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: Responsive.getFontSize(context, mobile: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: Responsive.getSpacing(context, mobile: 12)),
            Container(
              padding: EdgeInsets.all(
                Responsive.getSpacing(context, mobile: 12),
              ),
              decoration: BoxDecoration(
                gradient: EnhancedTheme.premiumGradient,
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: _sendMessage,
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: Responsive.getIconSize(context, mobile: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      final hour = time.hour > 12
          ? time.hour - 12
          : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final amPm = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $amPm';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[time.month - 1]} ${time.day}';
    }
  }
}
