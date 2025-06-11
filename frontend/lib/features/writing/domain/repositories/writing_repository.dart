import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_writing.dart';
import '../entities/writing_prompt.dart';

abstract interface class WritingRepository {
  Future<Either<Failure, WritingPrompt>> createWritingPrompt({
    required final WritingPromptRequest request,
  });

  Future<Either<Failure, WritingPrompt>> getWritingPrompt({
    required final int id,
  });

  Future<Either<Failure, List<WritingPrompt>>> listWritingPrompts();

  Future<Either<Failure, WritingPrompt>> updateWritingPrompt({
    required final int id,
    required final WritingPromptRequest request,
  });

  Future<Either<Failure, Success>> deleteWritingPrompt({
    required final int id,
  });

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
