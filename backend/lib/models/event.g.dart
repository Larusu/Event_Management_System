// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  eventId: json['event_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  cover_image_url: json['cover_image_url'] as String,
  date: json['date'] as String,
  start_time: json['start_time'] as String,
  end_time: json['end_time'] as String,
  event_mode: json['event_mode'] as String,
  location: json['location'] as String?,
  stream_link: json['stream_link'] as String?,
  host_name: json['host_name'] as String,
  guest_speaker: json['guest_speaker'] as String?,
  contactEmails: (json['contact_emails'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  is_open_to_guests: json['is_open_to_guests'] as bool,
  slotsTotal: (json['slots_total'] as num).toInt(),
  registeredCount: (json['registered_count'] as num).toInt(),
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'title': instance.title,
  'description': instance.description,
  'cover_image_url': instance.cover_image_url,
  'date': instance.date,
  'start_time': instance.start_time,
  'end_time': instance.end_time,
  'event_mode': instance.event_mode,
  'location': instance.location,
  'stream_link': instance.stream_link,
  'host_name': instance.host_name,
  'guest_speaker': instance.guest_speaker,
  'contact_emails': instance.contactEmails,
  'tags': instance.tags,
  'is_open_to_guests': instance.is_open_to_guests,
  'slots_total': instance.slotsTotal,
  'registered_count': instance.registeredCount,
};
