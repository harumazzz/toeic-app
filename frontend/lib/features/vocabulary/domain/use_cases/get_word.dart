import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/word_repository_impl.dart';
import '../entities/word.dart';
import '../repositories/word_repository.dart';

part 'get_word.g.dart';
part 'get_word.freezed.dart';

@riverpod
GetWord getWord(final Ref ref) {
  final wordRepository = ref.watch(wordRepositoryProvider);
  return GetWord(wordRepository);
}

@freezed
sealed class GetWordParams with _$GetWordParams {
  const factory GetWordParams({
    required final int id,
  }) = _GetWordParams;
}

class GetWord implements UseCase<Word, GetWordParams> {
  const GetWord(this._repository);

  final WordRepository _repository;

  @override
  Future<Either<Failure, Word>> call(
    final GetWordParams params,
  ) async => _repository.getWordById(id: params.id);
}
