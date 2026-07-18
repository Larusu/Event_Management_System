import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:campus_event_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:campus_event_app/features/profile/presentation/widgets/settings_card.dart';
import 'package:campus_event_app/shared/widgets/header.dart';
import 'package:campus_event_app/shared/widgets/header_delegate.dart';
import 'package:campus_event_app/shared/widgets/role_tag.dart';
import 'package:flutter/material.dart';
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SettingsCard(
                icon: Icons.person_outline,
                label: 'Edit profile information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfileScreen()),
                  );
                },
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
                color: Colors.red.shade50,
                child: InkWell(
                  onTap: () {
                    context.read<AuthProvider>().signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.logout,
                            size: 22, color: Colors.red.shade700),
                        const SizedBox(width: 16),
                        Text(
                          'Sign out',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500),
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
