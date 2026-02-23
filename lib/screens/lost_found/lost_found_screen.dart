import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../core/utils/responsive.dart';
import '../../controllers/lost_found_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/item_model.dart';
import '../../services/supabase_service.dart';
import '../chat/chat_detail_screen.dart';
import 'item_details_screen.dart';
import 'post_lost_found_screen.dart';

class LostFoundScreen extends StatefulWidget {
  final String? filterUserId;
  final String? filterType; // 'lost' or 'found'

  const LostFoundScreen({super.key, this.filterUserId, this.filterType});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  final LostFoundController _controller = Get.put(LostFoundController());

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _controller.searchItems(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.cardGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Header
              _buildSearchHeader(isDark),

              // Content
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_controller.items.isEmpty) {
                    return _buildEmptyState(isDark);
                  }
                  // Apply filters if provided
                  var filteredItems = _controller.items.toList();

                  if (widget.filterUserId != null) {
                    filteredItems = filteredItems
                        .where((item) => item.userId == widget.filterUserId)
                        .toList();
                  }

                  if (widget.filterType != null) {
                    filteredItems = filteredItems
                        .where((item) => item.type == widget.filterType)
                        .toList();
                  }

                  if (filteredItems.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(filteredItems[index], isDark);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingGradientButton(
        icon: Icons.add,
        gradient: AppTheme.accentGradient,
        onPressed: () {
          Get.to(() => const PostLostFoundScreen());
        },
        tooltip: 'Post Item',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    final canPop = Navigator.of(context).canPop();
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
      child: Column(
        children: [
          Row(
            children: [
              if (canPop)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search lost & found items...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  child: const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          if (_showFilters) ...[
            const SizedBox(height: 16),
            // Lost/Found Type Filter
            Obx(
                  () => Row(
                children: [
                  Expanded(
                    child: _buildFilterChip(
                      'All',
                      null,
                      isDark,
                          () {
                        _controller.filterByType(null);
                      },
                      isSelected: _controller.selectedType.value == null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip(
                      'Lost',
                      'lost',
                      isDark,
                          () {
                        _controller.filterByType('lost');
                      },
                      isSelected: _controller.selectedType.value == 'lost',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip(
                      'Found',
                      'found',
                      isDark,
                          () {
                        _controller.filterByType('found');
                      },
                      isSelected: _controller.selectedType.value == 'found',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Category and Color Filters
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Obx(
                            () => DropdownButton<String>(
                          value: _controller.selectedCategory.value,
                          hint: Text(
                            'All Categories',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          isExpanded: true,
                          items:
                          [
                            null,
                            'Electronics',
                            'Books',
                            'Clothing',
                            'ID/Card',
                            'Accessories',
                          ].map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category ?? 'All Categories',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            _controller.filterByCategory(value);
                          },
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Obx(
                            () => DropdownButton<String>(
                          value: _controller.selectedColor.value,
                          hint: Text(
                            'All Colors',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          isExpanded: true,
                          items:
                          [
                            null,
                            'Black',
                            'White',
                            'Blue',
                            'Red',
                            'Green',
                            'Yellow',
                            'Gray',
                          ].map((color) {
                            return DropdownMenuItem(
                              value: color,
                              child: Text(
                                color ?? 'All Colors',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            _controller.filterByColor(value);
                          },
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Location Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: Obx(
                      () => DropdownButton<String>(
                    value: _controller.selectedLocation.value,
                    hint: Text(
                      'All Locations',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    isExpanded: true,
                    items:
                    [
                      null,
                      'Congo',
                      'Volta',
                      'Admin Block',
                      'Ubangi',
                      'Block A',
                    ].map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(
                          location ?? 'All Locations',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _controller.filterByLocation(value);
                    },
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Date Filter
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _controller.selectedDate.value ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _controller.filterByDate(date);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Obx(
                          () => Text(
                        _controller.selectedDate.value != null
                            ? '${_controller.selectedDate.value!.day}/${_controller.selectedDate.value!.month}/${_controller.selectedDate.value!.year}'
                            : 'Select Date',
                        style: TextStyle(
                          color: _controller.selectedDate.value != null
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_controller.selectedDate.value != null)
                      GestureDetector(
                        onTap: () {
                          _controller.filterByDate(null);
                        },
                        child: Icon(
                          Icons.clear,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemModel item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.imageUrl != null
                    ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.type == 'lost'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.type == 'lost' ? 'Lost' : 'Found',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.type == 'lost'
                                ? Colors.red[700]
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (item.location != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  if (item.location != null) const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      if (item.color.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.palette,
                          size: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.color,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (item.userId !=
                          SupabaseService.client.auth.currentUser?.id)
                        Expanded(
                          child: GradientButton(
                            text: 'Contact',
                            gradient: AppTheme.primaryGradient,
                            onPressed: () async {
                              final chatController = Get.find<ChatController>();
                              final conversationId = await chatController
                                  .getOrCreateConversation(item.userId);

                              if (conversationId != null && mounted) {
                                // Get other user's name and avatar
                                final profilesResponse = await SupabaseService
                                    .client
                                    .from('user_profiles')
                                    .select('full_name, avatar_url')
                                    .eq('id', item.userId)
                                    .maybeSingle();

                                Get.to(
                                      () => ChatDetailScreen(
                                    conversationId: conversationId,
                                    otherUserId: item.userId,
                                    otherUserName:
                                    profilesResponse?['full_name'] ??
                                        item.userName,
                                    otherUserAvatar:
                                    profilesResponse?['avatar_url'],
                                  ),
                                );
                              } else if (mounted) {
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
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.getSpacing(
                                context,
                                mobile: 8,
                              ),
                            ),
                          ),
                        ),
                      if (item.userId !=
                          SupabaseService.client.auth.currentUser?.id)
                        const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => ItemDetailsScreen(item: item));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label,
      String? value,
      bool isDark,
      VoidCallback onTap, {
        required bool isSelected,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPurple
                : (isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
