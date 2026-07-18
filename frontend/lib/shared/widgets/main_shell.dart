import 'package:campus_event_app/features/admin/presentation/screens/admin_landing_screen.dart';
import 'package:campus_event_app/features/events/presentation/screens/create_event.dart';
import 'package:campus_event_app/features/events/presentation/screens/events_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../../../core/constants/roles.dart';
import '../../features/events/presentation/screens/calendar.dart';
import '../../features/events/presentation/screens/dashboard.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import 'navbar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedPageIndex = 1;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final isGuest = role == Roles.guest;
    final isAdmin = role == Roles.faculty || role == Roles.superAdmin;

    // The admin tab is appended last so the fixed indices 0-3 (and the
    // Events FAB check below) stay stable for every role.
    final pages = <Widget>[
      const CalendarPage(),
      const DashboardPage(),
      const EventsScreen(),
      const SettingsScreen(),
      if (isAdmin) const AdminLandingScreen(),
    ];

    // Guard against a role change (e.g. demotion) leaving the admin tab
    // selected after it disappears from the shell.
    final safeIndex =
        _selectedPageIndex < pages.length ? _selectedPageIndex : 1;

    return Scaffold(
      bottomNavigationBar: NavBar(
        selectedPageIndex: safeIndex,
        isAdmin: isAdmin,
        onPageSelected: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
      ),
      floatingActionButton: safeIndex == 2 && !isGuest
          ? FloatingActionButton(
              onPressed: () => createNewEvent(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
    );
  }
}
