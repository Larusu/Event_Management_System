import 'package:json_annotation/json_annotation.dart';

part 'registration.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Registration {
  Registration({
    required this.registrationId,
    required this.userId,
    required this.eventId,
    required this.isCancelled,
    this.cancelledAt,
    required this.createdAt,
    this.reactivatedAt,
  });

  factory Registration.fromJson(Map<String, dynamic> json) =>
      _$RegistrationFromJson(json);

  final String registrationId;
  final String userId;
  final String eventId;
  final bool isCancelled;
  final String? cancelledAt;
  final String createdAt;
  final String? reactivatedAt;

  Map<String, dynamic> toJson() => _$RegistrationToJson(this);
}
