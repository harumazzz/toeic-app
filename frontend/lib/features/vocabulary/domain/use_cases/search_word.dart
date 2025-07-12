import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/word_repository_impl.dart';
import '../entities/word.dart';
import '../repositories/word_repository.dart';

part 'search_word.freezed.dart';
part 'search_word.g.dart';

@riverpod
SearchWord searchWord(final Ref ref) {
  final repository = ref.watch(wordRepositoryProvider);
  return SearchWord(repository);
}

@freezed
abstract class SearchWordParams with _$SearchWordParams {
  const factory SearchWordParams({
    required final String query,
    required final int offset,
    required final int limit,
  }) = _SearchWordParams;
}

class SearchWord implements UseCase<List<Word>, SearchWordParams> {
  const SearchWord(this._repository);

  final WordRepository _repository;

  @override
  Future<Either<Failure, List<Word>>> call(
    final SearchWordParams params,
  ) => _repository.searchWords(
    query: params.query,
    offset: params.offset,
    limit: params.limit,
  );
}
