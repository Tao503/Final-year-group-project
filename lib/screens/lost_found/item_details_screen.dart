import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../models/item_model.dart';
import '../../services/supabase_service.dart';
import '../../controllers/chat_controller.dart';
import '../chat/chat_detail_screen.dart';

class ItemDetailsScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

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
              
              _buildHeader(context, isDark, theme),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      _buildImage(isDark),
                      
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            _buildTitleAndStatus(isDark, theme),
                            const SizedBox(height: 20),
                            
                            _buildDescription(isDark, theme),
                            const SizedBox(height: 24),
                            
                            _buildDetailsGrid(isDark, theme),
                            const SizedBox(height: 32),
                            
                            _buildActionButtons(context, isDark),
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
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            color: isDark ? Colors.white : Colors.black87,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Item Details',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              
            },
            color: isDark ? Colors.white : Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
      ),
      child: item.imageUrl != null
          ? Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 64),
                );
              },
            )
          : Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 64),
            ),
    );
  }

  Widget _buildTitleAndStatus(bool isDark, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            item.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: item.type == 'lost'
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.type == 'lost' ? 'Lost' : 'Found',
            style: theme.textTheme.labelMedium?.copyWith(
              color: item.type == 'lost' ? Colors.red[700] : Colors.green[700],
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsGrid(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (item.location != null) ...[
            _buildDetailRow(
              Icons.location_on,
              'Location',
              item.location!,
              isDark,
              theme,
            ),
            const Divider(height: 24),
          ],
          _buildDetailRow(
            Icons.calendar_today,
            'Date Found',
            item.dateFound != null
                ? '${item.dateFound!.day}/${item.dateFound!.month}/${item.dateFound!.year}'
                : '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
            isDark,
            theme,
          ),
          if (item.category.isNotEmpty) ...[
            const Divider(height: 24),
            _buildDetailRow(
              Icons.category,
              'Category',
              item.category,
              isDark,
              theme,
            ),
          ],
          if (item.color.isNotEmpty) ...[
            const Divider(height: 24),
            _buildDetailRow(Icons.palette, 'Color', item.color, isDark, theme),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
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
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    final isOwner = currentUserId != null && item.userId == currentUserId;

    return Column(
      children: [
        if (!isOwner)
          GradientButton(
            text: 'Contact Owner',
            gradient: AppTheme.primaryGradient,
            icon: Icons.message,
            onPressed: () async {
              final chatController = Get.find<ChatController>();
              final conversationId = await chatController
                  .getOrCreateConversation(item.userId);

              if (conversationId != null) {
                
                final profilesResponse = await SupabaseService.client
                    .from('user_profiles')
                    .select('full_name, avatar_url')
                    .eq('id', item.userId)
                    .maybeSingle();

                Get.to(
                  () => ChatDetailScreen(
                    conversationId: conversationId,
                    otherUserId: item.userId,
                    otherUserName:
                        profilesResponse?['full_name'] ?? item.userName,
                    otherUserAvatar: profilesResponse?['avatar_url'],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to start conversation. Please try again.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        if (!isOwner) const SizedBox(height: 12),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                'Save Item',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
