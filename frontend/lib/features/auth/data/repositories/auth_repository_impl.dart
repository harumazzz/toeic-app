import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

part 'auth_repository_impl.g.dart';

@riverpod
AuthRepository authRepository(final Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorageService = InjectionContainer.get<SecureStorageService>();
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    secureStorageService: secureStorageService,
  );
}

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorageService,
  });

  final AuthRemoteDataSource remoteDataSource;

  final SecureStorageService secureStorageService;

  @override
  Future<Either<Failure, User>> login(
    final String email,
    final String password,
  ) async {
    try {
      final result = await remoteDataSource.login(
        LoginRequest(email: email, password: password),
      );
      await secureStorageService.saveAccessToken(result.accessToken);
      await secureStorageService.saveRefreshToken(result.refreshToken);
      return Right(result.user.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(
          Failure.authenticationFailure(
            message: e.message ?? 'Invalid credentials',
          ),
        );
      } else if (e.response?.statusCode == 500) {
        return Left(
          Failure.serverFailure(
            message: e.message ?? 'Server error, please try again later',
          ),
        );
      } else {
        return Left(
          Failure.networkFailure(message: e.message ?? 'Network error'),
        );
      }
    } on Exception catch (e) {
      return Left(Failure.authenticationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register(
    final String email,
    final String password,
    final String username,
  ) async {
    try {
      final user = await remoteDataSource.register(
        RegisterRequest(
          email: email,
          password: password,
          username: username,
        ),
      );
      return Right(user.user.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return Left(
          Failure.authenticationFailure(
            message: e.message ?? 'Invalid registration data',
          ),
        );
      } else if (e.response?.statusCode == 500) {
        return Left(
          Failure.serverFailure(
            message: e.message ?? 'Server error, please try again later',
          ),
        );
      } else {
        return Left(
          Failure.networkFailure(message: e.message ?? 'Network error'),
        );
      }
    } on Exception catch (e) {
      return Left(Failure.authenticationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Success>> logout() async {
    try {
      await remoteDataSource.logout();
      await secureStorageService.deleteAccessToken();
      await secureStorageService.deleteRefreshToken();
      return const Right(Success());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(
          Failure.authenticationFailure(
            message: e.message ?? 'Not authenticated',
          ),
        );
      } else if (e.response?.statusCode == 500) {
        return Left(
          Failure.serverFailure(
            message: e.message ?? 'Server error, please try again later',
          ),
        );
      } else {
        return Left(
          Failure.networkFailure(message: e.message ?? 'Network error'),
        );
      }
    } on Exception catch (e) {
      return Left(Failure.authenticationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(
          Failure.authenticationFailure(
            message: e.message ?? 'Not authenticated',
          ),
        );
      } else if (e.response?.statusCode == 500) {
        return Left(
          Failure.serverFailure(
            message: e.message ?? 'Server error, please try again later',
          ),
        );
      } else {
        return Left(
          Failure.networkFailure(message: e.message ?? 'Network error'),
        );
      }
    } on Exception catch (e) {
      return Left(Failure.authenticationFailure(message: e.toString()));
    }
  }
}
