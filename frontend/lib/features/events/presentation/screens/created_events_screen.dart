import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/header.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/event.dart';
import '../../providers/created_events_provider.dart';
import 'create_event.dart';

/// Lists every non-deleted event created by the signed-in user.
class CreatedEventsScreen extends StatelessWidget {
  const CreatedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatedEventsProvider()..load(),
      child: const _CreatedEventsView(),
    );
  }
}

class _CreatedEventsView extends StatelessWidget {
  const _CreatedEventsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreatedEventsProvider>();
    final userName =
        context.watch<AuthProvider>().currentUser?.name ?? 'Account';

    return SafeArea(
      child: Column(
        children: [
          Header(
            header: 'Created Events',
            views: const [],
            page: 'dashboard',
            headerSubtitle: userName,
          ),
          Expanded(child: _body(context, provider)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, CreatedEventsProvider provider) {
    if (provider.status == CreatedEventsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.status == CreatedEventsStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.errorMessage ?? 'Could not load your events.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: provider.load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (provider.events.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(Icons.event_note_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Center(child: Text('You have not created any events yet.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: provider.events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final event = provider.events[index];
          return _CreatedEventCard(
            event: event,
            isDeleting: provider.isDeleting(event.eventId),
            onEdit: () => editEvent(
              context,
              event: event,
              onUpdated: provider.load,
            ),
            onDelete: () => _confirmDelete(context, provider, event),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CreatedEventsProvider provider,
    Event event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('“${event.title}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await provider.deleteEvent(event.eventId);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Event deleted.'
              : provider.errorMessage ?? 'Delete failed.',
        ),
        backgroundColor: deleted ? null : Colors.red.shade700,
      ),
    );
  }
}

class _CreatedEventCard extends StatelessWidget {
  const _CreatedEventCard({
    required this.event,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final Event event;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (event.status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      'pending' => Colors.orange,
      _ => Colors.blueGrey,
    };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: event.coverImageUrl.isEmpty
                  ? Container(
                      width: 76,
                      height: 76,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.event_outlined),
                    )
                  : Image.network(
                      event.coverImageUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 76,
                        height: 76,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.status[0].toUpperCase() +
                              event.status.substring(1),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      '${event.displayDate} • ${event.displayStartTime}–${event.displayEndTime}'),
                  const SizedBox(height: 4),
                  Text(
                    '${event.registeredCount} registered • ${event.slotsRemaining} slots left',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Edit event',
                        visualDensity: VisualDensity.compact,
                        onPressed: isDeleting ? null : onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete event',
                        visualDensity: VisualDensity.compact,
                        color: Colors.red.shade700,
                        onPressed: isDeleting ? null : onDelete,
                        icon: isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
