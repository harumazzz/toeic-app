import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

part 'auth_remote_data_source.g.dart';

@riverpod
AuthRemoteDataSource authRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return AuthRemoteDataSource(dio);
}

@RestApi()
abstract class AuthRemoteDataSource {
  factory AuthRemoteDataSource(
    final Dio dio,
  ) = _AuthRemoteDataSource;

  @POST('/api/auth/login')
  Future<LoginResponse> login(@Body() final LoginRequest body);

  @POST('/api/auth/register')
  Future<RegisterResponse> register(
    @Body() final RegisterRequest body,
  );

  @POST('/api/auth/logout')
  Future<String> logout();

  @GET('/api/v1/users/me')
  Future<UserModel> getCurrentUser();
}
