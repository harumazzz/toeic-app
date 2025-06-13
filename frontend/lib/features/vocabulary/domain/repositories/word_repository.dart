import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/word.dart';

abstract interface class WordRepository {
  Future<Either<Failure, List<Word>>> getAllWords({
    required final int offset,
    required final int limit,
  });

  Future<Either<Failure, Word>> getWordById({
    required final int id,
  });

  Future<Either<Failure, List<Word>>> searchWords({
    required final String query,
    required final int offset,
    required final int limit,
  });
}
