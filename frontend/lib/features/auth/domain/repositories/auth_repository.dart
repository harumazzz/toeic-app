import 'package:dart_either/dart_either.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register(String email, String password, String name);
  Future<Either<Failure, bool>> forgotPassword(String email);
  Future<Either<Failure, bool>> verifyOtp(String email, String otp);
  Future<void> logout();
  Future<Either<Failure, User?>> getCurrentUser();
}
