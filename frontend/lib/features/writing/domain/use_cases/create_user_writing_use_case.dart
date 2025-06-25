import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/user_writing_repository_impl.dart';
import '../entities/user_writing.dart';
import '../repositories/user_writing_repository.dart';

part 'create_user_writing_use_case.g.dart';

@riverpod
CreateUserWritingUseCase createUserWritingUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return CreateUserWritingUseCase(repository);
}

class CreateUserWritingUseCase
    implements UseCase<UserWriting, UserWritingRequest> {
  const CreateUserWritingUseCase(this._repository);

  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, UserWriting>> call(
    final UserWritingRequest request,
  ) async => _repository.createUserWriting(
    request: request,
  );
}
