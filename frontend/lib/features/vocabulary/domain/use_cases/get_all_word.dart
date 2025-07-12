import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/word_repository_impl.dart';
import '../entities/word.dart';
import '../repositories/word_repository.dart';

part 'get_all_word.g.dart';
part 'get_all_word.freezed.dart';

@riverpod
GetAllWord getAllWord(final Ref ref) {
  final wordRepository = ref.watch(wordRepositoryProvider);
  return GetAllWord(wordRepository);
}

@freezed
abstract class GetAllWordParams with _$GetAllWordParams {
  const factory GetAllWordParams({
    required final int offset,
    required final int limit,
  }) = _GetAllWordParams;
}

class GetAllWord implements UseCase<List<Word>, GetAllWordParams> {
  const GetAllWord(this._repository);

  final WordRepository _repository;

  @override
  Future<Either<Failure, List<Word>>> call(
    final GetAllWordParams params,
  ) async => _repository.getAllWords(
    offset: params.offset,
    limit: params.limit,
  );
}
