import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_response.freezed.dart';
part 'token_response.g.dart';

@freezed
abstract class RefreshTokenRequest with _$RefreshTokenRequest {
  const factory RefreshTokenRequest({
    @JsonKey(name: 'refresh_token') required final String refreshToken,
  }) = _RefreshTokenRequest;

  factory RefreshTokenRequest.fromJson(
    final Map<String, dynamic> json,
  ) => _$RefreshTokenRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
abstract class RefreshTokenResponse with _$RefreshTokenResponse {
  const factory RefreshTokenResponse({
    @JsonKey(name: 'access_token') required final String accessToken,
    @JsonKey(name: 'refresh_token') final String? refreshToken,
    @JsonKey(name: 'expires_in') final int? expiresIn,
  }) = _RefreshTokenResponse;

  factory RefreshTokenResponse.fromJson(
    final Map<String, dynamic> json,
  ) => _$RefreshTokenResponseFromJson(json);
}

@freezed
abstract class TokenError with _$TokenError {
  const factory TokenError({
    @JsonKey(name: 'error') required final String error,
    @JsonKey(name: 'error_description') final String? errorDescription,
    @JsonKey(name: 'status') final String? status,
    @JsonKey(name: 'message') final String? message,
  }) = _TokenError;

  factory TokenError.fromJson(
    final Map<String, dynamic> json,
  ) => _$TokenErrorFromJson(json);
}
