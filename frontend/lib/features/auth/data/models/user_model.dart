import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({required String id, required String email, String? name, String? photoUrl}) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

extension UserModelExtension on UserModel {
  User toEntity() => User(id: id, email: email, name: name, photoUrl: photoUrl);
}

@freezed
sealed class LoginRequest with _$LoginRequest {
  const factory LoginRequest({required String email, required String password}) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
sealed class LoginResponse with _$LoginResponse {
  const factory LoginResponse({required String email, required String password}) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
}

@freezed
sealed class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({required String email, required String password, required String name}) =
      _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
sealed class RegisterResponse with _$RegisterResponse {
  const factory RegisterResponse({required String email, required String password, required String name}) =
      _RegisterResponse;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) => _$RegisterResponseFromJson(json);
}

@freezed
sealed class ForgotPasswordRequest with _$ForgotPasswordRequest {
  const factory ForgotPasswordRequest({required String email}) = _ForgotPasswordRequest;

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) => _$ForgotPasswordRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
sealed class ForgotPasswordResponse with _$ForgotPasswordResponse {
  const factory ForgotPasswordResponse({required String email}) = _ForgotPasswordResponse;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) => _$ForgotPasswordResponseFromJson(json);
}
