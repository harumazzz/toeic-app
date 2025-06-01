import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

part 'login_user.freezed.dart';
part 'login_user.g.dart';

@riverpod
LoginUser loginUser(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUser(repository);
}

class LoginUser implements UseCase<User, LoginParams> {
  const LoginUser(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(
    final LoginParams params,
  ) async => repository.login(
    params.email,
    params.password,
  );
}

@freezed
sealed class LoginParams with _$LoginParams {
  const factory LoginParams({
    required final String email,
    required final String password,
  }) = _LoginParams;
}
