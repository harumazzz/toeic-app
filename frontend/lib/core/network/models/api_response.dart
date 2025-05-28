import 'package:freezed_annotation/freezed_annotation.dart';

import '../../error/exceptions.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@Freezed(genericArgumentFactories: true)
sealed class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required final String status,
    required final String message,
    @JsonKey(includeIfNull: false) final T? data,
    @JsonKey(includeIfNull: false) final String? error,
  }) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    final Map<String, dynamic> json,
    final T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson<T>(json, fromJsonT);
}

extension ApiResponseExtension<T> on ApiResponse<T> {
  bool get isSuccess => status == 'success';

  bool get isError => status == 'error';

  T get dataOrThrow {
    if (isError) {
      throw ApiException(message: message, error: error);
    }
    return data as T;
  }

  T? get dataOrNull {
    if (isError) {
      return null;
    }
    return data;
  }
}
