import 'package:flutter/material.dart';

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
    Center(child: Text('Menu')),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavBar(
        selectedPageIndex: _selectedPageIndex,
        onPageSelected: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
      ),
      body: IndexedStack(
        index: _selectedPageIndex,
        children: _pages,
      ),
    );
  }
}
