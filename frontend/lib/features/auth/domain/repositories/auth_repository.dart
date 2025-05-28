import 'package:dart_either/dart_either.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(
    final String email,
    final String password,
  );

  Future<Either<Failure, User>> register(
    final String email,
    final String password,
    final String name,
  );

  Future<Either<Failure, bool>> forgotPassword(
    final String email,
  );

  Future<Either<Failure, bool>> verifyOtp(
    final String email,
    final String otp,
  );

  Future<void> logout();

  Future<Either<Failure, User?>> getCurrentUser();
}
