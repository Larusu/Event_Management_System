import 'package:intl/intl.dart';

/// Single-event detail as returned by `GET /events/{eventId}`.
///
/// Scoped to the fields the Event Modal displays. Internal fields such as
/// `status`, `organizer_uid`, and `is_deleted` are intentionally never exposed
/// by this endpoint, so they are not modelled here.
class Event {
  final String eventId;
  final String title;
  final String description;
  final String coverImageUrl;
  final String date; // "YYYY-MM-DD"
  final String startTime; // "HH:mm" (24h)
  final String endTime; // "HH:mm" (24h)
  final String eventMode; // "offline" | "online"
  final String? location; // present when offline
  final String? streamLink; // present when online
  final String hostName;
  final String? guestSpeaker;
  final List<String> contactEmails;
  final List<String> tags;
  final bool isOpenToGuests;
  final int registeredCount;
  final int slotsRemaining;
  final bool isRegistered;
  final String status;

  /// Moderator's reason when [status] is `rejected`. Only returned by
  /// `GET /events/created` (the organizer's own events); null everywhere else
  /// and when no reason was supplied.
  final String? rejectionReason;

  const Event({
    required this.eventId,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.eventMode,
    this.location,
    this.streamLink,
    required this.hostName,
    this.guestSpeaker,
    required this.contactEmails,
    required this.tags,
    required this.isOpenToGuests,
    required this.registeredCount,
    required this.slotsRemaining,
    this.isRegistered = false,
    this.status = 'approved',
    this.rejectionReason,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        eventId: json['event_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        coverImageUrl: json['cover_image_url'] as String? ?? '',
        date: json['date'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        eventMode: json['event_mode'] as String? ?? 'offline',
        location: json['location'] as String?,
        streamLink: json['stream_link'] as String?,
        hostName: json['host_name'] as String? ?? '',
        guestSpeaker: json['guest_speaker'] as String?,
        contactEmails: _stringList(json['contact_emails']),
        tags: _stringList(json['tags']),
        isOpenToGuests: json['is_open_to_guests'] as bool? ?? false,
        registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
        slotsRemaining: (json['slots_remaining'] as num?)?.toInt() ?? 0,
        isRegistered: json['is_registered'] as bool? ?? false,
        status: _eventStatus(json['status']),
        rejectionReason: _nullableString(json['rejection_reason']),
      );

  /// Trims a string field and collapses empty/blank values to null.
  static String? _nullableString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static String _eventStatus(dynamic value) {
    final status = value is String ? value.trim() : '';
    return status.isEmpty ? 'approved' : status;
  }

  String get displayDate {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String get displayStartTime {
    try {
      final parts = startTime.split(':');
      final t = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(t);
    } catch (_) {
      return startTime;
    }
  }

  String get displayEndTime {
    try {
      final parts = endTime.split(':');
      final t = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(t);
    } catch (_) {
      return endTime;
    }
  }

  String get displayDay {
    try {
      return DateFormat('EEEE').format(DateTime.parse(date));
    } catch (_) {
      return '';
    }
  }

  /// True when the event's end (date + [endTime]) is at or before [now]
  /// (defaults to the current local time). A missing/malformed date or time is
  /// treated as not ended so a finished event is never assumed by accident.
  bool hasEnded([DateTime? now]) {
    final parsedDate = DateTime.tryParse(date);
    final parts = endTime.split(':');
    if (parsedDate == null || parts.length < 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;
    final end = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      hour,
      minute,
    );
    return !end.isAfter(now ?? DateTime.now());
  }
}
