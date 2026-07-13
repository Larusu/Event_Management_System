import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

/// API-facing event detail representation.
///
/// Matches the locked API doc response shape for GET /events/{eventId}.
/// Firestore additionally tracks `status`, `organizer_uid`, and `is_deleted`,
/// none of which are ever returned in an API response.
@JsonSerializable(fieldRename: FieldRename.snake)
class Event {
  /// Creates an [Event].
  Event({
    required this.eventId,
    required this.title,
    required this.description,
    required this.cover_image_url,
    required this.date,
    required this.start_time,
    required this.end_time,
    required this.event_mode,
    this.location,
    this.stream_link,
    required this.host_name,
    this.guest_speaker,
    required this.contactEmails,
    required this.tags,
    required this.is_open_to_guests,
    required this.slotsTotal,
    required this.registeredCount,
  });

  /// Creates an [Event] from a JSON map.
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  final String eventId;
  final String title;
  final String description;
  final String cover_image_url;
  final String date;
  final String start_time;
  final String end_time;
  final String event_mode;
  final String? location;
  final String? stream_link;
  final String host_name;
  final String? guest_speaker;
  final List<String> contactEmails;
  final List<String> tags;
  final bool is_open_to_guests;
  final int slotsTotal;
  final int registeredCount;

  /// Converts this [Event] to a JSON map with snake_case keys.
  ///
  /// Includes `slots_remaining`, computed server-side as
  /// `slots_total - registered_count`.
  Map<String, dynamic> toJson() {
    final json = _$EventToJson(this);
    json['slots_remaining'] = slotsTotal - registeredCount;
    return json;
  }
}
