// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Registration _$RegistrationFromJson(Map<String, dynamic> json) => Registration(
  registrationId: json['registration_id'] as String,
  userId: json['user_id'] as String,
  eventId: json['event_id'] as String,
  isCancelled: json['is_cancelled'] as bool,
  cancelledAt: json['cancelled_at'] as String?,
  createdAt: json['created_at'] as String,
  reactivatedAt: json['reactivated_at'] as String?,
);

Map<String, dynamic> _$RegistrationToJson(Registration instance) =>
    <String, dynamic>{
      'registration_id': instance.registrationId,
      'user_id': instance.userId,
      'event_id': instance.eventId,
      'is_cancelled': instance.isCancelled,
      'cancelled_at': instance.cancelledAt,
      'created_at': instance.createdAt,
      'reactivated_at': instance.reactivatedAt,
    };
