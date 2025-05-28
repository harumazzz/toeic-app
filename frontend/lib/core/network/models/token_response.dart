import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_response.freezed.dart';
part 'token_response.g.dart';

@freezed
sealed class RefreshTokenRequest with _$RefreshTokenRequest {
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
sealed class RefreshTokenResponse with _$RefreshTokenResponse {
  const factory RefreshTokenResponse({
    @JsonKey(name: 'access_token') required final String accessToken,
    @JsonKey(name: 'refresh_token') required final String refreshToken,
  }) = _RefreshTokenResponse;

  factory RefreshTokenResponse.fromJson(
    final Map<String, dynamic> json,
  ) => _$RefreshTokenResponseFromJson(json);
}
