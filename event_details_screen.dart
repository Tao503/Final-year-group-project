import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../controllers/event_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/event_model.dart';
import '../../services/supabase_service.dart';
import '../../screens/chat/chat_detail_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isRegistered = false;
  bool _isSaved = false;
  final TextEditingController _commentController = TextEditingController();
  final EventController _controller = Get.find<EventController>();

  @override
  void initState() {
    super.initState();
    
    _controller.currentEventId.value = widget.event.id;
    
    _controller.fetchComments(widget.event.id);
    
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final isRegistered = await _controller.isRegisteredForEvent(
      widget.event.id,
    );
    if (mounted) {
      setState(() {
        _isRegistered = isRegistered;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _controller.currentEventId.value = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final daysUntil = widget.event.eventDate.difference(DateTime.now()).inDays;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.cardGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              
              _buildHeader(context, isDark, theme),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      _buildHeroImage(isDark, daysUntil),
                      
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            _buildTitleAndCategory(isDark, theme),
                            const SizedBox(height: 24),
                            
                            _buildDescription(isDark, theme),
                            const SizedBox(height: 24),
                            
                            _buildDetailsCard(isDark, theme),
                            const SizedBox(height: 24),
                            
                            _buildOrganizerInfo(isDark, theme),
                            const SizedBox(height: 24),
                            
                            if (widget.event.tags != null &&
                                widget.event.tags!.isNotEmpty) ...[
                              _buildTags(isDark, theme),
                              const SizedBox(height: 24),
                            ],
                            
                            _buildLikesAndComments(isDark, theme),
                            const SizedBox(height: 32),
                            
                            _buildActionButtons(context, isDark, theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: EnhancedTheme.glassGradient(isDark),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
            color: isDark ? Colors.white : Colors.black87,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Event Details',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isSaved
                  ? EnhancedTheme.accentAmber
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            onPressed: () {
              setState(() {
                _isSaved = !_isSaved;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
            color: isDark ? Colors.white : Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(bool isDark, int daysUntil) {
    return Container(
      height: 400,
      width: double.infinity,
      child: Stack(
        children: [
          widget.event.imageUrl != null
              ? Image.network(
            widget.event.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.event, size: 64),
              );
            },
          )
              : Container(
            color: Colors.grey[300],
            child: const Icon(Icons.event, size: 64),
          ),
          
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),
          
          if (daysUntil >= 0)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: daysUntil == 0
                      ? EnhancedTheme.energyGradient
                      : EnhancedTheme.oceanGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: EnhancedTheme.glowEffect,
                ),
                child: Column(
                  children: [
                    Text(
                      daysUntil == 0 ? 'TODAY' : '$daysUntil',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    if (daysUntil > 0)
                      const Text(
                        'days left',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleAndCategory(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.event.title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: EnhancedTheme.premiumGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.event.category ?? 'General',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.event.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: EnhancedTheme.glassGradient(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: EnhancedTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.location_on_rounded,
            'Location',
            widget.event.location,
            isDark,
            theme,
          ),
          const Divider(height: 32),
          _buildDetailRow(
            Icons.access_time_rounded,
            'Start Time',
            _formatDateTime(widget.event.eventDate),
            isDark,
            theme,
          ),
          if (widget.event.endDate != null) ...[
            const Divider(height: 32),
            _buildDetailRow(
              Icons.schedule_rounded,
              'End Time',
              _formatDateTime(widget.event.endDate!),
              isDark,
              theme,
            ),
          ],
          if (widget.event.attendees != null ||
              widget.event.maxAttendees != null) ...[
            const Divider(height: 32),
            _buildDetailRow(
              Icons.people_rounded,
              'Attendees',
              '${widget.event.attendees ?? 0}/${widget.event.maxAttendees ?? '∞'} registered',
              isDark,
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon,
      String label,
      String value,
      bool isDark,
      ThemeData theme,
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: EnhancedTheme.premiumGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerInfo(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: EnhancedTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: EnhancedTheme.oceanGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organized by',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.event.organizer ?? widget.event.userName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.message_rounded),
            onPressed: () async {
              
              final organizerId = widget.event.userId;
              if (organizerId.isNotEmpty) {
                final chatController = Get.find<ChatController>();
                final conversationId = await chatController.getOrCreateConversation(organizerId);
                if (conversationId != null && mounted) {
                  
                  final supabase = SupabaseService.client;
                  final organizerProfile = await supabase
                      .from('user_profiles')
                      .select('id, full_name, avatar_url')
                      .eq('id', organizerId)
                      .maybeSingle();

                  Get.to(() => ChatDetailScreen(
                    conversationId: conversationId,
                    otherUserId: organizerId,
                    otherUserName: organizerProfile?['full_name'] ?? widget.event.organizer ?? widget.event.userName,
                    otherUserAvatar: organizerProfile?['avatar_url'],
                  ));
                }
              }
            },
            color: EnhancedTheme.primaryIndigo,
          ),
        ],
      ),
    );
  }

  Widget _buildTags(bool isDark, ThemeData theme) {
    if (widget.event.tags == null || widget.event.tags!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.event.tags!.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: EnhancedTheme.primaryIndigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: EnhancedTheme.primaryIndigo.withOpacity(0.3),
            ),
          ),
          child: Text(
            '#$tag',
            style: theme.textTheme.bodySmall?.copyWith(
              color: EnhancedTheme.primaryIndigo,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      bool isDark,
      ThemeData theme,
      ) {
    return Column(
      children: [
        if (!_isRegistered)
          GradientButton(
            text: 'Register for Event',
            gradient: EnhancedTheme.premiumGradient,
            icon: Icons.how_to_reg_rounded,
            onPressed: () async {
              final success = await _controller.registerForEvent(
                widget.event.id,
              );
              if (success && mounted) {
                setState(() {
                  _isRegistered = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Successfully registered!'),
                    backgroundColor: EnhancedTheme.accentEmerald,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to register. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            padding: const EdgeInsets.symmetric(vertical: 18),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: EnhancedTheme.successGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Registered',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLikesAndComments(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: EnhancedTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Obx(() {
            
            final updatedEvent =
                _controller.events.firstWhereOrNull(
                      (e) => e.id == widget.event.id,
                ) ??
                    widget.event;

            return Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    await _controller.likeEvent(widget.event.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: updatedEvent.isLiked
                          ? Colors.red.withOpacity(0.1)
                          : (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: updatedEvent.isLiked
                            ? Colors.red
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          updatedEvent.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: updatedEvent.isLiked
                              ? Colors.red
                              : (isDark ? Colors.white70 : Colors.black54),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${updatedEvent.likesCount}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: updatedEvent.isLiked
                                ? Colors.red
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${updatedEvent.commentsCount}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          
          Text(
            'Comments',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  if (_commentController.text.trim().isEmpty) return;

                  final success = await _controller.commentOnEvent(
                    widget.event.id,
                    _commentController.text.trim(),
                  );

                  if (success && mounted) {
                    _commentController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comment posted!'),
                        backgroundColor: EnhancedTheme.accentEmerald,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: EnhancedTheme.premiumGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Obx(() {
            final comments = _controller.eventComments[widget.event.id] ?? [];

            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No comments yet. Be the first to comment!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              children: comments.map((comment) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: EnhancedTheme.premiumGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            comment.userName.isNotEmpty
                                ? comment.userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment.userName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatCommentTime(comment.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  String _formatCommentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDateTime(DateTime date) {
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
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $amPm';
  }
}
