import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

part 'auth_repository_impl.g.dart';

@riverpod
AuthRepository authRepository(final Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remoteDataSource});
  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, User>> login(
    final String email,
    final String password,
  ) async {
    throw Exception('Not implemented');
  }

  @override
  Future<Either<Failure, User>> register(
    final String email,
    final String password,
    final String name,
  ) async {
    throw Exception('Not implemented');
  }

  @override
  Future<Either<Failure, bool>> forgotPassword(
    final String email,
  ) async {
    throw Exception('Not implemented');
  }

  @override
  Future<Either<Failure, bool>> verifyOtp(
    final String email,
    final String otp,
  ) async {
    throw Exception('Not implemented');
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    throw Exception('Not implemented');
  }
}
