import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

/// API-facing event representation.
///
/// This model matches the locked API doc response shape exactly - it is
/// NOT a 1:1 mirror of the Firestore document.
@JsonSerializable(fieldRename: FieldRename.snake)
class Event {
  /// Creates an [Event] with the API response fields and internal
  /// filtering fields ([status], [isDeleted]).
  Event({
    required this.eventId,
    required this.title,
    required this.coverImageUrl,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.tags,
    required this.slotsTotal,
    required this.registeredCount,
    this.status = 'draft',
    this.isDeleted = false,
  });

  /// Creates an [Event] from a decoded JSON map.
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  /// Unique identifier for the event.
  final String eventId;

  /// Event title.
  final String title;

  /// URL to the event cover image.
  final String coverImageUrl;

  /// Event date in ISO 8601 format.
  final String date;

  /// Event start time.
  final String startTime;

  /// Event end time.
  final String endTime;

  /// List of tags associated with the event.
  final List<String> tags;

  /// Total number of available slots.
  final int slotsTotal;

  /// Number of registered attendees.
  final int registeredCount;

  /// Event status (draft, approved, rejected). Internal use for filtering.
  @JsonKey(includeToJson: false, includeFromJson: false)
  final String status;

  /// Whether the event is deleted (internal use only, not exposed in API).
  @JsonKey(includeToJson: false, includeFromJson: false)
  final bool isDeleted;

  /// Computed field: remaining slots = total - registered.
  int get slotsRemaining => slotsTotal - registeredCount;

  /// Serializes this event to the API response JSON map.
  Map<String, dynamic> toJson() => _$EventToJson(this);
}
