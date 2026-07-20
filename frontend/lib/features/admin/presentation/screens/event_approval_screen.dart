import 'package:campus_event_app/core/constants/roles.dart';
import 'package:campus_event_app/features/admin/models/pending_event.dart';
import 'package:campus_event_app/features/admin/providers/event_approval_provider.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Event approval / review queue (faculty / super_admin only).
///
/// Lists pending events (title + date/time). Tapping one opens a minimal
/// modal (cover, title, date/time) with Approve / Reject actions.
class EventApprovalScreen extends StatelessWidget {
  const EventApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final isAdmin = role == Roles.faculty || role == Roles.superAdmin;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Event Approvals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: const Center(
          child: Text(
            'You do not have access to this page.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => EventApprovalProvider()..load(),
      child: const _EventApprovalView(),
    );
  }
}

class _EventApprovalView extends StatefulWidget {
  const _EventApprovalView();

  @override
  State<_EventApprovalView> createState() => _EventApprovalViewState();
}

class _EventApprovalViewState extends State<_EventApprovalView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<EventApprovalProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        provider.hasMore &&
        !provider.isLoadingMore) {
      provider.loadMore();
    }
  }

  void _openEventSheet(PendingEvent event) {
    final isRejected =
        context.read<EventApprovalProvider>().filter == ReviewFilter.rejected;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _PendingEventSheet(
        event: event,
        isRejected: isRejected,
        onApprove: isRejected
            ? null
            : () {
                Navigator.pop(sheetContext);
                _approve(event);
              },
        onReject: isRejected
            ? null
            : () {
                Navigator.pop(sheetContext);
                _reject(event);
              },
        onReopen: isRejected
            ? () {
                Navigator.pop(sheetContext);
                _reopen(event);
              }
            : null,
      ),
    );
  }

  Future<void> _approve(PendingEvent event) async {
    final provider = context.read<EventApprovalProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await _confirm(
      title: 'Approve event',
      message: 'Approve "${event.title}"? It will become visible to everyone.',
      confirmLabel: 'Approve',
    );
    if (!mounted || confirmed != true) return;

    final error = await provider.moderate(
      eventId: event.eventId,
      action: 'approve',
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? '"${event.title}" approved.'),
        backgroundColor: error != null ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _reject(PendingEvent event) async {
    final provider = context.read<EventApprovalProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final reason = await _askReason(event);
    if (!mounted || reason == null) return;

    final confirmed = await _confirm(
      title: 'Reject event',
      message: reason.trim().isEmpty
          ? 'Reject "${event.title}" without a reason?'
          : 'Reject "${event.title}"?',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (!mounted || confirmed != true) return;

    final error = await provider.moderate(
      eventId: event.eventId,
      action: 'reject',
      reason: reason,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? '"${event.title}" rejected.'),
        backgroundColor: error != null ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _reopen(PendingEvent event) async {
    final provider = context.read<EventApprovalProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await _confirm(
      title: 'Reopen event',
      message: 'Reopen "${event.title}"? It will move back to the pending '
          'queue for review.',
      confirmLabel: 'Reopen',
    );
    if (!mounted || confirmed != true) return;

    final error = await provider.moderate(
      eventId: event.eventId,
      action: 'reopen',
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? '"${event.title}" reopened.'),
        backgroundColor: error != null ? Colors.red.shade700 : null,
      ),
    );
  }

  /// Reason prompt. Returns `null` if cancelled, or the (possibly empty)
  /// reason string if the user chose to continue.
  Future<String?> _askReason(PendingEvent event) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Rejection reason'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optionally tell the organizer why "${event.title}" was '
                  'rejected.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Reason (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700)
                  : null,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventApprovalProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Event Approvals',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilter(provider),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter(EventApprovalProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<ReviewFilter>(
        segments: const [
          ButtonSegment(
            value: ReviewFilter.pending,
            label: Text('Pending'),
            icon: Icon(Icons.hourglass_empty),
          ),
          ButtonSegment(
            value: ReviewFilter.rejected,
            label: Text('Rejected'),
            icon: Icon(Icons.cancel_outlined),
          ),
        ],
        selected: {provider.filter},
        onSelectionChanged: (selection) {
          provider.setFilter(selection.first);
        },
      ),
    );
  }

  Widget _buildBody(EventApprovalProvider provider) {
    switch (provider.status) {
      case EventApprovalStatus.idle:
      case EventApprovalStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case EventApprovalStatus.error:
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
                onPressed: provider.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      case EventApprovalStatus.loaded:
        final events = provider.events;
        final isRejected = provider.filter == ReviewFilter.rejected;
        if (events.isEmpty) {
          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    isRejected
                        ? 'No rejected events.'
                        : 'No events awaiting approval.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: provider.load,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: events.length + (provider.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index >= events.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final event = events[index];
              return _PendingEventTile(
                event: event,
                isRejected: isRejected,
                onTap: () => _openEventSheet(event),
              );
            },
          ),
        );
    }
  }
}

/// Small queue row: title + date/time + a status tag.
class _PendingEventTile extends StatelessWidget {
  final PendingEvent event;
  final bool isRejected;
  final VoidCallback onTap;

  const _PendingEventTile({
    required this.event,
    required this.isRejected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusTag(isRejected: isRejected),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.displayDate}  •  '
                      '${event.displayStartTime} - ${event.displayEndTime}',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.slotsTotal} slots',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small tinted pill showing whether an event is pending or rejected.
class _StatusTag extends StatelessWidget {
  final bool isRejected;

  const _StatusTag({required this.isRejected});

  @override
  Widget build(BuildContext context) {
    final foreground =
        isRejected ? Colors.red.shade700 : Colors.orange.shade800;
    final background =
        isRejected ? Colors.red.shade50 : Colors.orange.shade50;
    final label = isRejected ? 'Rejected' : 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

/// A single icon + value detail row used inside the pending event sheet.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal detail sheet for a review-queue event. In the pending queue it shows
/// approve/reject actions; in the rejected queue it shows the rejection reason
/// and a single reopen action.
class _PendingEventSheet extends StatelessWidget {
  final PendingEvent event;
  final bool isRejected;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onReopen;

  const _PendingEventSheet({
    required this.event,
    required this.isRejected,
    this.onApprove,
    this.onReject,
    this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(Icons.person, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Organized by',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        event.organizerDisplay,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (event.organizerName.isNotEmpty &&
                          event.organizerEmail.isNotEmpty)
                        Text(
                          event.organizerEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (event.coverImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    event.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.event_outlined,
              value: '${event.displayDate}  •  '
                  '${event.displayStartTime} - ${event.displayEndTime}',
            ),
            if (event.hostName.isNotEmpty)
              _InfoRow(icon: Icons.person_outline, value: event.hostName),
            if (event.guestSpeaker != null && event.guestSpeaker!.isNotEmpty)
              _InfoRow(
                icon: Icons.mic_none_outlined,
                value: event.guestSpeaker!,
              ),
            if (event.isOnline)
              if (event.streamLink != null && event.streamLink!.isNotEmpty)
                _InfoRow(icon: Icons.link, value: event.streamLink!)
              else
                const _InfoRow(icon: Icons.link, value: 'Online event')
            else if (event.location != null && event.location!.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, value: event.location!),
            _InfoRow(
              icon: Icons.event_seat_outlined,
              value: '${event.slotsTotal} slots',
            ),
            _InfoRow(
              icon: Icons.groups_outlined,
              value: event.isOpenToGuests ? 'Open to guests' : 'Students only',
            ),
            if (isRejected &&
                event.rejectionReason != null &&
                event.rejectionReason!.trim().isNotEmpty)
              _InfoRow(
                icon: Icons.notes_outlined,
                value: 'Reason: ${event.rejectionReason}',
              ),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (isRejected) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onReopen,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reopen'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
