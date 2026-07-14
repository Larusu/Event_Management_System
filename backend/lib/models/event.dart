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
    required this.coverImageUrl,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.eventMode,
    required this.hostName,
    required this.contactEmails,
    required this.tags,
    required this.isOpenToGuests,
    required this.slotsTotal,
    required this.registeredCount,
    this.location,
    this.streamLink,
    this.guestSpeaker,
  });

  /// Creates an [Event] from a JSON map.
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  /// Firestore document ID.
  final String eventId;

  /// Event title.
  final String title;

  /// Full event description.
  final String description;

  /// Cover photo URL shown on cards and the modal.
  final String coverImageUrl;

  /// Event date, `YYYY-MM-DD`.
  final String date;

  /// Start time, 24h `HH:mm`.
  final String startTime;

  /// End time, 24h `HH:mm`.
  final String endTime;

  /// Event mode, `offline` or `online`.
  final String eventMode;

  /// Physical location; present when [eventMode] is `offline`.
  final String? location;

  /// External stream URL; present when [eventMode] is `online`.
  final String? streamLink;

  /// Free-text host display name.
  final String hostName;

  /// Optional free-text guest speaker name.
  final String? guestSpeaker;

  /// Contact emails shown on the event detail.
  final List<String> contactEmails;

  /// Free-form tags used for filtering and display.
  final List<String> tags;

  /// Whether guests may register (display-only in Feature 3).
  final bool isOpenToGuests;

  /// Total registration capacity.
  final int slotsTotal;

  /// Current confirmed registrations.
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
