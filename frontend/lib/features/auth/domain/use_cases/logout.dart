import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

part 'logout.g.dart';

@riverpod
LogoutUseCase logoutUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
}

class LogoutUseCase implements UseCase<Success, NoParams> {
  const LogoutUseCase(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, Success>> call(
    final NoParams params,
  ) async => repository.logout();
}
