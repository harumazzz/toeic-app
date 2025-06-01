import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

part 'get_user.g.dart';

@riverpod
GetUser getUser(final Ref ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return GetUser(authRepository);
}

class GetUser implements UseCase<User, NoParams> {
  const GetUser(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(
    final NoParams params,
  ) async => repository.getUser();
}
