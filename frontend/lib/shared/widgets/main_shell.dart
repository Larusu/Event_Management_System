import 'package:campus_event_app/features/events/presentation/screens/create_event.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../../../core/constants/roles.dart';
import 'navbar.dart';

/// Persistent shell hosting the bottom navigation. The [navigationShell] is an
/// IndexedStack under the hood, so each tab keeps its state when switching.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final isGuest = role == Roles.guest;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      bottomNavigationBar: NavBar(
        selectedPageIndex: currentIndex,
        onPageSelected: (index) => navigationShell.goBranch(
          index,
          // Re-tapping the current tab pops it back to its initial route.
          initialLocation: index == currentIndex,
        ),
      ),
      floatingActionButton: currentIndex == 2 && !isGuest
          ? FloatingActionButton(
              onPressed: () => createNewEvent(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: navigationShell,
    );
  }
}
