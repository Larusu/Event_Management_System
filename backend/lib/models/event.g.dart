// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  eventId: json['event_id'] as String,
  title: json['title'] as String,
  coverImageUrl: json['cover_image_url'] as String,
  date: json['date'] as String,
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  slotsTotal: (json['slots_total'] as num).toInt(),
  registeredCount: (json['registered_count'] as num).toInt(),
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'title': instance.title,
  'cover_image_url': instance.coverImageUrl,
  'date': instance.date,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'tags': instance.tags,
  'slots_total': instance.slotsTotal,
  'registered_count': instance.registeredCount,
};
