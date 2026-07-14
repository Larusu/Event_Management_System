import 'package:campus_event_app/features/auth/presentation/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/roles.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuest =
        context.watch<AuthProvider>().currentUser?.role == Roles.guest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isGuest)
              Container(
                width: double.infinity,
                color: Colors.amber.shade100,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  "You're browsing as a guest.",
                  textAlign: TextAlign.center,
                ),
              ),
            const Expanded(
              child: Center(child: Text('This is the home screen')),
            ),
          ],
        ),
      ),
    );
  }
}
