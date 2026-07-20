import 'package:campus_event_app/features/events/presentation/screens/create_event.dart';
import 'package:campus_event_app/features/events/presentation/screens/events_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../../../core/constants/roles.dart';
import '../../features/events/presentation/screens/calendar.dart';
import '../../features/events/presentation/screens/created_events_screen.dart';
import '../../features/events/presentation/screens/dashboard.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import 'navbar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  _ShellDestination _selectedDestination = _ShellDestination.dashboard;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final isGuest = role == Roles.guest;
    final showCreatedEvents = role != Roles.student;

    final destinations = <(_ShellDestination, Widget)>[
      (_ShellDestination.calendar, const CalendarPage()),
      if (showCreatedEvents)
        (_ShellDestination.createdEvents, const CreatedEventsScreen()),
      (_ShellDestination.dashboard, const DashboardPage()),
      (_ShellDestination.events, const EventsScreen()),
      (_ShellDestination.settings, const SettingsScreen()),
    ];

    final selectedIndex = destinations.indexWhere(
      (entry) => entry.$1 == _selectedDestination,
    );
    final safeIndex = selectedIndex < 0
        ? destinations.indexWhere(
            (entry) => entry.$1 == _ShellDestination.dashboard,
          )
        : selectedIndex;

    return Scaffold(
      bottomNavigationBar: NavBar(
        selectedPageIndex: safeIndex,
        showCreatedEvents: showCreatedEvents,
        onPageSelected: (index) {
          setState(() {
            _selectedDestination = destinations[index].$1;
          });
        },
      ),
      floatingActionButton:
          destinations[safeIndex].$1 == _ShellDestination.events && !isGuest
              ? FloatingActionButton(
                  onPressed: () => createNewEvent(context),
                  child: const Icon(Icons.add),
                )
              : null,
      body: IndexedStack(
        index: safeIndex,
        children: destinations.map((entry) => entry.$2).toList(),
      ),
    );
  }
}

enum _ShellDestination { calendar, createdEvents, dashboard, events, settings }
