import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

/// API-facing event representation.
///
/// This model matches the locked API doc response shape exactly - it is
/// NOT a 1:1 mirror of the Firestore document.
@JsonSerializable(fieldRename: FieldRename.snake)
class Event {
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
  });

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

  /// Computed field: remaining slots = total - registered.
  int get slotsRemaining => slotsTotal - registeredCount;

  Map<String, dynamic> toJson() => _$EventToJson(this);
}