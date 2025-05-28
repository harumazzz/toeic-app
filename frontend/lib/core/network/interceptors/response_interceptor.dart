import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/api_response.dart';

part 'response_interceptor.g.dart';

@Riverpod(keepAlive: true)
ResponseInterceptor responseInterceptor(
  final Ref ref,
) => const ResponseInterceptor();

final class ResponseInterceptor extends Interceptor {
  const ResponseInterceptor();

  @override
  Future<void> onResponse(
    final Response response,
    final ResponseInterceptorHandler handler,
  ) async {
    try {
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('status') &&
            responseData.containsKey('message')) {
          final apiResponse = ApiResponse<dynamic>.fromJson(
            responseData,
            (final json) => json,
          );
          response.data = apiResponse;
          if (apiResponse.status == 'error') {
            final error = DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              message: apiResponse.message,
            );
            return handler.reject(error);
          }
        }
      }
    } catch (e) {
      final error = DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to parse API response: $e',
      );
      return handler.reject(error);
    }
    return super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    final DioException err,
    final ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.data is Map<String, dynamic>) {
      try {
        final responseData = err.response!.data as Map<String, dynamic>;
        if (responseData.containsKey('status') &&
            responseData.containsKey('message')) {
          final apiResponse = ApiResponse<dynamic>.fromJson(
            responseData,
            (final json) => json,
          );
          final enhancedError = DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            message: apiResponse.message,
            error: apiResponse.error,
          );

          return handler.next(enhancedError);
        }
      } catch (e) {
        // If parsing fails, we still want to propagate the original error
      }
    }

    return super.onError(err, handler);
  }
}
