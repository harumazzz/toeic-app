import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/user_writing_repository_impl.dart';
import '../entities/user_writing.dart';
import '../repositories/user_writing_repository.dart';

part 'user_writing_usecases.freezed.dart';
part 'user_writing_usecases.g.dart';

@riverpod
CreateUserWritingUseCase createUserWritingUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return CreateUserWritingUseCase(repository);
}

class CreateUserWritingUseCase
    implements UseCase<UserWriting, UserWritingRequest> {
  const CreateUserWritingUseCase(this._repository);

  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, UserWriting>> call(
    final UserWritingRequest request,
  ) async => _repository.createUserWriting(request: request);
}

@riverpod
GetUserWritingUseCase getUserWritingUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return GetUserWritingUseCase(repository);
}

class GetUserWritingUseCase implements UseCase<UserWriting, int> {
  const GetUserWritingUseCase(this._repository);
  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, UserWriting>> call(
    final int params,
  ) => _repository.getUserWriting(id: params);
}

@riverpod
ListUserWritingsByUserIdUseCase listUserWritingsByUserIdUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return ListUserWritingsByUserIdUseCase(repository);
}

class ListUserWritingsByUserIdUseCase
    implements UseCase<List<UserWriting>, int> {
  const ListUserWritingsByUserIdUseCase(this._repository);
  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, List<UserWriting>>> call(
    final int params,
  ) async => _repository.listUserWritingsByUserId(userId: params);
}

@riverpod
ListUserWritingsByPromptIdUseCase listUserWritingsByPromptIdUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return ListUserWritingsByPromptIdUseCase(repository);
}

class ListUserWritingsByPromptIdUseCase
    implements UseCase<List<UserWriting>, int> {
  const ListUserWritingsByPromptIdUseCase(this._repository);
  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, List<UserWriting>>> call(
    final int params,
  ) async => _repository.listUserWritingsByPromptId(
    promptId: params,
  );
}

@freezed
sealed class UpdateUserWritingParams with _$UpdateUserWritingParams {
  const factory UpdateUserWritingParams({
    required final int id,
    required final UserWritingUpdateRequest request,
  }) = _UpdateUserWritingParams;
}

@riverpod
UpdateUserWritingUseCase updateUserWritingUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return UpdateUserWritingUseCase(repository);
}

class UpdateUserWritingUseCase
    implements UseCase<UserWriting, UpdateUserWritingParams> {
  const UpdateUserWritingUseCase(this._repository);
  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, UserWriting>> call(
    final UpdateUserWritingParams params,
  ) async => _repository.updateUserWriting(
    id: params.id,
    request: params.request,
  );
}

@riverpod
DeleteUserWritingUseCase deleteUserWritingUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return DeleteUserWritingUseCase(repository);
}

class DeleteUserWritingUseCase implements UseCase<Success, int> {
  const DeleteUserWritingUseCase(this._repository);
  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, Success>> call(
    final int id,
  ) async => _repository.deleteUserWriting(id: id);
}

@freezed
sealed class SubmitWritingForEvaluationParams
    with _$SubmitWritingForEvaluationParams {
  const factory SubmitWritingForEvaluationParams({
    required final int userId,
    final int? promptId,
    required final String submissionText,
  }) = _SubmitWritingForEvaluationParams;
}

@riverpod
SubmitWritingForEvaluationUseCase submitWritingForEvaluationUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return SubmitWritingForEvaluationUseCase(repository);
}

class SubmitWritingForEvaluationUseCase
    implements UseCase<UserWriting, SubmitWritingForEvaluationParams> {
  const SubmitWritingForEvaluationUseCase(this._repository);
  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, UserWriting>> call(
    final SubmitWritingForEvaluationParams params,
  ) async => _repository.createUserWriting(
    request: UserWritingRequest(
      userId: params.userId,
      promptId: params.promptId,
      submissionText: params.submissionText,
    ),
  );
}

@freezed
sealed class AddAIFeedbackParams with _$AddAIFeedbackParams {
  const factory AddAIFeedbackParams({
    required final int submissionId,
    required final Map<String, dynamic> aiFeedback,
    required final double aiScore,
  }) = _AddAIFeedbackParams;
}

@riverpod
AddAIFeedbackUseCase addAIFeedbackUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return AddAIFeedbackUseCase(repository);
}

class AddAIFeedbackUseCase
    implements UseCase<UserWriting, AddAIFeedbackParams> {
  const AddAIFeedbackUseCase(this._repository);
  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, UserWriting>> call(
    final AddAIFeedbackParams params,
  ) async => _repository.updateUserWriting(
    id: params.submissionId,
    request: UserWritingUpdateRequest(
      aiFeedback: params.aiFeedback,
      aiScore: params.aiScore,
    ),
  );
}

@riverpod
GetUserWritingProgressUseCase getUserWritingProgressUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return GetUserWritingProgressUseCase(repository);
}

class GetUserWritingProgressUseCase
    implements UseCase<UserWritingProgress, int> {
  const GetUserWritingProgressUseCase(this._repository);
  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, UserWritingProgress>> call(
    final int userId,
  ) async {
    final result = await _repository.listUserWritingsByUserId(userId: userId);
    return result.fold(
      ifLeft: Left.new,
      ifRight: (final writings) {
        if (writings.isEmpty) {
          return const Right(
            UserWritingProgress(
              userId: 0,
              totalSubmissions: 0,
              evaluatedSubmissions: 0,
              recentSubmissions: [],
            ),
          );
        }
        final sortedWritings = List<UserWriting>.from(writings)..sort(
          (final a, final b) => a.submittedAt.compareTo(b.submittedAt),
        );
        final evaluatedWritings = sortedWritings.where(
          (final w) => w.aiScore != null,
        );
        final totalSubmissions = writings.length;
        final evaluatedSubmissions = evaluatedWritings.length;
        var averageScore = null as double?;
        var latestScore = null as double?;
        var improvementTrend = null as double?;
        if (evaluatedWritings.isNotEmpty) {
          final scores = [...evaluatedWritings.map((final w) => w.aiScore!)];
          averageScore =
              scores.reduce((final a, final b) => a + b) / scores.length;
          latestScore = evaluatedWritings.last.aiScore;
          if (evaluatedWritings.length >= 4) {
            final midPoint = evaluatedWritings.length ~/ 2;
            final firstHalf = evaluatedWritings
                .take(midPoint)
                .map((final w) => w.aiScore!);
            final secondHalf = evaluatedWritings
                .skip(midPoint)
                .map((final w) => w.aiScore!);
            final firstHalfAvg =
                firstHalf.reduce((final a, final b) => a + b) /
                firstHalf.length;
            final secondHalfAvg =
                secondHalf.reduce((final a, final b) => a + b) /
                secondHalf.length;
            improvementTrend = secondHalfAvg - firstHalfAvg;
          }
        }
        return Right(
          UserWritingProgress(
            userId: userId,
            totalSubmissions: totalSubmissions,
            evaluatedSubmissions: evaluatedSubmissions,
            averageScore: averageScore,
            latestScore: latestScore,
            improvementTrend: improvementTrend,
            recentSubmissions: [...sortedWritings.take(5)],
            bestSubmission:
                evaluatedWritings.isEmpty
                    ? null
                    : evaluatedWritings.reduce(
                      (final a, final b) =>
                          (a.aiScore ?? 0) > (b.aiScore ?? 0) ? a : b,
                    ),
          ),
        );
      },
    );
  }
}

@freezed
sealed class ReviseWritingSubmissionParams
    with _$ReviseWritingSubmissionParams {
  const factory ReviseWritingSubmissionParams({
    required final int submissionId,
    required final String revisedText,
  }) = _ReviseWritingSubmissionParams;
}

@riverpod
ReviseWritingSubmissionUseCase reviseWritingSubmissionUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return ReviseWritingSubmissionUseCase(repository);
}

class ReviseWritingSubmissionUseCase
    implements UseCase<UserWriting, ReviseWritingSubmissionParams> {
  const ReviseWritingSubmissionUseCase(this._repository);
  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, UserWriting>> call(
    final ReviseWritingSubmissionParams params,
  ) async => _repository.updateUserWriting(
    id: params.submissionId,
    request: UserWritingUpdateRequest(
      submissionText: params.revisedText,
    ),
  );
}

@freezed
sealed class UserWritingProgress with _$UserWritingProgress {
  const factory UserWritingProgress({
    required final int userId,
    required final int totalSubmissions,
    required final int evaluatedSubmissions,
    final double? averageScore,
    final double? latestScore,
    final double? improvementTrend,
    required final List<UserWriting> recentSubmissions,
    final UserWriting? bestSubmission,
  }) = _UserWritingProgress;
}

extension UserWritingProgressExtension on UserWritingProgress {
  bool get hasProgress => totalSubmissions > 0;

  bool get hasEvaluations => evaluatedSubmissions > 0;

  bool get isImproving => improvementTrend != null && improvementTrend! > 0;
}
