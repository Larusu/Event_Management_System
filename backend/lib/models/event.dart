import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Event {
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

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  final String eventId;
  final String title;
  final String description;
  final String coverImageUrl;
  final String date;
  final String startTime;
  final String endTime;
  final String eventMode;
  final String? location;
  final String? streamLink;
  final String hostName;
  final String? guestSpeaker;
  final List<String> contactEmails;
  final List<String> tags;
  final bool isOpenToGuests;
  final int slotsTotal;
  final int registeredCount;
  @JsonKey(includeToJson: false, includeFromJson: false)
  final String status;
  @JsonKey(includeToJson: false, includeFromJson: false)
  final bool isDeleted;

  int get slotsRemaining => slotsTotal - registeredCount;

  Map<String, dynamic> toJson() {
    final json = _$EventToJson(this);
    json['slots_remaining'] = slotsRemaining;
    return json;
  }
}