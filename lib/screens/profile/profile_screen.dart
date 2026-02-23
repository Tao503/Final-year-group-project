import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/lost_found_controller.dart';
import '../../controllers/donation_controller.dart';
import '../../services/supabase_service.dart';
import '../saved/saved_items_screen.dart';
import '../chat/chat_list_screen.dart';
import '../edit_profile/edit_profile_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../donate/donate_screen.dart';
import '../auth/auth_screen.dart';
import '../../controllers/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final LostFoundController _lostFoundController =
  Get.find<LostFoundController>();
  final DonationController _donationController = Get.find<DonationController>();
  final _supabase = SupabaseService.client;

  // Get counts from controllers
  int get _myLostCount {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;
    return _lostFoundController.items
        .where((item) => item.userId == userId && item.type == 'lost')
        .length;
  }

  int get _myFoundCount {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;
    return _lostFoundController.items
        .where((item) => item.userId == userId && item.type == 'found')
        .length;
  }

  int get _myDonationCount {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;
    return _donationController.donations
        .where((donation) => donation.userId == userId)
        .length;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Card
                _buildProfileCard(isDark),

                const SizedBox(height: 24),

                // Stats Grid
                _buildStatsGrid(isDark),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(isDark),

                const SizedBox(height: 24),

                // More Options
                _buildMoreOptions(context, isDark, theme),

                const SizedBox(height: 24),

                // Logout Button
                _buildLogoutButton(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Obx(
                  () => ClipOval(
                child:
                _authController.currentUser.value?.avatarUrl != null &&
                    _authController.currentUser.value!.avatarUrl!.isNotEmpty
                    ? Image.network(
                  _authController.currentUser.value!.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                )
                    : Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                      () => Text(
                    _authController.currentUser.value?.fullName ??
                        'Nile Student',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                      () => Text(
                    _authController.currentUser.value?.email ??
                        'student@nileuniversity.edu.ng',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return Obx(
          () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('My Lost', _myLostCount.toString(), isDark),
            _buildStatItem('My Found', _myFoundCount.toString(), isDark),
            _buildStatItem('My Donations', _myDonationCount.toString(), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        _buildActionButton('My Lost Posts', Icons.search, () {
          Get.to(
                () => LostFoundScreen(
              filterUserId: _supabase.auth.currentUser?.id,
              filterType: 'lost',
            ),
          );
        }, isDark),
        const SizedBox(height: 12),
        _buildActionButton('My Found Posts', Icons.check_circle, () {
          Get.to(
                () => LostFoundScreen(
              filterUserId: _supabase.auth.currentUser?.id,
              filterType: 'found',
            ),
          );
        }, isDark),
        const SizedBox(height: 12),
        _buildActionButton('My Donations', Icons.card_giftcard, () {
          Get.to(
                () => DonateScreen(filterUserId: _supabase.auth.currentUser?.id),
          );
        }, isDark),
      ],
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      VoidCallback onTap,
      bool isDark,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOptions(BuildContext context, bool isDark, ThemeData theme) {
    return Column(
      children: [
        _buildActionButton('Saved Items', Icons.bookmark_rounded, () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SavedItemsScreen()),
          );
        }, isDark),
        const SizedBox(height: 12),
        _buildActionButton('Messages', Icons.chat_bubble_rounded, () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        }, isDark),
        const SizedBox(height: 12),
        _buildActionButton('Edit Profile', Icons.edit_rounded, () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          );
        }, isDark),
        const SizedBox(height: 12),
        Obx(
              () => _buildActionButton(
            'Dark Mode',
            Get.find<ThemeController>().isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
                () {
              Get.find<ThemeController>().toggleDarkMode();
            },
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return GradientButton(
      text: 'Logout',
      gradient: LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!]),
      icon: Icons.logout,
      onPressed: () async {
        // Show confirmation dialog
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (shouldLogout == true && mounted) {
          await _authController.signOut();
          // Navigate to auth screen
          Get.offAll(() => const AuthScreen());
        }
      },
    );
  }
}
