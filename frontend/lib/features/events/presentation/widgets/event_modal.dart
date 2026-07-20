import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/roles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/event_dashboard_provider.dart';
import '../../providers/event_detail_provider.dart';
import '../screens/event_map.dart';

const Color _kGrey = Color(0xFF828282);

/// Entry point for the Event Modal
///
/// [show] fetches the event by id (via [EventDetailProvider]) and renders the
/// loading / error / loaded states. The loaded state paints [EventModalContent],
/// which is a pure, design-only widget (no data access) so it can also be reused
/// or previewed with hand-supplied values.
class EventModal {
  const EventModal._();

  /// Presents the modal as a full-bleed draggable bottom sheet.
  ///
  /// The cover image runs edge-to-edge, so this uses its own bottom sheet rather
  /// than the shared `ModalContainer` (whose inner padding would inset it).
  static Future<void> show(
    BuildContext context, {
    required String eventId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => EventDetailProvider(),
        child: _EventModalView(eventId: eventId),
      ),
    );
  }
}

/// Renders the modal based on the fetch state and applies the guest-role rule
/// for the Register button (client-side only).
class _EventModalView extends StatefulWidget {
  final String eventId;
  const _EventModalView({required this.eventId});

  @override
  State<_EventModalView> createState() => _EventModalViewState();
}

class _EventModalViewState extends State<_EventModalView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EventDetailProvider>().load(widget.eventId);
    });
  }

  void _onRegister() {
    final provider = context.read<EventDetailProvider>();
    final event = provider.event;
    if (event == null) return;

    showDialog(
      context: context,
      builder: (_) => _RegisterConfirmDialog(
        eventTitle: event.title,
        onConfirm: () async {
          Navigator.pop(context);
          final success = await provider.register(widget.eventId);
          if (!mounted) return;
          if (success) {
            // Refresh the Dashboard's registered sections so the newly
            // registered event shows up without an app restart.
            final dashboard = context.read<EventDashboardProvider>();
            dashboard.loadRegistered();
            dashboard.loadNextRegistered();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registered successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(provider.registrationError ?? 'Registration failed.'),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventDetailProvider>();

    switch (provider.status) {
      case EventDetailStatus.idle:
      case EventDetailStatus.loading:
        return const _SheetShell(
          child: SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      case EventDetailStatus.error:
        return _SheetShell(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Center(
              child: Text(
                provider.errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      case EventDetailStatus.loaded:
        final event = provider.event!;
        final role = context.read<AuthProvider>().currentUser?.role;
        final showRegister = !(role == Roles.guest && !event.isOpenToGuests);
        return EventModalContent(
          coverImageUrl: event.coverImageUrl,
          title: event.title,
          date: event.date,
          startTime: event.startTime,
          endTime: event.endTime,
          eventMode: event.eventMode,
          location: event.location,
          streamLink: event.streamLink,
          hostName: event.hostName,
          guestSpeaker: event.guestSpeaker,
          description: event.description,
          contactEmails: event.contactEmails,
          tags: event.tags,
          isOpenToGuests: event.isOpenToGuests,
          registeredCount: event.registeredCount,
          slotsRemaining: event.slotsRemaining,
          isRegistered: event.isRegistered,
          showRegisterButton: showRegister,
          onRegister: _onRegister,
        );
    }
  }
}

/// Confirmation dialog shown before registering.
class _RegisterConfirmDialog extends StatelessWidget {
  final String eventTitle;
  final VoidCallback onConfirm;

  const _RegisterConfirmDialog({
    required this.eventTitle,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available, size: 48, color: primary),
          const SizedBox(height: 16),
          const Text(
            'Register for this event?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            eventTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

/// A minimal rounded bottom-sheet shell used for the
/// loading and error states, so they match the modal's look.
class _SheetShell extends StatelessWidget {
  final Widget child;

  const _SheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [child],
        );
      },
    );
  }
}

class EventModalContent extends StatelessWidget {
  final String coverImageUrl;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String eventMode;
  final String? location;
  final String? streamLink;
  final String hostName;
  final String? guestSpeaker;
  final String description;
  final List<String> contactEmails;
  final List<String> tags;
  final bool isOpenToGuests;
  final int registeredCount;
  final int slotsRemaining;
  final bool isRegistered;
  final bool showRegisterButton;
  final VoidCallback? onRegister;

  const EventModalContent({
    super.key,
    required this.coverImageUrl,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.eventMode,
    this.location,
    this.streamLink,
    required this.hostName,
    this.guestSpeaker,
    required this.description,
    required this.contactEmails,
    this.tags = const [],
    required this.isOpenToGuests,
    required this.registeredCount,
    required this.slotsRemaining,
    this.isRegistered = false,
    this.showRegisterButton = true,
    this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.87,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            _cover(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(23, 20, 23, 24),
              child: _details(context),
            ),
          ],
        );
      },
    );
  }

  Widget _cover(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Image.network(
        coverImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined,
              size: 48, color: _kGrey),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        },
      ),
    );
  }

  Widget _details(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + date/time
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(date),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Location / stream link
        eventMode == 'online'
            ? Text(
                streamLink ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              )
            : InkWell(
                onTap: () => viewEventMap(context, location: location ?? ''),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        location ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.map_outlined,
                      size: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 12),

        // Host / guest speaker + info chip
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _hostInfo(context)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _guestBadge(primary),
                const SizedBox(height: 6),
                _infoChip(primary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        const Divider(color: _kGrey, thickness: 0.5, height: 1),
        const SizedBox(height: 12),

        // Description
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map(
                  (t) => Chip(
                    label: Text(t),
                    labelStyle: const TextStyle(fontSize: 11),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 16),

        // Contact details
        _contactInfo(context),
        const SizedBox(height: 16),

        // Register button
        if (showRegisterButton) _registerButton(primary),
        const SizedBox(height: 16),

        // Footer
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                color: primary,
              ),
              children: const [
                TextSpan(text: 'For more inquiries, contact '),
                TextSpan(
                  text: 'sao@ciit.edu.ph',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hostInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
                fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
            children: [
              const TextSpan(
                text: 'Hosted by: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: hostName),
            ],
          ),
        ),
        if (guestSpeaker != null && guestSpeaker!.isNotEmpty) ...[
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
              children: [
                const TextSpan(
                  text: 'Guest Speaker: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: guestSpeaker),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _registerButton(Color primary) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: isRegistered ? Colors.grey : primary,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: isRegistered ? null : onRegister,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              isRegistered ? 'Registered \u2713' : 'Register Now!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Details:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        ...contactEmails.map(
          (email) => Text(
            email,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _guestBadge(Color primary) {
    final color = isOpenToGuests ? primary : _kGrey;
    final label = isOpenToGuests ? 'Open to guests!!' : 'Students only!!';
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _infoChip(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 14, color: primary),
          const SizedBox(width: 4),
          Text(
            '$registeredCount / ${registeredCount + slotsRemaining}',
            style: TextStyle(
              fontSize: 11,
              color: primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _formatTime(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final t = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(t);
    } catch (_) {
      return hhmm;
    }
  }
}
