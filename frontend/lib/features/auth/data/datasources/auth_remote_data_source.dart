import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

part 'auth_remote_data_source.g.dart';

@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return AuthRemoteDataSource(dio);
}

@RestApi()
abstract class AuthRemoteDataSource {
  factory AuthRemoteDataSource(Dio dio) = _AuthRemoteDataSource;

  @POST('/auth/login')
  Future<LoginResponse> login(@Body() LoginRequest body);

  @POST('/auth/register')
  Future<RegisterResponse> register(@Body() RegisterRequest body);

  @POST('/auth/forgot-password')
  Future<ForgotPasswordResponse> forgotPassword(@Body() ForgotPasswordRequest body);

  @POST('/auth/logout')
  Future<void> logout();

  @GET('/auth/me')
  Future<UserModel?> getCurrentUser();
}
