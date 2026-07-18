import 'package:intl/intl.dart';

/// Single-event detail as returned by `GET /events/{eventId}` (doc 3.5.2).
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
      );

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
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
}
