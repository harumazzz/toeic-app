import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required final int id,
    required final String email,
    required final String username,
  }) = _UserModel;

  factory UserModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$UserModelFromJson(json);
}

extension UserModelExtension on UserModel {
  User toEntity() => User(
    id: id,
    email: email,
    username: username,
  );
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
    required final UserModel user,
    @JsonKey(name: 'access_token') required final String accessToken,
    @JsonKey(name: 'refresh_token') required final String refreshToken,
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
    required final String username,
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
    required final UserModel user,
    @JsonKey(name: 'access_token') required final String accessToken,
    @JsonKey(name: 'refresh_token') required final String refreshToken,
  }) = _RegisterResponse;

  factory RegisterResponse.fromJson(
    final Map<String, dynamic> json,
  ) => _$RegisterResponseFromJson(json);
}
