import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dio_client.dart';
import '../models/token_response.dart';

part 'token_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
TokenRemoteDataSource tokenRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioTokenProvider);
  return TokenRemoteDataSource(dio);
}

@RestApi()
abstract class TokenRemoteDataSource {
  factory TokenRemoteDataSource(
    final Dio dio,
  ) = _TokenRemoteDataSource;

  @POST('/api/auth/refresh-token')
  Future<RefreshTokenResponse> refreshToken(
    final RefreshTokenRequest body,
  );
}
