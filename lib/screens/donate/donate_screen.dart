import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../core/utils/responsive.dart';
import '../../controllers/donation_controller.dart';
import '../../models/donation_model.dart';
import 'post_donation_screen.dart';
import 'donation_details_screen.dart';

class DonateScreen extends StatefulWidget {
  final String? filterUserId;

  const DonateScreen({super.key, this.filterUserId});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final DonationController _controller = Get.put(DonationController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _controller.searchDonations(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              
              _buildHeader(isDark),

              
              _buildSearchAndFilters(isDark),

              
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var donationsToShow = <DonationModel>[
                    ...(_controller.searchQuery.value.isNotEmpty ||
                        _controller.selectedCategory.value != 'All' ||
                        _controller.selectedStatus.value != 'All'
                        ? _controller.filteredDonations
                        : _controller.donations),
                  ];

                  
                  if (widget.filterUserId != null) {
                    donationsToShow = donationsToShow
                        .where(
                          (donation) => donation.userId == widget.filterUserId,
                    )
                        .toList();
                  }

                  if (donationsToShow.isEmpty) {
                    return _buildEmptyState(isDark);
                  }
                  return GridView.builder(
                    padding: Responsive.getPadding(context),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.getGridCrossAxisCount(
                        context,
                        mobile: 2,
                        tablet: 3,
                        desktop: 4,
                      ),
                      crossAxisSpacing: Responsive.getSpacing(
                        context,
                        mobile: 16,
                      ),
                      mainAxisSpacing: Responsive.getSpacing(
                        context,
                        mobile: 16,
                      ),
                      childAspectRatio: Responsive.isMobile(context)
                          ? 0.75
                          : 0.8,
                    ),
                    itemCount: donationsToShow.length,
                    itemBuilder: (context, index) {
                      return _buildDonationCard(donationsToShow[index], isDark);
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
          Get.to(() => const PostDonationScreen());
        },
        tooltip: 'Post Donation',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(bool isDark) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Text(
                  'Donations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Give what you don't need",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        children: [
          
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search donations...',
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  _searchController.clear();
                  _controller.searchDonations('');
                },
              )
                  : null,
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),

          const SizedBox(height: 12),

          
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'All', isDark, () {
                        _controller.filterByCategory('All');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('General', 'General', isDark, () {
                        _controller.filterByCategory('General');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Library/Students',
                        'Library/Students',
                        isDark,
                            () {
                          _controller.filterByCategory('Library/Students');
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Orphanage', 'Orphanage', isDark, () {
                        _controller.filterByCategory('Orphanage');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'IT Department',
                        'IT Department or Lab',
                        isDark,
                            () {
                          _controller.filterByCategory('IT Department or Lab');
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Food Bank', 'Food Bank', isDark, () {
                        _controller.filterByCategory('Food Bank');
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          
          Row(
            children: [
              _buildFilterChip('All Status', 'All', isDark, () {
                _controller.filterByStatus('All');
              }, isStatus: true),
              const SizedBox(width: 8),
              _buildFilterChip('Available', 'available', isDark, () {
                _controller.filterByStatus('available');
              }, isStatus: true),
              const SizedBox(width: 8),
              _buildFilterChip('Claimed', 'claimed', isDark, () {
                _controller.filterByStatus('claimed');
              }, isStatus: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label,
      String value,
      bool isDark,
      VoidCallback onTap, {
        bool isStatus = false,
      }) {
    return Obx(() {
      final isSelected = isStatus
          ? _controller.selectedStatus.value == value
          : _controller.selectedCategory.value == value;

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryPurple
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryPurple
                  : (isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey[300]!),
            ),
          ),
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
      );
    });
  }

  Widget _buildDonationCard(DonationModel item, bool isDark) {
    return GestureDetector(
      onTap: () {
        Get.to(() => DonationDetailsScreen(donation: item));
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: item.imageUrl != null
                    ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 48),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 48),
                ),
              ),
            ),
            
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.status == 'available'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.status == 'available'
                                    ? 'Available'
                                    : 'Claimed',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: item.status == 'available'
                                      ? Colors.green[700]
                                      : Colors.amber[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.recommendedCategory ?? 'General',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.to(() => DonationDetailsScreen(donation: item));
                          },
                          child: Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
            Icons.card_giftcard_outlined,
            size: 64,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No donations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to donate!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
