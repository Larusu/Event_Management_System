// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      contact: json['contact'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'contact': instance.contact,
    };

SignInRequest _$SignInRequestFromJson(Map<String, dynamic> json) =>
    SignInRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$SignInRequestToJson(SignInRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    RefreshTokenRequest(token: json['token'] as String);

Map<String, dynamic> _$RefreshTokenRequestToJson(
  RefreshTokenRequest instance,
) => <String, dynamic>{'token': instance.token};

ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ForgotPasswordRequest(email: json['email'] as String);

Map<String, dynamic> _$ForgotPasswordRequestToJson(
  ForgotPasswordRequest instance,
) => <String, dynamic>{'email': instance.email};

UpdateProfileRequest _$UpdateProfileRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequest(
  currentPassword: json['current_password'] as String,
  name: json['name'] as String?,
  contact: json['contact'] as String?,
  newPassword: json['new_password'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestToJson(
  UpdateProfileRequest instance,
) => <String, dynamic>{
  'current_password': instance.currentPassword,
  'name': instance.name,
  'contact': instance.contact,
  'new_password': instance.newPassword,
};
