import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/header.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/event.dart';
import '../../providers/created_events_provider.dart';
import 'create_event.dart';

/// Lists every non-deleted event created by the signed-in user.
///
/// Consumes the app-level [CreatedEventsProvider] (registered in `main.dart`)
/// so the same owned-events data backs both this screen and the Event Modal's
/// "Your own event" check. Refreshes on entry.
class CreatedEventsScreen extends StatefulWidget {
  const CreatedEventsScreen({super.key});

  @override
  State<CreatedEventsScreen> createState() => _CreatedEventsScreenState();
}

class _CreatedEventsScreenState extends State<CreatedEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CreatedEventsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) => const _CreatedEventsView();
}

class _CreatedEventsView extends StatelessWidget {
  const _CreatedEventsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreatedEventsProvider>();
    final userName =
        context.watch<AuthProvider>().currentUser?.name ?? 'Account';

    return SafeArea(
      top: false,
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
    final confirmed = await AppDialog.confirm(
      context: context,
      icon: Icons.delete_outline,
      title: 'Delete event?',
      message: '"${event.title}" will be permanently removed.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    final deleted = await provider.deleteEvent(event.eventId);
    if (!context.mounted) return;
    AppDialog.info(
      context: context,
      icon: deleted ? Icons.check_circle_outline : Icons.error_outline,
      iconColor: deleted ? null : Theme.of(context).colorScheme.error,
      title: deleted ? 'Event Deleted' : 'Delete Failed',
      message: deleted
          ? 'Event deleted.'
          : (provider.errorMessage ?? 'Delete failed.'),
    );
    if (deleted) provider.load();
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

    // Finished events (date + end time already past) are locked: they can no
    // longer be edited or deleted.
    final isFinished = event.hasEnded();

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
                  if (event.status == 'rejected') ...[
                    const SizedBox(height: 8),
                    _RejectionBanner(reason: event.rejectionReason),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isFinished) ...[
                        Text(
                          'Finished',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        tooltip:
                            isFinished ? 'Finished events can\'t be edited' : 'Edit event',
                        visualDensity: VisualDensity.compact,
                        onPressed: (isDeleting || isFinished) ? null : onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: isFinished
                            ? 'Finished events can\'t be deleted'
                            : 'Delete event',
                        visualDensity: VisualDensity.compact,
                        color: Colors.red.shade700,
                        onPressed:
                            (isDeleting || isFinished) ? null : onDelete,
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

/// Explains to the organizer why their event was rejected. Shown only on
/// rejected cards; falls back to a generic line when the moderator left no
/// reason (rejection reasons are optional).
class _RejectionBanner extends StatelessWidget {
  const _RejectionBanner({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final red = Colors.red.shade700;
    final hasReason = reason != null && reason!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: red),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason for rejection',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasReason ? reason! : 'No reason was provided.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: hasReason ? FontStyle.normal : FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
