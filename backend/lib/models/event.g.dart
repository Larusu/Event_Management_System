// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  eventId: json['event_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  coverImageUrl: json['cover_image_url'] as String,
  date: json['date'] as String,
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String,
  eventMode: json['event_mode'] as String,
  hostName: json['host_name'] as String,
  contactEmails: (json['contact_emails'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  isOpenToGuests: json['is_open_to_guests'] as bool,
  slotsTotal: (json['slots_total'] as num).toInt(),
  registeredCount: (json['registered_count'] as num).toInt(),
  location: json['location'] as String?,
  streamLink: json['stream_link'] as String?,
  guestSpeaker: json['guest_speaker'] as String?,
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'title': instance.title,
  'description': instance.description,
  'cover_image_url': instance.coverImageUrl,
  'date': instance.date,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'event_mode': instance.eventMode,
  'location': instance.location,
  'stream_link': instance.streamLink,
  'host_name': instance.hostName,
  'guest_speaker': instance.guestSpeaker,
  'contact_emails': instance.contactEmails,
  'tags': instance.tags,
  'is_open_to_guests': instance.isOpenToGuests,
  'slots_total': instance.slotsTotal,
  'registered_count': instance.registeredCount,
};
