import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_writing.dart';

abstract interface class UserWritingRepository {
  Future<Either<Failure, UserWriting>> createUserWriting({
    required final UserWritingRequest request,
  });

  Future<Either<Failure, UserWriting>> getUserWriting({
    required final int id,
  });

  Future<Either<Failure, List<UserWriting>>> listUserWritingsByUserId({
    required final int userId,
  });

  Future<Either<Failure, List<UserWriting>>> listUserWritingsByPromptId({
    required final int promptId,
  });

  Future<Either<Failure, UserWriting>> updateUserWriting({
    required final int id,
    required final UserWritingUpdateRequest request,
  });

  Future<Either<Failure, Success>> deleteUserWriting({
    required final int id,
  });
}
