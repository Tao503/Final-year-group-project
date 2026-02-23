import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              // Header
              _buildHeader(isDark, theme),
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: EnhancedTheme.primaryIndigo,
                unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                indicatorColor: EnhancedTheme.primaryIndigo,
                tabs: const [
                  Tab(text: 'Lost & Found'),
                  Tab(text: 'Donations'),
                  Tab(text: 'Events'),
                ],
              ),
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSavedLostFound(isDark, theme),
                    _buildSavedDonations(isDark, theme),
                    _buildSavedEvents(isDark, theme),
                  ],
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
              'Saved Items',
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

  Widget _buildSavedLostFound(bool isDark, ThemeData theme) {
    return _buildEmptyState('No saved lost & found items', isDark, theme);
  }

  Widget _buildSavedDonations(bool isDark, ThemeData theme) {
    return _buildEmptyState('No saved donations', isDark, theme);
  }

  Widget _buildSavedEvents(bool isDark, ThemeData theme) {
    return _buildEmptyState('No saved events', isDark, theme);
  }

  Widget _buildEmptyState(String message, bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 80,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
