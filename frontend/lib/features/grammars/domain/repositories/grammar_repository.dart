import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/grammar.dart';

abstract class GrammarRepository {
  Future<Either<Failure, List<Grammar>>> getAllGrammars({
    required final int limit,
    required final int offset,
  });

  Future<Either<Failure, List<Grammar>>> getAllGrammarsByLevel({
    required final int level,
    required final int limit,
    required final int offset,
  });

  Future<Either<Failure, List<Grammar>>> getAllGrammarsByTag({
    required final int tag,
    required final int limit,
    required final int offset,
  });

  Future<Either<Failure, List<Grammar>>> searchGrammars({
    required final String query,
    required final int limit,
    required final int offset,
  });

  Future<Either<Failure, Grammar>> getRandomGrammar();

  Future<Either<Failure, Grammar>> getGrammarById({
    required final int id,
  });

  Future<Either<Failure, List<Grammar>>> getRelatedGrammars({
    required final List<int> ids,
  });
}
