import 'package:campus_event_app/core/constants/roles.dart';
import 'package:campus_event_app/core/router/app_router.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:campus_event_app/features/profile/presentation/widgets/settings_card.dart';
import 'package:campus_event_app/shared/widgets/app_dialog.dart';
import 'package:campus_event_app/shared/widgets/header.dart';
import 'package:campus_event_app/shared/widgets/header_delegate.dart';
import 'package:campus_event_app/shared/widgets/role_tag.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final userName = currentUser?.name ?? 'Account';
    final userRole = currentUser?.role;
    final isAdmin = userRole == Roles.faculty || userRole == Roles.superAdmin;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: HeaderDelegate(
              child: Header(
                header: 'Account \nSettings',
                views: const [],
                page: 'settings',
                headerSubtitle: userName,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    const ProfileAvatar(),
                    if (userRole != null) ...[
                      const SizedBox(height: 12),
                      RoleTag(role: userRole),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isAdmin) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Admin',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: SettingsCard(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin Panel',
                  onTap: () => context.push(Routes.admin),
                ),
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2.5),
              child: SettingsCard(
                icon: Icons.person_outline,
                label: 'Edit profile information',
                onTap: () => context.push(Routes.editProfile),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2.5, 16, 10),
              child: SettingsCard(
                icon: Icons.history,
                label: 'View previous registrations',
                onTap: () => context.push(Routes.previousRegistrations),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Application Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: SettingsCard(
                icon: Icons.water_drop_outlined,
                label: 'Choose theme',
                onTap: () => context.push(Routes.theme),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Notification Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: SettingsCard(
                icon: Icons.notifications_outlined,
                label: 'Edit notifications',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.red,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final confirmed = await AppDialog.confirm(
                      context: context,
                      title: 'Sign out',
                      message: 'Are you sure you want to sign out?',
                      confirmLabel: 'Sign out',
                      destructive: true,
                    );
                    if (confirmed && context.mounted) {
                      // The router redirect reacts to the auth status change and
                      // returns to /sign-in, so no manual navigation is needed.
                      context.read<AuthProvider>().signOut();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 22,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Sign out',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
