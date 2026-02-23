import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
              // Header
              _buildHeader(context, isDark, theme),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // FAQ Section
                      _buildSection(
                        'Frequently Asked Questions',
                        [
                          _buildFAQItem(
                            'How do I report a lost item?',
                            'Go to Lost & Found section, tap the + button, select "Lost Item", fill in the details and submit.',
                            isDark,
                            theme,
                          ),
                          _buildFAQItem(
                            'How do I request a donation?',
                            'Browse donations, tap on an item, and click "Request This Item" to send a request to the donor.',
                            isDark,
                            theme,
                          ),
                          _buildFAQItem(
                            'How do I create an event?',
                            'Toggle to Events mode from home, tap "Create Event", fill in the details and publish.',
                            isDark,
                            theme,
                          ),
                        ],
                        isDark,
                        theme,
                      ),
                      const SizedBox(height: 24),
                      // Contact Section
                      _buildSection(
                        'Contact Support',
                        [
                          _buildContactTile(
                            Icons.email_rounded,
                            'Email',
                            'support@nileconnect.edu',
                            () {},
                            isDark,
                            theme,
                          ),
                          _buildContactTile(
                            Icons.phone_rounded,
                            'Phone',
                            '+234 123 456 7890',
                            () {},
                            isDark,
                            theme,
                          ),
                          _buildContactTile(
                            Icons.chat_bubble_rounded,
                            'Live Chat',
                            'Available 24/7',
                            () {},
                            isDark,
                            theme,
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

  Widget _buildHeader(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: EnhancedTheme.premiumGradient,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Help & Support',
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
              color: isDark ? Colors.white : Colors.black87,
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

  Widget _buildFAQItem(
    String question,
    String answer,
    bool isDark,
    ThemeData theme,
  ) {
    return ExpansionTile(
      title: Text(
        question,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.6,
            ),
          ),
        ),
      ],
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildContactTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    bool isDark,
    ThemeData theme,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: EnhancedTheme.oceanGradient,
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
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.white60 : Colors.black54,
      ),
      onTap: onTap,
    );
  }
}

