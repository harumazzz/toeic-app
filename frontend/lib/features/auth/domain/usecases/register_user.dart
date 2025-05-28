import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

part 'register_user.freezed.dart';
part 'register_user.g.dart';

@riverpod
RegisterUser registerUser(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUser(repository);
}

final class RegisterUser implements UseCase<User, RegisterParams> {
  const RegisterUser(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(
    final RegisterParams params,
  ) async => repository.register(
    params.email,
    params.password,
    params.name,
  );
}

@freezed
sealed class RegisterParams with _$RegisterParams {
  const factory RegisterParams({
    required final String email,
    required final String password,
    required final String name,
  }) = _RegisterParams;
}
