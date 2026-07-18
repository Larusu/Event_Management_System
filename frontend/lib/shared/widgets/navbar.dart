import "package:flutter/material.dart";

class NavBar extends StatelessWidget {
  final int selectedPageIndex;
  final ValueChanged<int> onPageSelected;

  /// When true, an extra faculty/super_admin-only management tab is appended
  /// as the last item. Its index must line up with the pages list in
  /// [MainShell].
  final bool isAdmin;

  const NavBar(
      {super.key,
      required this.selectedPageIndex,
      required this.onPageSelected,
      this.isAdmin = false});

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
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              label: '',
            ),
        ]);
  }
}
