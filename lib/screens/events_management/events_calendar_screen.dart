import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';
import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import 'event_details_screen.dart';

class EventsCalendarScreen extends StatefulWidget {
  const EventsCalendarScreen({super.key});

  @override
  State<EventsCalendarScreen> createState() => _EventsCalendarScreenState();
}

class _EventsCalendarScreenState extends State<EventsCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  final EventController _controller = Get.find<EventController>();

  // Group events by date from controller
  Map<DateTime, List<EventModel>> get _eventsByDate {
    final events = <DateTime, List<EventModel>>{};

    for (var event in _controller.events) {
      final eventDate = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );

      if (!events.containsKey(eventDate)) {
        events[eventDate] = [];
      }
      events[eventDate]!.add(event);
    }

    return events;
  }

  List<EventModel> get _selectedDateEvents {
    final key = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return _eventsByDate[key] ?? [];
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
          // Header (starts from top)
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: EnhancedTheme.premiumGradient,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calendar',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedDateEvents.length} events on ${_formatDateHeader(_selectedDate)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Calendar Widget
          Expanded(
            child: MediaQuery.of(context).size.width > 600
                ? Row(
                    children: [
                      // Calendar
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: EnhancedTheme.softShadow,
                          ),
                          child: _buildCalendar(isDark, theme),
                        ),
                      ),
                      // Events List
                      Expanded(
                        flex: 3,
                        child: Obx(
                          () => _selectedDateEvents.isEmpty
                              ? _buildEmptyState(isDark, theme)
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _selectedDateEvents.length,
                                  itemBuilder: (context, index) {
                                    return _buildEventCard(
                                      _selectedDateEvents[index],
                                      isDark,
                                      theme,
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: EnhancedTheme.softShadow,
                          ),
                          child: _buildCalendar(isDark, theme),
                        ),
                        Obx(() {
                          if (_selectedDateEvents.isNotEmpty) {
                            return Column(
                              children: _selectedDateEvents.map((event) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: _buildEventCard(event, isDark, theme),
                                );
                              }).toList(),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: _buildEmptyState(isDark, theme),
                            );
                          }
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                    );
                  });
                },
                color: isDark ? Colors.white : Colors.black87,
              ),
              Text(
                _formatMonthYear(_selectedDate),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                    );
                  });
                },
                color: isDark ? Colors.white : Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Week Days
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Calendar Days - Use SizedBox with fixed height instead of Expanded
          SizedBox(height: 280, child: _buildCalendarDays(isDark, theme)),
        ],
      ),
    );
  }

  Widget _buildCalendarDays(bool isDark, ThemeData theme) {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: firstWeekday - 1 + daysInMonth,
      itemBuilder: (context, index) {
        if (index < firstWeekday - 1) {
          return const SizedBox();
        }
        final day = index - firstWeekday + 2;
        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final isSelected =
            date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final hasEvents = _eventsByDate.containsKey(
          DateTime(date.year, date.month, date.day),
        );
        final isToday =
            date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? EnhancedTheme.premiumGradient
                  : (isToday
                        ? LinearGradient(
                            colors: [
                              EnhancedTheme.primaryIndigo.withOpacity(0.2),
                              EnhancedTheme.primaryIndigo.withOpacity(0.1),
                            ],
                          )
                        : null),
              color: isSelected
                  ? null
                  : (isToday
                        ? null
                        : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[100])),
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected
                  ? Border.all(color: EnhancedTheme.primaryIndigo, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                if (hasEvents)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : EnhancedTheme.primaryIndigo,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(EventModel event, bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: EnhancedTheme.oceanGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        event.endDate != null
                            ? '${event.endDate!.hour.toString().padLeft(2, '0')}:${event.endDate!.minute.toString().padLeft(2, '0')}'
                            : 'All day',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
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

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 80,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 24),
          Text(
            'No events on this day',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
