import "package:flutter/material.dart";

class NavBar extends StatelessWidget {
  final int selectedPageIndex;
  final ValueChanged<int> onPageSelected;
  final bool showCreatedEvents;

  const NavBar({
    super.key,
    required this.selectedPageIndex,
    required this.onPageSelected,
    this.showCreatedEvents = true,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        backgroundColor: const Color(0xFF00364D),
        currentIndex: selectedPageIndex,
        onTap: onPageSelected,
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.white,
        selectedItemColor: Colors.white,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: '',
          ),
          if (showCreatedEvents)
            const BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              label: '',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '',
          ),
        ]);
  }
}
