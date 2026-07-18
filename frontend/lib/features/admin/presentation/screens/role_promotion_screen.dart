import 'package:campus_event_app/core/constants/roles.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Role promotion surface (faculty / super_admin only).
///
/// Phase 1 placeholder — the searchable user list and promote flow are wired
/// up in Phase 2 against GET /users and PATCH /users/{targetUID}/role.
class RolePromotionScreen extends StatelessWidget {
  const RolePromotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final isAdmin = role == Roles.faculty || role == Roles.superAdmin;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Role Promotion',
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
