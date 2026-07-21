import 'package:campus_event_app/features/events/presentation/screens/create_event.dart';
import 'package:campus_event_app/features/events/providers/created_events_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../../../core/constants/roles.dart';
import 'navbar.dart';

/// Persistent shell hosting the bottom navigation. [navigationShell] is an
/// IndexedStack under the hood, so each tab keeps its state when switching.
///
/// The router always defines all five branches (see app_router.dart); the
/// Created Events branch only surfaces a navbar tab for organizers and up, so
/// the visible navbar items are mapped onto the fixed branch indices here.
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Fixed branch indices as declared in the StatefulShellRoute.
  static const int _calendarBranch = 0;
  static const int _createdEventsBranch = 1;
  static const int _dashboardBranch = 2;
  static const int _eventsBranch = 3;

  // Ensures the owned-events list is warmed only once per shell lifetime.
  bool _warmedOwnedEvents = false;

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final role = context.watch<AuthProvider>().currentUser?.role;
    // Only organizers and up may create events (and therefore see the Created
    // Events tab and the create-event FAB); students and guests cannot.
    final canManageEvents = role == Roles.organizer ||
        role == Roles.faculty ||
        role == Roles.superAdmin;
    final showCreatedEvents = canManageEvents;

    // Warm the owned-events list once so the Event Modal can flag the user's own
    // events from any tab (browse/dashboard/calendar), not just after visiting
    // the Created Events screen.
    if (canManageEvents && !_warmedOwnedEvents) {
      _warmedOwnedEvents = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<CreatedEventsProvider>().ensureLoaded();
      });
    }

    // Branch indices that have a navbar tab, in display order. Created Events
    // is only present for organizers and up.
    final visibleBranches = <int>[
      _calendarBranch,
      if (showCreatedEvents) _createdEventsBranch,
      _dashboardBranch,
      _eventsBranch,
      4, // settings
    ];

    final currentBranch = navigationShell.currentIndex;
    var selectedNavIndex = visibleBranches.indexOf(currentBranch);
    if (selectedNavIndex < 0) {
      // Current branch has no visible tab (e.g. a role change hid it): fall
      // back to the dashboard tab.
      selectedNavIndex = visibleBranches.indexOf(_dashboardBranch);
    }

    return Scaffold(
      bottomNavigationBar: NavBar(
        selectedPageIndex: selectedNavIndex,
        showCreatedEvents: showCreatedEvents,
        onPageSelected: (navIndex) {
          final targetBranch = visibleBranches[navIndex];
          navigationShell.goBranch(
            targetBranch,
            // Re-tapping the current tab pops it back to its initial route.
            initialLocation: targetBranch == navigationShell.currentIndex,
          );
        },
      ),
      floatingActionButton: currentBranch == _eventsBranch && canManageEvents
          ? FloatingActionButton(
              onPressed: () => createNewEvent(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: navigationShell,
    );
  }
}
