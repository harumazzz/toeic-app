import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../logger/logger_service.dart';

part 'logging_interceptor.g.dart';

@Riverpod(keepAlive: true)
LoggingInterceptor loggingInterceptor(final Ref ref) {
  final logger = ref.read(loggerServiceProvider);
  return LoggingInterceptor(logger);
}

final class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor(this.logger);

  final LoggerService logger;

  @override
  void onRequest(
    final RequestOptions options,
    final RequestInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      logger
        ..d('REQUEST[${options.method}] => PATH: ${options.path}')
        ..d('Headers:');
      options.headers.forEach((final k, final v) => logger.d('$k: $v'));
      if (options.data != null) {
        logger.d('Body: ${options.data}');
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(
    final Response response,
    final ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final path = response.requestOptions.path;
      logger
        ..d(
          'RESPONSE[${response.statusCode}] => PATH: $path',
        )
        ..d(
          'Response: ${response.data}',
        );
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(final DioException err, final ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final path = err.requestOptions.path;
      logger
        ..e(
          'ERROR[${err.response?.statusCode}] => PATH: $path',
        )
        ..e(
          'Error: ${err.error}, Message: ${err.message}',
        );
      if (err.response != null) {
        logger.e('Response data: ${err.response!.data}');
      }
    }
    return super.onError(err, handler);
  }
}
