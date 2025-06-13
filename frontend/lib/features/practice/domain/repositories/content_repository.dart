import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/content.dart';

abstract interface class ContentRepository {
  Future<Either<Failure, Content>> getContentById({
    required final int contentId,
  });

  Future<Either<Failure, List<Content>>> getContentByParts({
    required final int partId,
  });
}
