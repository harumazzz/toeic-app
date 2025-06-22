import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/text_analyze_repository_impl.dart';
import '../entities/text_analyze.dart';
import '../repositories/text_analyze_repository.dart';

part 'analyze_usecases.g.dart';

@riverpod
AnalyzeText analyzeText(
  final Ref ref,
) {
  final repository = ref.watch(textAnalyzeRepositoryProvider);
  return AnalyzeText(repository);
}

class AnalyzeText implements UseCase<TextAnalyze, TextAnalyzeRequest> {

  const AnalyzeText(this._repository);

  final TextAnalyzeRepository _repository;

  @override
  Future<Either<Failure, TextAnalyze>> call(
    final TextAnalyzeRequest params
  ) async => _repository.analyzeText(
    request: params,
  );
}
