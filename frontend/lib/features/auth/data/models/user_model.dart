import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required final String id,
    required final String email,
    final String? name,
    final String? photoUrl,
  }) = _UserModel;

  factory UserModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$UserModelFromJson(json);
}

extension UserModelExtension on UserModel {
  User toEntity() => User(id: id, email: email, name: name, photoUrl: photoUrl);
}

@freezed
sealed class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required final String email,
    required final String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(
    final Map<String, dynamic> json,
  ) => _$LoginRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
sealed class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required final String email,
    required final String password,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(
    final Map<String, dynamic> json,
  ) => _$LoginResponseFromJson(json);
}

@freezed
sealed class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required final String email,
    required final String password,
    required final String name,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(
    final Map<String, dynamic> json,
  ) => _$RegisterRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
sealed class RegisterResponse with _$RegisterResponse {
  const factory RegisterResponse({
    required final String email,
    required final String password,
    required final String name,
  }) = _RegisterResponse;

  factory RegisterResponse.fromJson(
    final Map<String, dynamic> json,
  ) => _$RegisterResponseFromJson(json);
}

@freezed
sealed class ForgotPasswordRequest with _$ForgotPasswordRequest {
  const factory ForgotPasswordRequest({
    required final String email,
  }) = _ForgotPasswordRequest;

  factory ForgotPasswordRequest.fromJson(
    final Map<String, dynamic> json,
  ) => _$ForgotPasswordRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
sealed class ForgotPasswordResponse with _$ForgotPasswordResponse {
  const factory ForgotPasswordResponse({
    required final String email,
  }) = _ForgotPasswordResponse;

  factory ForgotPasswordResponse.fromJson(
    final Map<String, dynamic> json,
  ) => _$ForgotPasswordResponseFromJson(json);
}
