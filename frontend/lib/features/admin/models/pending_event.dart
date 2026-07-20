import 'package:intl/intl.dart';

/// A row from the faculty/super_admin review queue (`GET /events/pending`).
/// Mirrors the backend's limited pending payload — pending events are not yet
/// public, so only these fields are exposed (no description/location/etc.).
class PendingEvent {
  final String eventId;
  final String title;
  final String coverImageUrl;
  final String date;
  final String startTime;
  final String endTime;
  final String eventMode; // "offline" | "online"
  final String? location; // present when offline
  final String? streamLink; // present when online
  final String hostName;
  final String? guestSpeaker;
  final bool isOpenToGuests;
  final int slotsTotal;
  final String organizerUid;
  final String organizerName;
  final String organizerEmail;
  final String createdAt;

  /// Only meaningful for rejected events (from `GET /events/rejected`);
  /// null/empty for pending rows.
  final String? rejectionReason;

  const PendingEvent({
    required this.eventId,
    required this.title,
    required this.coverImageUrl,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.eventMode,
    this.location,
    this.streamLink,
    required this.hostName,
    this.guestSpeaker,
    required this.isOpenToGuests,
    required this.slotsTotal,
    required this.organizerUid,
    required this.organizerName,
    required this.organizerEmail,
    required this.createdAt,
    this.rejectionReason,
  });

  factory PendingEvent.fromJson(Map<String, dynamic> json) => PendingEvent(
        eventId: json['event_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        coverImageUrl: json['cover_image_url'] as String? ?? '',
        date: json['date'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        eventMode: json['event_mode'] as String? ?? 'offline',
        location: json['location'] as String?,
        streamLink: json['stream_link'] as String?,
        hostName: json['host_name'] as String? ?? '',
        guestSpeaker: json['guest_speaker'] as String?,
        isOpenToGuests: json['is_open_to_guests'] as bool? ?? false,
        slotsTotal: (json['slots_total'] as num?)?.toInt() ?? 0,
        organizerUid: json['organizer_uid'] as String? ?? '',
        organizerName: json['organizer_name'] as String? ?? '',
        organizerEmail: json['organizer_email'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        rejectionReason: json['rejection_reason'] as String?,
      );

  bool get isOnline => eventMode == 'online';

  /// Best-effort display of who created the event, for the modal header.
  String get organizerDisplay {
    if (organizerName.isNotEmpty) return organizerName;
    if (organizerEmail.isNotEmpty) return organizerEmail;
    return 'Unknown organizer';
  }

  String get displayDate {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String get displayStartTime => _formatTime(startTime);

  String get displayEndTime => _formatTime(endTime);

  static String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final t = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(t);
    } catch (_) {
      return time;
    }
  }
}
