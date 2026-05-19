import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';
import '../../controllers/theme_controller.dart';
import '../notifications/notifications_screen.dart';
import '../help/help_screen.dart';
import '../about/about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationEnabled = true;
  final ThemeController _themeController = Get.find<ThemeController>();

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      
                      _buildSection(
                        'Account',
                        [
                          _buildSettingTile(
                            Icons.person_rounded,
                            'Edit Profile',
                            'Update your personal information',
                            () {},
                            isDark,
                            theme,
                          ),
                          _buildSettingTile(
                            Icons.lock_rounded,
                            'Privacy & Security',
                            'Manage your privacy settings',
                            () {},
                            isDark,
                            theme,
                          ),
                          _buildSettingTile(
                            Icons.notifications_rounded,
                            'Notifications',
                            'Manage notification preferences',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationsScreen(),
                                ),
                              );
                            },
                            isDark,
                            theme,
                          ),
                        ],
                        isDark,
                        theme,
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Preferences',
                        [
                          Obx(
                            () => _buildSwitchTile(
                              Icons.dark_mode_rounded,
                              'Dark Mode',
                              'Switch to dark theme',
                              _themeController.isDarkMode,
                              (value) {
                                _themeController.toggleDarkMode();
                              },
                              isDark,
                              theme,
                            ),
                          ),
                          _buildSwitchTile(
                            Icons.location_on_rounded,
                            'Location Services',
                            'Enable location tracking',
                            _locationEnabled,
                            (value) {
                              setState(() {
                                _locationEnabled = value;
                              });
                            },
                            isDark,
                            theme,
                          ),
                          _buildSettingTile(
                            Icons.language_rounded,
                            'Language',
                            'English (US)',
                            () {},
                            isDark,
                            theme,
                          ),
                        ],
                        isDark,
                        theme,
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Support',
                        [
                          _buildSettingTile(
                            Icons.help_outline_rounded,
                            'Help & Support',
                            'Get help and contact support',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const HelpScreen(),
                                ),
                              );
                            },
                            isDark,
                            theme,
                          ),
                          _buildSettingTile(
                            Icons.info_outline_rounded,
                            'About',
                            'App version and information',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AboutScreen(),
                                ),
                              );
                            },
                            isDark,
                            theme,
                          ),
                          _buildSettingTile(
                            Icons.feedback_rounded,
                            'Send Feedback',
                            'Share your thoughts with us',
                            () {},
                            isDark,
                            theme,
                          ),
                        ],
                        isDark,
                        theme,
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Account Actions',
                        [
                          _buildSettingTile(
                            Icons.logout_rounded,
                            'Logout',
                            'Sign out of your account',
                            () {
                              _showLogoutDialog(context, isDark, theme);
                            },
                            isDark,
                            theme,
                            isDanger: true,
                          ),
                        ],
                        isDark,
                        theme,
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

  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: EnhancedTheme.premiumGradient),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Settings',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<Widget> children,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: EnhancedTheme.softShadow,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    bool isDark,
    ThemeData theme, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isDanger
              ? EnhancedTheme.energyGradient
              : EnhancedTheme.oceanGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDanger
              ? EnhancedTheme.accentRed
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.white60 : Colors.black54,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
    ThemeData theme,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: EnhancedTheme.sunsetGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: EnhancedTheme.primaryIndigo,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Logout',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: EnhancedTheme.accentRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
