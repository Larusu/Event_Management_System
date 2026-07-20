import 'package:campus_event_app/features/admin/presentation/screens/event_approval_screen.dart';
import 'package:campus_event_app/features/admin/presentation/screens/role_promotion_screen.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/features/profile/presentation/widgets/settings_card.dart';
import 'package:campus_event_app/shared/widgets/header.dart';
import 'package:campus_event_app/shared/widgets/header_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Faculty / super_admin management hub. Acts as a landing menu that routes
/// into the moderation and role-management surfaces (built in later phases).
class AdminLandingScreen extends StatelessWidget {
  const AdminLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName =
        context.watch<AuthProvider>().currentUser?.name ?? 'Account';

    return SafeArea(
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
                onBack: () => Navigator.pop(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: SettingsCard(
                icon: Icons.fact_check_outlined,
                label: 'Event Approvals',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventApprovalScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: SettingsCard(
                icon: Icons.manage_accounts_outlined,
                label: 'Role Management',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RolePromotionScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
