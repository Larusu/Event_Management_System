import 'dart:async';

import 'package:campus_event_app/core/constants/roles.dart';
import 'package:campus_event_app/features/admin/models/managed_user.dart';
import 'package:campus_event_app/features/admin/providers/role_promotion_provider.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/shared/widgets/role_tag.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Role promotion surface (faculty / super_admin only).
///
/// Faculty sees students and can promote them to organizer. Super_admin sees
/// students, guests, and organizers, and can promote to organizer or faculty.
class RolePromotionScreen extends StatelessWidget {
  const RolePromotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final isAdmin = role == Roles.faculty || role == Roles.superAdmin;

    if (!isAdmin || role == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Role Promotion',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: const Center(
          child: Text(
            'You do not have access to this page.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => RolePromotionProvider(requesterRole: role)..load(),
      child: const _RolePromotionView(),
    );
  }
}

class _RolePromotionView extends StatefulWidget {
  const _RolePromotionView();

  @override
  State<_RolePromotionView> createState() => _RolePromotionViewState();
}

class _RolePromotionViewState extends State<_RolePromotionView> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<RolePromotionProvider>().load(search: value);
    });
  }

  Future<void> _onPromote(ManagedUser user) async {
    final provider = context.read<RolePromotionProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final options = RolePromotionProvider.assignableRoles(
      requesterRole: provider.requesterRole,
      targetRole: user.role,
    );
    if (options.isEmpty) return;

    String targetRole;
    if (options.length == 1) {
      targetRole = options.first;
    } else {
      final picked = await _pickRole(user, options);
      if (!mounted || picked == null) return;
      targetRole = picked;
    }

    final confirmed = await _confirm(user, targetRole);
    if (!mounted || confirmed != true) return;

    final error =
        await provider.promote(targetUid: user.uid, newRole: targetRole);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? '${user.name} is now a ${roleLabel(targetRole)}.',
        ),
        backgroundColor: error != null ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<String?> _pickRole(ManagedUser user, List<String> options) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Promote ${user.name} to…',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final role in options)
                ListTile(
                  leading: const Icon(Icons.arrow_upward),
                  title: Text(roleLabel(role)),
                  onTap: () => Navigator.pop(sheetContext, role),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirm(ManagedUser user, String targetRole) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm promotion'),
          content: Text(
            'Promote ${user.name} (${roleLabel(user.role)}) to '
            '${roleLabel(targetRole)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Promote'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RolePromotionProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Role Promotion',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(RolePromotionProvider provider) {
    switch (provider.status) {
      case RolePromotionStatus.idle:
      case RolePromotionStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case RolePromotionStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.errorMessage ?? 'Something went wrong.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    provider.load(search: _searchController.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      case RolePromotionStatus.loaded:
        final users = provider.users;
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'No users found.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => provider.load(search: _searchController.text),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _UserCard(user: users[index], onPromote: _onPromote),
          ),
        );
    }
  }
}

class _UserCard extends StatelessWidget {
  final ManagedUser user;
  final Future<void> Function(ManagedUser user) onPromote;

  const _UserCard({required this.user, required this.onPromote});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  RoleTag(role: user.role),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: () => onPromote(user),
              child: const Text('Promote'),
            ),
          ],
        ),
      ),
    );
  }
}
