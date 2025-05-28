import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/response_interceptor.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
DioClient dioClient(final Ref ref) {
  final loggingInterceptor = ref.watch(loggingInterceptorProvider);
  final authInterceptor = ref.watch(authInterceptorProvider);
  final responseInterceptor = ref.watch(responseInterceptorProvider);
  final dio = Dio();
  dio.interceptors.addAll([
    authInterceptor,
    responseInterceptor,
    loggingInterceptor,
  ]);
  dio.options = BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    contentType: Headers.jsonContentType,
  );
  return DioClient(dio);
}

@Riverpod(keepAlive: true)
Dio dioToken(final Ref ref) {
  final loggingInterceptor = ref.watch(loggingInterceptorProvider);
  final dio = Dio();
  dio.interceptors.add(
    loggingInterceptor,
  );
  dio.options = BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    contentType: Headers.jsonContentType,
  );
  return dio;
}

class DioClient {
  const DioClient(final Dio dio) : _dio = dio;

  final Dio _dio;

  Dio get dio => _dio;

  Future<Response> get(
    final String path, {
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onReceiveProgress,
  }) => _dio.get(
    path,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onReceiveProgress: onReceiveProgress,
  );

  Future<Response> post(
    final String path, {
    final dynamic data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onSendProgress,
    final ProgressCallback? onReceiveProgress,
  }) => _dio.post(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );

  Future<Response> put(
    final String path, {
    final dynamic data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onSendProgress,
    final ProgressCallback? onReceiveProgress,
  }) => _dio.put(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );

  Future<Response> delete(
    final String path, {
    final dynamic data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
  }) => _dio.delete(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );
}
