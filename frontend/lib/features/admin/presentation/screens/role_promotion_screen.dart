import 'dart:async';

import 'package:campus_event_app/core/constants/roles.dart';
import 'package:campus_event_app/features/admin/models/managed_user.dart';
import 'package:campus_event_app/features/admin/providers/role_promotion_provider.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/shared/widgets/app_dialog.dart';
import 'package:campus_event_app/shared/widgets/role_tag.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Role management surface (faculty / super_admin only).
///
/// Shows students and organizers (the only roles with available transitions)
/// and lets the requester promote or demote them per the locked role graph.
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
            'Role Management',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: Center(
          child: Text(
            'You do not have access to this page.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  static const Map<String, int> _roleRank = {
    Roles.guest: 0,
    Roles.student: 1,
    Roles.organizer: 2,
    Roles.faculty: 3,
    Roles.superAdmin: 4,
  };

  bool _isPromotion(String fromRole, String toRole) =>
      (_roleRank[toRole] ?? 0) > (_roleRank[fromRole] ?? 0);

  String _actionLabel(String fromRole, String toRole) =>
      _isPromotion(fromRole, toRole)
          ? 'Promote to ${roleLabel(toRole)}'
          : 'Demote to ${roleLabel(toRole)}';

  Future<void> _onChangeRole(ManagedUser user) async {
    final provider = context.read<RolePromotionProvider>();

    final options = RolePromotionProvider.availableRoleChanges(
      requesterRole: provider.requesterRole,
      currentRole: user.role,
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
        await provider.changeRole(targetUid: user.uid, newRole: targetRole);
    if (!mounted) return;
    AppDialog.info(
      context: context,
      icon: error != null ? Icons.error_outline : Icons.check_circle_outline,
      iconColor: error != null ? Theme.of(context).colorScheme.error : null,
      title: error != null ? 'Role Change Failed' : 'Role Changed',
      message: error ?? '${user.name} is now a ${roleLabel(targetRole)}.',
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
                  "Change ${user.name}'s role",
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final role in options)
                Builder(
                  builder: (_) {
                    final promoting = _isPromotion(user.role, role);
                    final color = promoting ? null : Colors.red.shade700;
                    return ListTile(
                      leading: Icon(
                        promoting ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                      ),
                      title: Text(
                        _actionLabel(user.role, role),
                        style: color == null ? null : TextStyle(color: color),
                      ),
                      onTap: () => Navigator.pop(sheetContext, role),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirm(ManagedUser user, String targetRole) {
    final promoting = _isPromotion(user.role, targetRole);
    return AppDialog.confirm(
      context: context,
      title: promoting ? 'Confirm promotion' : 'Confirm demotion',
      message: '${promoting ? 'Promote' : 'Demote'} ${user.name} '
          '(${roleLabel(user.role)}) to ${roleLabel(targetRole)}?',
      confirmLabel: promoting ? 'Promote' : 'Demote',
      destructive: !promoting,
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
          'Role Management',
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
                onPressed: () => provider.load(search: _searchController.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      case RolePromotionStatus.loaded:
        final users = provider.users;
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users found.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                _UserCard(user: users[index], onManage: _onChangeRole),
          ),
        );
    }
  }
}

class _UserCard extends StatelessWidget {
  final ManagedUser user;
  final Future<void> Function(ManagedUser user) onManage;

  const _UserCard({required this.user, required this.onManage});

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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  RoleTag(role: user.role),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => onManage(user),
              child: const Text('Change role'),
            ),
          ],
        ),
      ),
    );
  }
}
