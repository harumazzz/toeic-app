import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/writing_repository_impl.dart';
import '../entities/writing_prompt.dart';
import '../repositories/writing_repository.dart';

part 'get_writing_prompts_use_case.g.dart';

@riverpod
GetWritingPromptsUseCase getWritingPromptsUseCase(
  final Ref ref,
) {
  final repository = ref.watch(writingRepositoryProvider);
  return GetWritingPromptsUseCase(repository);
}

class GetWritingPromptsUseCase
    implements UseCase<List<WritingPrompt>, NoParams> {
  const GetWritingPromptsUseCase(this._repository);

  final WritingRepository _repository;

  @override
  Future<Either<Failure, List<WritingPrompt>>> call(
    final NoParams params,
  ) async => _repository.listWritingPrompts();
}
