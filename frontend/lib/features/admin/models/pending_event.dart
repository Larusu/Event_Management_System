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
  final String organizerUid;
  final String createdAt;

  const PendingEvent({
    required this.eventId,
    required this.title,
    required this.coverImageUrl,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.organizerUid,
    required this.createdAt,
  });

  factory PendingEvent.fromJson(Map<String, dynamic> json) => PendingEvent(
        eventId: json['event_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        coverImageUrl: json['cover_image_url'] as String? ?? '',
        date: json['date'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        organizerUid: json['organizer_uid'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );

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
