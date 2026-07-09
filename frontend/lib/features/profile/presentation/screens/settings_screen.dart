import 'package:campus_event_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:campus_event_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:campus_event_app/features/profile/presentation/widgets/settings_card.dart';
import 'package:campus_event_app/shared/widgets/header.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(
                  header: 'Account \nSettings',
                  views: const [],
                  page: 'settings'),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 30),
                child: const Center(
                  child: ProfileAvatar(),
                ),
              ),
              Padding(
                padding:
                    EdgeInsetsGeometry.symmetric(vertical: 20, horizontal: 20),
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
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                child: Text(
                  'Application Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.start,
                ),
              ),
              Padding(
                padding:
                    EdgeInsetsGeometry.symmetric(vertical: 10, horizontal: 20),
                child: SettingsCard(
                  icon: Icons.water_drop_outlined,
                  label: 'Choose theme',
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                child: Text(
                  'Notification Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.start,
                ),
              ),
              Padding(
                padding:
                    EdgeInsetsGeometry.symmetric(vertical: 10, horizontal: 20),
                child: SettingsCard(
                    icon: Icons.notifications_outlined,
                    label: 'Edit notifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
