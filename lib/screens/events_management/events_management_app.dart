import 'package:flutter/material.dart';
import '../../core/theme/enhanced_theme.dart';
import 'events_home_screen.dart';
import 'events_calendar_screen.dart';
import 'events_create_screen.dart';
import 'events_my_events_screen.dart';
import 'events_explore_screen.dart';

/// Standalone Events Management App
class EventsManagementApp extends StatefulWidget {
  const EventsManagementApp({super.key});

  @override
  State<EventsManagementApp> createState() => _EventsManagementAppState();
}

class _EventsManagementAppState extends State<EventsManagementApp> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _navBarItems;

  @override
  void initState() {
    super.initState();
    _screens = [
      EventsHomeScreen(
        key: const ValueKey('events_home'),
        onBack: () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      const EventsExploreScreen(key: ValueKey('events_explore')),
      const EventsCalendarScreen(key: ValueKey('events_calendar')),
      const EventsMyEventsScreen(key: ValueKey('events_my_events')),
    ];
    _navBarItems = _createNavBarItems();
  }

  List<BottomNavigationBarItem> _createNavBarItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore_rounded),
        label: 'Explore',
      ),
      BottomNavigationBarItem(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: EnhancedTheme.premiumGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        ),
        label: 'Create',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month_rounded),
        label: 'Calendar',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event_note_outlined),
        activeIcon: Icon(Icons.event_note_rounded),
        label: 'My Events',
      ),
    ];
  }

  // Map screen index to nav bar index (accounting for Create button at index 2)
  int _getNavBarIndex(int screenIndex) {
    // Screen indices: 0=Home, 1=Explore, 2=Calendar, 3=MyEvents
    // Nav bar indices: 0=Home, 1=Explore, 2=Create, 3=Calendar, 4=MyEvents
    return screenIndex < 2 ? screenIndex : screenIndex + 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navIndex = _getNavBarIndex(_currentIndex);

    return Scaffold(
      body: IndexedStack(
        key: const ValueKey('events_indexed_stack'),
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: const ValueKey('events_bottom_nav'),
        currentIndex: navIndex,
        onTap: (index) {
          if (index == 2) {
            // Create Event button - navigate but don't change currentIndex
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EventsCreateScreen(),
              ),
            );
          } else {
            // Map nav bar indices to screen indices
            // Nav: 0=Home, 1=Explore, 2=Create, 3=Calendar, 4=MyEvents
            // Screen: 0=Home, 1=Explore, 2=Calendar, 3=MyEvents
            int screenIndex = index < 2 ? index : index - 1;
            if (mounted) {
              setState(() {
                _currentIndex = screenIndex;
              });
            }
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        selectedItemColor: EnhancedTheme.primaryIndigo,
        unselectedItemColor: isDark ? Colors.white60 : Colors.black54,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: _navBarItems,
      ),
    );
  }
}

