import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/grammar_repository_impl.dart';
import '../entities/grammar.dart';
import '../repositories/grammar_repository.dart';

part 'search_grammar.freezed.dart';
part 'search_grammar.g.dart';

@freezed
abstract class SearchGrammarsParams with _$SearchGrammarsParams {
  const factory SearchGrammarsParams({
    required final String query,
    required final int limit,
    required final int offset,
  }) = _SearchGrammarsParams;
}

@riverpod
SearchGrammar searchGrammar(final Ref ref) {
  final repository = ref.watch(grammarRepositoryProvider);
  return SearchGrammar(repository);
}

class SearchGrammar implements UseCase<List<Grammar>, SearchGrammarsParams> {
  const SearchGrammar(this._grammarRepository);

  final GrammarRepository _grammarRepository;

  @override
  Future<Either<Failure, List<Grammar>>> call(
    final SearchGrammarsParams params,
  ) async => _grammarRepository.searchGrammars(
    query: params.query,
    limit: params.limit,
    offset: params.offset,
  );
}
