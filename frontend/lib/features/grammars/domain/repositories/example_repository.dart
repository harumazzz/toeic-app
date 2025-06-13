import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/example.dart';

abstract interface class ExampleRepository {
  Future<Either<Failure, List<Example>>> getExamples();

  Future<Either<Failure, List<Example>>> getExamplesByIds({
    required final List<int> ids,
  });
}
