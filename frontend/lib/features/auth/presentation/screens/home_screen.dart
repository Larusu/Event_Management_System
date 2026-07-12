import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/roles.dart';
import '../../../events/presentation/widgets/event_modal.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuest =
        context.watch<AuthProvider>().currentUser?.role == Roles.guest;

    return Scaffold(
      // TEMP: preview trigger for the Event Modal design.
      // TODO(cleanup): if the design is already implemented (Dev A/B wire real
      // event-card taps to EventModal.show), please remove this button and the
      // _showPlaceholderNote dialog below.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlaceholderNote(context),
        label: const Text('View Event'),
        icon: const Icon(Icons.event),
      ),
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

  // TEMP: placeholder note shown before the Event Modal preview.
  // TODO(cleanup): remove together with the "View Event" button once the
  // design is wired into the real screens.
  void _showPlaceholderNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Heads up'),
        content: const Text(
          'THIS IS JUST A PLACEHOLDER FOR NOW.\n\n'
          'This is only to show that the `Event Modal` works! '
          'Real data and design will be wired up later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Any id works with the mock repo; use 'missing' to preview the
              // not-found (EVT002) state.
              EventModal.show(context, eventId: 'evt_abc123');
            },
            child: const Text('Show Event Modal (Placeholder)'),
          ),
        ],
      ),
    );
  }
}
