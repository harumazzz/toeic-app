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
  Future<void> onRequest(
    final RequestOptions options,
    final RequestInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      await logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
      await logger.d('Headers:');
      options.headers.forEach(
        (final k, final v) async => logger.d('$k: $v'),
      );
      if (options.data != null) {
        await logger.d('Body: ${options.data}');
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(
    final Response response,
    final ResponseInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      final path = response.requestOptions.path;
      await logger.d(
        'RESPONSE[${response.statusCode}] => PATH: $path',
      );
      await logger.d(
        'Response: ${response.data}',
      );
    }
    return super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    final DioException err,
    final ErrorInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      final path = err.requestOptions.path;
      await logger.e(
        'ERROR[${err.response?.statusCode}] => PATH: $path',
      );
      await logger.e(
        'Error: ${err.error}, Message: ${err.message}',
      );
      if (err.response != null) {
        await logger.e('Response data: ${err.response!.data}');
      }
    }
    return super.onError(err, handler);
  }
}
