import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../injection_container.dart';
import '../../storage/secure_storage_service.dart';
import '../datasources/token_remote_data_source.dart';
import '../dio_client.dart';
import '../models/token_response.dart';

part 'auth_interceptor.g.dart';

@Riverpod(keepAlive: true)
AuthInterceptor authInterceptor(final Ref ref) {
  final secureStorageService = InjectionContainer.get<SecureStorageService>();
  final tokenRemoteDataSource = ref.watch(tokenRemoteDataSourceProvider);
  final dio = ref.watch(dioTokenProvider);
  return AuthInterceptor(
    secureStorageService,
    tokenRemoteDataSource,
    dio,
  );
}

final class AuthInterceptor extends Interceptor {
  const AuthInterceptor(
    this.secureStorageService,
    this.tokenRemoteDataSource,
    this.dio,
  );

  final SecureStorageService secureStorageService;

  final TokenRemoteDataSource tokenRemoteDataSource;

  final Dio dio;

  @override
  Future<void> onRequest(
    final RequestOptions options,
    final RequestInterceptorHandler handler,
  ) async {
    final accessToken = await secureStorageService.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    final DioException err,
    final ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final accessToken = await secureStorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return handler.next(err);
      }
      final refreshToken = await secureStorageService.getRefreshToken();
      final isRefreshTokenExpired = await secureStorageService.isExpired();
      if (refreshToken != null && !isRefreshTokenExpired) {
        try {
          final response = await tokenRemoteDataSource.refreshToken(
            RefreshTokenRequest(refreshToken: refreshToken),
          );
          await secureStorageService.saveAccessToken(response.accessToken);
          await secureStorageService.saveRefreshToken(response.refreshToken);
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${response.accessToken}';
          final result = await dio.fetch(options);
          return handler.resolve(result);
        } catch (e) {
          await secureStorageService.clearAllTokens();
          return handler.reject(err);
        }
      } else {
        await secureStorageService.clearAllTokens();
        return handler.reject(err);
      }
    }
    return super.onError(err, handler);
  }
}
