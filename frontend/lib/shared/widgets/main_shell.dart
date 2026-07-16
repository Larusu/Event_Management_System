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

  final List<Widget> _pages = const [
    CalendarPage(),
    DashboardPage(),
    EventsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isGuest =
        context.watch<AuthProvider>().currentUser?.role == Roles.guest;

    return Scaffold(
      bottomNavigationBar: NavBar(
        selectedPageIndex: _selectedPageIndex,
        onPageSelected: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
      ),
      floatingActionButton: _selectedPageIndex == 2 && !isGuest
          ? FloatingActionButton(
              onPressed: () => createNewEvent(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: IndexedStack(
        index: _selectedPageIndex,
        children: _pages,
      ),
    );
  }
}
