import 'package:campus_event_app/core/constants/roles.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Event approval / review queue (faculty / super_admin only).
///
/// Phase 1 placeholder — the pending-events list and approve/reject flow are
/// wired up in Phase 3 (after merging the moderation endpoints from `dev`).
class EventApprovalScreen extends StatelessWidget {
  const EventApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final isAdmin = role == Roles.faculty || role == Roles.superAdmin;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Event Approvals',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: Center(
        child: Text(
          isAdmin ? 'Coming soon' : 'You do not have access to this page.',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
