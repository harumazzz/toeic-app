import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_interceptor.g.dart';

@Riverpod(keepAlive: true)
AuthInterceptor authInterceptor(final Ref ref) => AuthInterceptor();

final class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  @override
  void onRequest(
    final RequestOptions options,
    final RequestInterceptorHandler handler,
  ) {
    // if (_accessToken != null) {
    //   options.headers['Authorization'] = 'Bearer $_accessToken';
    // }
    return super.onRequest(options, handler);
  }

  @override
  void onError(
    final DioException err,
    final ErrorInterceptorHandler handler,
  ) {
    // Handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      // Implement token refresh logic here
      // For now, we'll just let the error propagate
    }
    return super.onError(err, handler);
  }
}
