import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../controllers/donation_controller.dart';
import '../../models/donation_model.dart';
import '../../services/supabase_service.dart';

class DonationDetailsScreen extends StatefulWidget {
  final DonationModel donation;

  const DonationDetailsScreen({super.key, required this.donation});

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  bool _isRequested = false;
  bool _isSaved = false;

  final DonationController _controller = Get.find<DonationController>();

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
                      
                      _buildHeroImage(isDark),
                      
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            _buildTitleAndStatus(isDark, theme),
                            const SizedBox(height: 24),
                            
                            _buildDescription(isDark, theme),
                            const SizedBox(height: 24),
                            
                            _buildDetailsCard(isDark, theme),
                            const SizedBox(height: 24),
                            
                            _buildDonorInfo(isDark, theme),
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
              'Donation Details',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved
                  ? EnhancedTheme.accentAmber
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            onPressed: () {
              setState(() {
                _isSaved = !_isSaved;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isSaved ? 'Saved to favorites' : 'Removed from favorites',
                  ),
                  backgroundColor: EnhancedTheme.accentEmerald,
                ),
              );
            },
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

  Widget _buildHeroImage(bool isDark) {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
      ),
      child: Stack(
        children: [
          widget.donation.imageUrl != null
              ? Image.network(
            widget.donation.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
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
          
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: widget.donation.status == 'available'
                    ? EnhancedTheme.successGradient
                    : EnhancedTheme.sunsetGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: EnhancedTheme.softShadow,
              ),
              child: Text(
                widget.donation.status == 'available' ? 'Available' : 'Claimed',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleAndStatus(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.donation.title,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: EnhancedTheme.primaryIndigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.donation.recommendedCategory ?? 'General',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: EnhancedTheme.primaryIndigo,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  size: 16,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  'Posted ${_formatDate(widget.donation.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
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
          'Description',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.donation.description,
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
            Icons.category,
            'Category',
            widget.donation.recommendedCategory ?? 'General',
            isDark,
            theme,
          ),
          const Divider(height: 32),
          _buildDetailRow(
            Icons.calendar_today,
            'Posted',
            _formatDate(widget.donation.createdAt),
            isDark,
            theme,
          ),
          const Divider(height: 32),
          _buildDetailRow(
            Icons.location_on,
            'Pickup Location',
            'Campus',
            isDark,
            theme,
          ),
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
            boxShadow: EnhancedTheme.softShadow,
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

  Widget _buildDonorInfo(bool isDark, ThemeData theme) {
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
              gradient: EnhancedTheme.premiumGradient,
              shape: BoxShape.circle,
              boxShadow: EnhancedTheme.softShadow,
            ),
            child: ClipOval(
              child: Image.network(
                'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, color: Colors.white);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.donation.userName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: EnhancedTheme.accentAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Donor',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              
            },
            color: EnhancedTheme.primaryIndigo,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      bool isDark,
      ThemeData theme,
      ) {
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    final isOwner =
        currentUserId != null && widget.donation.userId == currentUserId;

    return Column(
      children: [
        if (!isOwner && widget.donation.status == 'available' && !_isRequested)
          GradientButton(
            text: 'Request This Item',
            gradient: EnhancedTheme.premiumGradient,
            icon: Icons.handshake,
            onPressed: () {
              _showRequestDialog(context, isDark, theme);
            },
            padding: const EdgeInsets.symmetric(vertical: 18),
          )
        else if (_isRequested)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: EnhancedTheme.successGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: EnhancedTheme.softShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Request Sent',
                  style: theme.textTheme.titleMedium?.copyWith(
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
                      Icons.phone,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Contact',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                      Icons.report,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Report',
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

  void _showRequestDialog(BuildContext context, bool isDark, ThemeData theme) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Request Item',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a message to the donor:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Hi! I\'m interested in this item...',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          GradientButton(
            text: 'Send Request',
            gradient: EnhancedTheme.premiumGradient,
            icon: Icons.send,
            onPressed: () async {
              
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              
              final success = await _controller.requestDonation(
                widget.donation.id,
              );

              if (mounted) {
                setState(() {
                  _isRequested = success;
                });

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Request sent successfully!'
                          : 'Failed to send request. Please try again.',
                    ),
                    backgroundColor: success
                        ? EnhancedTheme.accentEmerald
                        : Colors.red,
                  ),
                );
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
