import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/grammar_repository_impl.dart';
import '../entities/grammar.dart';
import '../repositories/grammar_repository.dart';

part 'get_grammars.freezed.dart';
part 'get_grammars.g.dart';

@freezed
abstract class GetGrammarsParams with _$GetGrammarsParams {
  const factory GetGrammarsParams({
    required final int limit,
    required final int offset,
  }) = _GetGrammarsParams;
}

@freezed
abstract class GetGrammarsByLevelParams with _$GetGrammarsByLevelParams {
  const factory GetGrammarsByLevelParams({
    required final int level,
    required final int limit,
    required final int offset,
  }) = _GetGrammarsByLevelParams;
}

@freezed
abstract class GetGrammarsByTagParams with _$GetGrammarsByTagParams {
  const factory GetGrammarsByTagParams({
    required final int tag,
    required final int limit,
    required final int offset,
  }) = _GetGrammarsByTagParams;
}

@riverpod
GetGrammars getGrammars(final Ref ref) {
  final repository = ref.watch(grammarRepositoryProvider);
  return GetGrammars(repository);
}

@riverpod
GetGrammarsByLevel getGrammarsByLevel(final Ref ref) {
  final repository = ref.watch(grammarRepositoryProvider);
  return GetGrammarsByLevel(repository);
}

@riverpod
GetGrammarsByTag getGrammarsByTag(final Ref ref) {
  final repository = ref.watch(grammarRepositoryProvider);
  return GetGrammarsByTag(repository);
}

class GetGrammars implements UseCase<List<Grammar>, GetGrammarsParams> {
  const GetGrammars(this._grammarRepository);

  final GrammarRepository _grammarRepository;

  @override
  Future<Either<Failure, List<Grammar>>> call(
    final GetGrammarsParams params,
  ) async => _grammarRepository.getAllGrammars(
    limit: params.limit,
    offset: params.offset,
  );
}

class GetGrammarsByLevel
    implements UseCase<List<Grammar>, GetGrammarsByLevelParams> {
  const GetGrammarsByLevel(this._grammarRepository);

  final GrammarRepository _grammarRepository;

  @override
  Future<Either<Failure, List<Grammar>>> call(
    final GetGrammarsByLevelParams params,
  ) async => _grammarRepository.getAllGrammarsByLevel(
    level: params.level,
    limit: params.limit,
    offset: params.offset,
  );
}

class GetGrammarsByTag
    implements UseCase<List<Grammar>, GetGrammarsByTagParams> {
  const GetGrammarsByTag(this._grammarRepository);

  final GrammarRepository _grammarRepository;

  @override
  Future<Either<Failure, List<Grammar>>> call(
    final GetGrammarsByTagParams params,
  ) async => _grammarRepository.getAllGrammarsByTag(
    tag: params.tag,
    limit: params.limit,
    offset: params.offset,
  );
}

@riverpod
GetRelatedGrammars getRelatedGrammars(final Ref ref) {
  final repository = ref.watch(grammarRepositoryProvider);
  return GetRelatedGrammars(repository);
}

@freezed
abstract class GetRelatedGrammarsParams with _$GetRelatedGrammarsParams {
  const factory GetRelatedGrammarsParams({
    required final List<int> ids,
  }) = _GetRelatedGrammarsParams;
}

class GetRelatedGrammars
    implements UseCase<List<Grammar>, GetRelatedGrammarsParams> {
  const GetRelatedGrammars(this._grammarRepository);

  final GrammarRepository _grammarRepository;

  @override
  Future<Either<Failure, List<Grammar>>> call(
    final GetRelatedGrammarsParams params,
  ) async => _grammarRepository.getRelatedGrammars(
    ids: params.ids,
  );
}
