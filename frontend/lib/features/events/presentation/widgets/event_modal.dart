import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/roles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/event_detail_provider.dart';

const Color _kGrey = Color(0xFF828282);

/// Entry point for the Feature 3 Event Modal (Figma node 75:59).
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
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => EventDetailProvider()..load(eventId),
        child: const _EventModalView(),
      ),
    );
  }
}

/// Renders the modal based on the fetch state and applies the guest-role rule
/// for the Register button (client-side only, per doc 3.9).
class _EventModalView extends StatelessWidget {
  const _EventModalView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventDetailProvider>();

    switch (provider.status) {
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
        // Hide Register for guests when the event isn't open to guests.
        final showRegister =
            !(role == Roles.guest && !event.isOpenToGuests);
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
          showRegisterButton: showRegister,
        );
    }
  }
}

/// A minimal rounded bottom-sheet shell (handle + white background) used for the
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
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: Colors.white,
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [_dragHandle(), child],
            ),
          ),
        );
      },
    );
  }
}

/// The grey pill drag handle shown at the top of every modal state.
Widget _dragHandle() {
  return Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12),
    alignment: Alignment.center,
    child: Container(
      width: 61,
      height: 8,
      decoration: BoxDecoration(
        color: _kGrey,
        borderRadius: BorderRadius.circular(15),
      ),
    ),
  );
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
    this.showRegisterButton = true,
    this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: Colors.white,
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                _dragHandle(),
                _cover(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(23, 20, 23, 24),
                  child: _details(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cover() {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Image.network(
        coverImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined,
              size: 48, color: _kGrey),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade100,
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Location / stream link
        Text(
          eventMode == 'online'
              ? (streamLink ?? '')
              : (location ?? ''),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        // Host / guest speaker + register button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _hostInfo()),
            const SizedBox(width: 12),
            if (showRegisterButton) _registerColumn(context, primary),
          ],
        ),
        const SizedBox(height: 12),

        const Divider(color: _kGrey, thickness: 0.5, height: 1),
        const SizedBox(height: 12),

        // Description
        Text(
          description,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: Colors.black,
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

        // Contact details + info box
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _contactInfo()),
            const SizedBox(width: 12),
            _infoBox(primary),
          ],
        ),
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

  Widget _hostInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: Colors.black),
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
              style: const TextStyle(fontSize: 13, color: Colors.black),
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

  Widget _registerColumn(BuildContext context, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _guestBadgeLabel,
          style: const TextStyle(fontSize: 9, color: _kGrey),
        ),
        const SizedBox(height: 4),
        Material(
          color: primary,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              if (onRegister != null) {
                onRegister!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Text(
                'Register Now!',
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _contactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Details:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        ...contactEmails.map(
          (email) => Text(
            email,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: Colors.black,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(Color primary) {
    return Container(
      width: 137,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _guestBadgeLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            '$registeredCount registered participants',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            '$slotsRemaining slots left!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String get _guestBadgeLabel =>
      isOpenToGuests ? 'Open to guests!!' : 'Available to students only!!';

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
