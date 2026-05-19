import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';
import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import '../../services/supabase_service.dart';
import 'event_details_screen.dart';

class EventsMyEventsScreen extends StatefulWidget {
  const EventsMyEventsScreen({super.key});

  @override
  State<EventsMyEventsScreen> createState() => _EventsMyEventsScreenState();
}

class _EventsMyEventsScreenState extends State<EventsMyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventController _controller = Get.find<EventController>();
  final _supabase = SupabaseService.client;

  
  List<EventModel> get _createdEvents {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    return _controller.events.where((e) => e.userId == userId).toList();
  }

  
  final RxList<EventModel> _registeredEventsList = <EventModel>[].obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRegisteredEvents();
  }

  Future<void> _loadRegisteredEvents() async {
    final registeredIds = await _controller.getRegisteredEventIds();
    _registeredEventsList.value = _controller.events
        .where((e) => registeredIds.contains(e.id))
        .toList();
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

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.darkGradient : AppTheme.cardGradient,
      ),
      child: Column(
        children: [
          
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: EnhancedTheme.premiumGradient,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Events',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your events',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Registered'),
                      Tab(text: 'Created'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Obx(() {
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadRegisteredEvents();
              });
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildRegisteredEvents(isDark, theme),
                  _buildCreatedEvents(isDark, theme),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredEvents(bool isDark, ThemeData theme) {
    return Obx(() {
      if (_registeredEventsList.isEmpty) {
        return _buildEmptyState('No registered events', isDark, theme);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _registeredEventsList.length,
        itemBuilder: (context, index) {
          return _buildEventCard(
            _registeredEventsList[index],
            isDark,
            theme,
            true,
          );
        },
      );
    });
  }

  Widget _buildCreatedEvents(bool isDark, ThemeData theme) {
    if (_createdEvents.isEmpty) {
      return _buildEmptyState('No created events', isDark, theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _createdEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(_createdEvents[index], isDark, theme, false);
      },
    );
  }

  Widget _buildEventCard(
    EventModel event,
    bool isDark,
    ThemeData theme,
    bool isRegistered,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: EnhancedTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventDetailsScreen(event: event),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[300],
                  ),
                  child: event.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.event),
                              );
                            },
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.event),
                        ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: isRegistered
                                  ? EnhancedTheme.successGradient
                                  : EnhancedTheme.oceanGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isRegistered ? 'Registered' : 'Created',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(event.eventDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_rounded,
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
    return '${months[date.month - 1]} ${date.day} • $hour:$minute $amPm';
  }
}
