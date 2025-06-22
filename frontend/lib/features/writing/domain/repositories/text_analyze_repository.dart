import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/text_analyze.dart';

abstract interface class TextAnalyzeRepository {
  Future<Either<Failure, TextAnalyze>> analyzeText({
    required final TextAnalyzeRequest request,
  });
}
