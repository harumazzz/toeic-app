import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/user_writing_repository_impl.dart';
import '../../data/repositories/writing_repository_impl.dart';
import '../entities/user_writing.dart';
import '../entities/writing_prompt.dart';
import '../repositories/user_writing_repository.dart';
import '../repositories/writing_repository.dart';

part 'writing_composite_usecases.g.dart';
part 'writing_composite_usecases.freezed.dart';

@freezed
sealed class WritingPracticeSessionRequest
    with _$WritingPracticeSessionRequest {
  const factory WritingPracticeSessionRequest({
    required final int userId,
    final int? promptId,
    final String? difficultyLevel,
    final String? topic,
    required final String submissionText,
  }) = _WritingPracticeSessionRequest;
}

@riverpod
WritingPracticeSessionUseCase writingPracticeSessionUseCase(
  final Ref ref,
) {
  final writingRepository = ref.watch(writingRepositoryProvider);
  final userWritingRepository = ref.watch(userWritingRepositoryProvider);
  return WritingPracticeSessionUseCase(
    userWritingRepository: userWritingRepository,
    writingRepository: writingRepository,
  );
}

class WritingPracticeSessionUseCase
    implements UseCase<WritingSessionResult, WritingPracticeSessionRequest> {
  const WritingPracticeSessionUseCase({
    required final WritingRepository writingRepository,
    required final UserWritingRepository userWritingRepository,
  }) : _writingRepository = writingRepository,
       _userWritingRepository = userWritingRepository;

  final WritingRepository _writingRepository;

  final UserWritingRepository _userWritingRepository;

  @override
  Future<Either<Failure, WritingSessionResult>> call(
    final WritingPracticeSessionRequest request,
  ) async {
    var selectedPrompt = null as WritingPrompt?;
    if (request.promptId != null) {
      final promptResult = await _writingRepository.getWritingPrompt(
        id: request.promptId!,
      );
      final promptOrFailure = promptResult.fold(
        ifLeft: Left.new,
        ifRight: (final prompt) {
          selectedPrompt = prompt;
          return Right(prompt);
        },
      );
      if (promptOrFailure is Left) {
        return Left((promptOrFailure as Left<Failure, WritingPrompt>).value);
      }
    } else {
      final allPromptsResult = await _writingRepository.listWritingPrompts();
      final randomPromptResult = allPromptsResult.fold(
        ifLeft: Left.new,
        ifRight: (final prompts) {
          if (prompts.isEmpty) {
            return const Left(
              ServerFailure(message: 'No writing prompts available'),
            );
          }
          var filteredPrompts = prompts;
          if (request.difficultyLevel != null) {
            filteredPrompts = [
              ...filteredPrompts.where(
                (final p) =>
                    p.difficultyLevel?.toLowerCase() ==
                    request.difficultyLevel!.toLowerCase(),
              ),
            ];
          }
          if (request.topic != null) {
            filteredPrompts = [
              ...filteredPrompts.where(
                (final p) =>
                    p.topic?.toLowerCase() == request.topic!.toLowerCase(),
              ),
            ];
          }

          if (filteredPrompts.isEmpty) {
            return const Left(
              ServerFailure(message: 'No prompts found matching criteria'),
            );
          }
          final randomIndex =
              DateTime.now().millisecondsSinceEpoch % filteredPrompts.length;
          selectedPrompt = filteredPrompts[randomIndex];
          return Right(selectedPrompt!);
        },
      );
      if (randomPromptResult is Left) {
        return Left((randomPromptResult as Left<Failure, WritingPrompt>).value);
      }
    }
    final submissionResult = await _userWritingRepository.createUserWriting(
      request: UserWritingRequest(
        userId: request.userId,
        promptId: selectedPrompt!.id,
        submissionText: request.submissionText,
      ),
    );
    return submissionResult.fold(
      ifLeft: Left.new,
      ifRight:
          (final userWriting) => Right(
            WritingSessionResult(
              prompt: selectedPrompt!,
              submission: userWriting,
              sessionStartTime: DateTime.now().subtract(
                const Duration(minutes: 30),
              ),
              sessionEndTime: DateTime.now(),
            ),
          ),
    );
  }
}

@freezed
sealed class BatchEvaluateWritingsRequest with _$BatchEvaluateWritingsRequest {
  const factory BatchEvaluateWritingsRequest({
    required final List<int> submissionIds,
    required final EvaluationCriteria evaluationCriteria,
  }) = _BatchEvaluateWritingsRequest;
}

@riverpod
BatchEvaluateWritingsUseCase batchEvaluateWritingsUseCase(
  final Ref ref,
) {
  final userWritingRepository = ref.watch(userWritingRepositoryProvider);
  return BatchEvaluateWritingsUseCase(
    userWritingRepository: userWritingRepository,
  );
}

class BatchEvaluateWritingsUseCase
    implements UseCase<BatchEvaluationResult, BatchEvaluateWritingsRequest> {
  const BatchEvaluateWritingsUseCase({
    required final UserWritingRepository userWritingRepository,
  }) : _userWritingRepository = userWritingRepository;

  final UserWritingRepository _userWritingRepository;

  @override
  Future<Either<Failure, BatchEvaluationResult>> call(
    final BatchEvaluateWritingsRequest request,
  ) async {
    final List<UserWriting> successfulEvaluations = [];
    final List<EvaluationFailure> failedEvaluations = [];
    for (final submissionId in request.submissionIds) {
      final submissionResult = await _userWritingRepository.getUserWriting(
        id: submissionId,
      );
      await submissionResult.fold(
        ifLeft: (final failure) async {
          failedEvaluations.add(
            EvaluationFailure(
              submissionId: submissionId,
              failure: failure,
            ),
          );
        },
        ifRight: (final submission) async {
          final mockFeedback = _generateMockAIFeedback(
            submission.submissionText,
            request.evaluationCriteria,
          );
          final mockScore = _calculateMockScore(submission.submissionText);
          final updateResult = await _userWritingRepository.updateUserWriting(
            id: submissionId,
            request: UserWritingUpdateRequest(
              aiFeedback: mockFeedback,
              aiScore: mockScore,
              evaluatedAt: DateTime.now(),
            ),
          );
          updateResult.fold(
            ifLeft: (final failure) {
              failedEvaluations.add(
                EvaluationFailure(
                  submissionId: submissionId,
                  failure: failure,
                ),
              );
            },
            ifRight: successfulEvaluations.add,
          );
        },
      );
    }
    return Right(
      BatchEvaluationResult(
        totalSubmissions: request.submissionIds.length,
        successfulEvaluations: successfulEvaluations,
        failedEvaluations: failedEvaluations,
        evaluationCriteria: request.evaluationCriteria,
        processingTime: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> _generateMockAIFeedback(
    final String text,
    final EvaluationCriteria criteria,
  ) => {
    'grammar': {
      'score': 8,
      'feedback': 'Good use of grammar with minor issues in complex sentences.',
      'errors': ['Tense consistency in paragraph 2'],
      'suggestions': [
        'Review past perfect usage',
        'Check subject-verb agreement',
      ],
    },
    'vocabulary': {
      'score': 7,
      'feedback': 'Adequate vocabulary range with room for improvement.',
      'strengths': ['Good use of topic-specific terms'],
      'suggestions': [
        'Use more varied synonyms',
        'Include more advanced vocabulary',
      ],
    },
    'coherence': {
      'score': 8,
      'feedback': 'Well-organized with clear paragraph structure.',
      'strengths': ['Good use of transition words', 'Clear topic sentences'],
      'suggestions': ['Improve conclusion strength'],
    },
    'task_response': {
      'score': 9,
      'feedback': 'Excellent response addressing all parts of the prompt.',
      'coverage': 'All main points addressed with examples',
    },
    'overall_feedback':
        // ignore: lines_longer_than_80_chars
        'Strong writing with good structure and ideas. Focus on expanding vocabulary and refining grammar in complex sentences.',
    'writing_length': text.split(' ').length,
    'estimated_level': criteria.targetLevel,
  };

  double _calculateMockScore(final String text) {
    final wordCount = text.split(' ').length;
    const baseScore = 5.0;
    var score = baseScore;
    if (wordCount > 50) {
      score += 1.0;
    }
    if (wordCount > 100) {
      score += 1.0;
    }
    if (wordCount > 200) {
      score += 0.5;
    }
    final variation = (DateTime.now().millisecondsSinceEpoch % 20) / 10.0 - 1.0;
    score += variation;

    return score.clamp(0.0, 10.0);
  }
}

@freezed
sealed class WritingAnalyticsRequest with _$WritingAnalyticsRequest {
  const factory WritingAnalyticsRequest({
    final DateTimeRange? timeRange,
    final int? userId,
  }) = _WritingAnalyticsRequest;
}

@riverpod
WritingAnalyticsUseCase writingAnalyticsUseCase(
  final Ref ref,
) {
  final writingRepository = ref.watch(writingRepositoryProvider);
  final userWritingRepository = ref.watch(userWritingRepositoryProvider);
  return WritingAnalyticsUseCase(
    writingRepository: writingRepository,
    userWritingRepository: userWritingRepository,
  );
}

class WritingAnalyticsUseCase
    implements UseCase<WritingAnalytics, WritingAnalyticsRequest> {
  const WritingAnalyticsUseCase({
    required final WritingRepository writingRepository,
    required final UserWritingRepository userWritingRepository,
  }) : _writingRepository = writingRepository,
       _userWritingRepository = userWritingRepository;

  final WritingRepository _writingRepository;
  final UserWritingRepository _userWritingRepository;

  @override
  Future<Either<Failure, WritingAnalytics>> call(
    final WritingAnalyticsRequest request,
  ) async {
    final promptsResult = await _writingRepository.listWritingPrompts();
    if (promptsResult is Left) {
      return Left((promptsResult as Left<Failure, List<WritingPrompt>>).value);
    }
    final prompts =
        (promptsResult as Right<Failure, List<WritingPrompt>>).value;
    var allWritings = <UserWriting>[];
    if (request.userId != null) {
      final userWritingsResult = await _userWritingRepository
          .listUserWritingsByUserId(
            userId: request.userId!,
          );
      if (userWritingsResult is Left) {
        return Left(
          (userWritingsResult as Left<Failure, List<UserWriting>>).value,
        );
      }
      allWritings =
          (userWritingsResult as Right<Failure, List<UserWriting>>).value;
    } else {
      for (final prompt in prompts) {
        final promptWritingsResult = await _userWritingRepository
            .listUserWritingsByPromptId(promptId: prompt.id);
        promptWritingsResult.fold(
          ifLeft: (final failure) {},
          ifRight: (final writings) => allWritings.addAll(writings),
        );
      }
    }

    if (request.timeRange != null) {
      allWritings = [
        ...allWritings.where(
          (final writing) =>
              writing.submittedAt.isAfter(request.timeRange!.start) &&
              writing.submittedAt.isBefore(request.timeRange!.end),
        ),
      ];
    }

    final analytics = _generateAnalytics(
      prompts,
      allWritings,
      request.userId,
    );
    return Right(analytics);
  }

  WritingAnalytics _generateAnalytics(
    final List<WritingPrompt> prompts,
    final List<UserWriting> writings,
    final int? userId,
  ) {
    final evaluatedWritings = writings.where((final w) => w.aiScore != null);

    final totalPrompts = prompts.length;
    final totalSubmissions = writings.length;
    final evaluatedSubmissions = evaluatedWritings.length;

    var averageScore = null as double?;
    var highestScore = null as double?;
    var lowestScore = null as double?;

    if (evaluatedWritings.isNotEmpty) {
      final scores = evaluatedWritings.map((final w) => w.aiScore!);
      averageScore = scores.reduce((final a, final b) => a + b) / scores.length;
      highestScore = scores.reduce((final a, final b) => a > b ? a : b);
      lowestScore = scores.reduce((final a, final b) => a < b ? a : b);
    }

    final topicDistribution = <String, int>{};
    for (final prompt in prompts) {
      if (prompt.topic != null) {
        topicDistribution[prompt.topic!] =
            (topicDistribution[prompt.topic!] ?? 0) + 1;
      }
    }

    final difficultyDistribution = <String, int>{};
    for (final prompt in prompts) {
      if (prompt.difficultyLevel != null) {
        difficultyDistribution[prompt.difficultyLevel!] =
            (difficultyDistribution[prompt.difficultyLevel!] ?? 0) + 1;
      }
    }

    final activityTrends = _calculateActivityTrends(writings, 30);

    final promptPopularity = <int, int>{};
    for (final writing in writings) {
      if (writing.promptId != null) {
        promptPopularity[writing.promptId!] =
            (promptPopularity[writing.promptId!] ?? 0) + 1;
      }
    }

    final mostPopularPrompts = [
      ...promptPopularity.entries
          .map(
            (final entry) => prompts.firstWhere((final p) => p.id == entry.key),
          )
          .take(5),
    ];

    return WritingAnalytics(
      totalPrompts: totalPrompts,
      totalSubmissions: totalSubmissions,
      evaluatedSubmissions: evaluatedSubmissions,
      averageScore: averageScore,
      highestScore: highestScore,
      lowestScore: lowestScore,
      topicDistribution: topicDistribution,
      difficultyDistribution: difficultyDistribution,
      activityTrends: activityTrends,
      mostPopularPrompts: mostPopularPrompts,
      recentActivity: [...writings.take(10)],
      generatedAt: DateTime.now(),
      userId: userId,
    );
  }

  Map<DateTime, int> _calculateActivityTrends(
    final List<UserWriting> writings,
    final int days,
  ) {
    final trends = <DateTime, int>{};
    final now = DateTime.now();
    for (var i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      trends[date] = 0;
    }
    for (final writing in writings) {
      final date = DateTime(
        writing.submittedAt.year,
        writing.submittedAt.month,
        writing.submittedAt.day,
      );
      if (trends.containsKey(date)) {
        trends[date] = trends[date]! + 1;
      }
    }
    return trends;
  }
}

@freezed
sealed class WritingSessionResult with _$WritingSessionResult {
  const factory WritingSessionResult({
    required final WritingPrompt prompt,
    required final UserWriting submission,
    required final DateTime sessionStartTime,
    required final DateTime sessionEndTime,
  }) = _WritingSessionResult;
}

extension WritingSessionResultExtension on WritingSessionResult {
  Duration get sessionDuration => sessionEndTime.difference(sessionStartTime);
}

@freezed
sealed class EvaluationCriteria with _$EvaluationCriteria {
  const factory EvaluationCriteria({
    required final String targetLevel,
    required final List<String> focusAreas,
    @Default(true) required final bool includeDetailedFeedback,
    @Default(true) required final bool includeScoring,
  }) = _EvaluationCriteria;
}

@freezed
sealed class BatchEvaluationResult with _$BatchEvaluationResult {
  const factory BatchEvaluationResult({
    required final int totalSubmissions,
    required final List<UserWriting> successfulEvaluations,
    required final List<EvaluationFailure> failedEvaluations,
    required final EvaluationCriteria evaluationCriteria,
    required final DateTime processingTime,
  }) = _BatchEvaluationResult;
}

extension BatchEvaluationResultExtension on BatchEvaluationResult {
  bool get hasFailures => failedEvaluations.isNotEmpty;

  bool get hasSuccesses => successfulEvaluations.isNotEmpty;

  int get totalEvaluated =>
      successfulEvaluations.length + failedEvaluations.length;
}

@freezed
sealed class EvaluationFailure with _$EvaluationFailure {
  const factory EvaluationFailure({
    required final int submissionId,
    required final Failure failure,
  }) = _EvaluationFailure;
}

@freezed
sealed class WritingAnalytics with _$WritingAnalytics {
  const factory WritingAnalytics({
    required final int totalPrompts,
    required final int totalSubmissions,
    required final int evaluatedSubmissions,
    @Default(null) final double? averageScore,
    @Default(null) final double? highestScore,
    @Default(null) final double? lowestScore,
    required final Map<String, int> topicDistribution,
    required final Map<String, int> difficultyDistribution,
    required final Map<DateTime, int> activityTrends,
    required final List<WritingPrompt> mostPopularPrompts,
    required final List<UserWriting> recentActivity,
    required final DateTime generatedAt,
    @Default(null) final int? userId,
  }) = _WritingAnalytics;
}

extension WritingAnalyticsExtension on WritingAnalytics {
  bool get isUserSpecific => userId != null;

  double get evaluationRate => evaluatedSubmissions / totalSubmissions;
}

@freezed
sealed class DateTimeRange with _$DateTimeRange {
  const factory DateTimeRange({
    required final DateTime start,
    required final DateTime end,
  }) = _DateTimeRange;
}
