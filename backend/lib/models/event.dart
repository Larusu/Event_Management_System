import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

/// API-facing event representation (shared by the feed and detail endpoints).
///
/// Matches the locked API doc response shape. Firestore also tracks `status`,
/// `organizer_uid`, and `is_deleted`; `status` and `is_deleted` are read into
/// the model for server-side feed filtering but are NEVER serialized into an
/// API response. `organizer_uid` is not modeled.
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
    this.status = 'draft',
    this.isDeleted = false,
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

  /// Event status (e.g. `approved`); internal, used for feed filtering only.
  @JsonKey(includeToJson: false, includeFromJson: false)
  final String status;

  /// Soft-delete flag; internal, used for feed filtering only.
  @JsonKey(includeToJson: false, includeFromJson: false)
  final bool isDeleted;

  /// Remaining slots = total - registered.
  int get slotsRemaining => slotsTotal - registeredCount;

  /// Converts this [Event] to a JSON map with snake_case keys, including the
  /// computed `slots_remaining`.
  Map<String, dynamic> toJson() {
    final json = _$EventToJson(this);
    json['slots_remaining'] = slotsRemaining;
    return json;
  }
}

