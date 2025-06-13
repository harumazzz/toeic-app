import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/speaking.dart';

abstract interface class SpeakingRepository {
  Future<Either<Failure, Speaking>> createSession({
    required final SpeakingRequest speakingRequest,
  });

  Future<Either<Failure, Speaking>> getSessionById({
    required final int id,
  });

  Future<Either<Failure, Speaking>> updateSession({
    required final int id,
    required final SpeakingRequest speakingRequest,
  });

  Future<Either<Failure, Success>> deleteSession({
    required final int id,
  });

  Future<Either<Failure, List<SpeakingTurn>>> getSpeakingTurns({
    required final int sessionId,
  });

  Future<Either<Failure, SpeakingTurn>> createNewTurn({
    required final SpeakingTurnRequest request,
  });

  Future<Either<Failure, SpeakingTurn>> getTurnById({
    required final int id,
  });

  Future<Either<Failure, SpeakingTurn>> updateTurn({
    required final int id,
    required final SpeakingTurnRequest request,
  });

  Future<Either<Failure, Success>> deleteTurn({
    required final int id,
  });

  Future<Either<Failure, List<Speaking>>> getSpeakingSessions({
    required final int userId,
  });
}
