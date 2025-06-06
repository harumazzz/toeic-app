import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/grammar_repository_impl.dart';
import '../entities/grammar.dart';
import '../repositories/grammar_repository.dart';

part 'get_grammar.freezed.dart';
part 'get_grammar.g.dart';

@freezed
sealed class GetGrammarParams with _$GetGrammarParams {
  const factory GetGrammarParams({
    required final int id,
  }) = _GetGrammarParams;
}

@riverpod
GetGrammar getGrammar(final Ref ref) {
  final repository = ref.watch(grammarRepositoryProvider);
  return GetGrammar(repository);
}

@riverpod
GetRandomGrammar getRandomGrammar(final Ref ref) {
  final repository = ref.watch(grammarRepositoryProvider);
  return GetRandomGrammar(repository);
}

class GetGrammar implements UseCase<Grammar, GetGrammarParams> {
  const GetGrammar(this._grammarRepository);

  final GrammarRepository _grammarRepository;

  @override
  Future<Either<Failure, Grammar>> call(
    final GetGrammarParams params,
  ) async => _grammarRepository.getGrammarById(
    id: params.id,
  );
}

class GetRandomGrammar implements UseCase<Grammar, NoParams> {
  const GetRandomGrammar(this._grammarRepository);

  final GrammarRepository _grammarRepository;

  @override
  Future<Either<Failure, Grammar>> call(
    final NoParams params,
  ) async => _grammarRepository.getRandomGrammar();
}
