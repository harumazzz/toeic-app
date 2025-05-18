import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

part 'login_user.freezed.dart';
part 'login_user.g.dart';

@riverpod
LoginUser loginUser(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUser(repository);
}

class LoginUser implements UseCase<User, LoginParams> {
  const LoginUser(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(params.email, params.password);
  }
}

@freezed
sealed class LoginParams with _$LoginParams {
  const factory LoginParams({required String email, required String password}) = _LoginParams;
}
