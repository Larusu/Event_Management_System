import 'package:campus_event_app/core/router/app_router.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/features/profile/presentation/widgets/settings_card.dart';
import 'package:campus_event_app/shared/widgets/header.dart';
import 'package:campus_event_app/shared/widgets/header_delegate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Faculty / super_admin management hub. Acts as a landing menu that routes
/// into the moderation and role-management surfaces (built in later phases).
class AdminLandingScreen extends StatelessWidget {
  const AdminLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName =
        context.watch<AuthProvider>().currentUser?.name ?? 'Account';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: HeaderDelegate(
                child: Header(
                  header: 'Admin \nPanel',
                  views: const [],
                  page: 'settings',
                  headerSubtitle: userName,
                  onBack: () => context.pop(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: SettingsCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Event Approvals',
                  onTap: () => context.push(Routes.adminApprovals),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: SettingsCard(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Role Management',
                  onTap: () => context.push(Routes.adminRoles),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
