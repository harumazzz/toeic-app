// ignore_for_file: lines_longer_than_80_chars

import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/writing/domain/entities/user_writing.dart';
import 'package:learn/features/writing/domain/repositories/user_writing_repository.dart';
import 'package:learn/features/writing/domain/repositories/writing_repository.dart';
import 'package:learn/features/writing/domain/use_cases/user_writing_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockWritingRepository extends Mock implements WritingRepository {}

class MockUserWritingRepository extends Mock implements UserWritingRepository {}

void main() {
  late MockWritingRepository mockWritingRepository;
  late MockUserWritingRepository mockUserWritingRepository;

  setUp(() {
    mockWritingRepository = MockWritingRepository();
    mockUserWritingRepository = MockUserWritingRepository();
  });

  setUpAll(() {
    registerFallbackValue(
      const UserWritingRequest(userId: 0, submissionText: ''),
    );
    registerFallbackValue(const UserWritingUpdateRequest());
  });

  group('CreateUserWritingUseCase', () {
    late CreateUserWritingUseCase usecase;

    setUp(() {
      usecase = CreateUserWritingUseCase(
        mockUserWritingRepository,
      );
    });

    const tUserWritingRequest = UserWritingRequest(
      userId: 123,
      promptId: 456,
      submissionText:
          'My favorite hobby is reading because it expands my knowledge and vocabulary.',
      aiFeedback: {'grammar': 'Good', 'vocabulary': 'Excellent'},
      aiScore: 8.5,
    );

    final tUserWriting = UserWriting(
      id: 1,
      userId: 123,
      promptId: 456,
      submissionText:
          'My favorite hobby is reading because it expands my knowledge and vocabulary.',
      aiFeedback: const {'grammar': 'Good', 'vocabulary': 'Excellent'},
      aiScore: 8.5,
      submittedAt: DateTime(2024, 1, 17, 16, 45),
      evaluatedAt: DateTime(2024, 1, 17, 16, 50),
      updatedAt: DateTime(2024, 1, 17, 16, 50),
    );

    test('should create user writing successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.createUserWriting(
          request: any(named: 'request'),
        ),
      ).thenAnswer((_) async => Right(tUserWriting));

      // act
      final result = await usecase(tUserWritingRequest);

      // assert
      expect(result, Right(tUserWriting));
      verify(
        () => mockUserWritingRepository.createUserWriting(
          request: tUserWritingRequest,
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test(
      'should return ServerFailure when submission text is empty',
      () async {
        // arrange
        const tFailure = ServerFailure(
          message: 'Submission text cannot be empty',
        );
        when(
          () => mockUserWritingRepository.createUserWriting(
            request: any(named: 'request'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(tUserWritingRequest);

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.createUserWriting(
            request: tUserWritingRequest,
          ),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );

    test(
      'should return ServerFailure when prompt ID does not exist',
      () async {
        // arrange
        const tFailure = ServerFailure(message: 'Writing prompt not found');
        when(
          () => mockUserWritingRepository.createUserWriting(
            request: any(named: 'request'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(tUserWritingRequest);

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.createUserWriting(
            request: tUserWritingRequest,
          ),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );

    test('should return ServerFailure when creation fails', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Failed to create user writing');
      when(
        () => mockUserWritingRepository.createUserWriting(
          request: any(named: 'request'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tUserWritingRequest);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockUserWritingRepository.createUserWriting(
          request: tUserWritingRequest,
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });
  });

  group('GetUserWritingUseCase', () {
    late GetUserWritingUseCase usecase;

    setUp(() {
      usecase = GetUserWritingUseCase(mockUserWritingRepository);
    });

    const tUserWritingId = 1;
    final tUserWriting = UserWriting(
      id: tUserWritingId,
      userId: 123,
      promptId: 456,
      submissionText:
          'My favorite hobby is reading because it expands my knowledge and vocabulary.',
      aiFeedback: const {'grammar': 'Good', 'vocabulary': 'Excellent'},
      aiScore: 8.5,
      submittedAt: DateTime(2024, 1, 17, 16, 45),
      evaluatedAt: DateTime(2024, 1, 17, 16, 50),
      updatedAt: DateTime(2024, 1, 17, 16, 50),
    );

    test('should get user writing by ID successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.getUserWriting(id: any(named: 'id')),
      ).thenAnswer((_) async => Right(tUserWriting));

      // act
      final result = await usecase(tUserWritingId);

      // assert
      expect(result, Right(tUserWriting));
      verify(
        () => mockUserWritingRepository.getUserWriting(id: tUserWritingId),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test(
      'should return ServerFailure when user writing does not exist',
      () async {
        // arrange
        const tFailure = ServerFailure(message: 'User writing not found');
        when(
          () => mockUserWritingRepository.getUserWriting(id: any(named: 'id')),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(tUserWritingId);

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.getUserWriting(id: tUserWritingId),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );

    test('should return ServerFailure when server error occurs', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Internal server error');
      when(
        () => mockUserWritingRepository.getUserWriting(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tUserWritingId);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockUserWritingRepository.getUserWriting(id: tUserWritingId),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });
  });

  group('ListUserWritingsByUserIdUseCase', () {
    late ListUserWritingsByUserIdUseCase usecase;

    setUp(() {
      usecase = ListUserWritingsByUserIdUseCase(mockUserWritingRepository);
    });

    const tUserId = 123;
    final tUserWritingsList = [
      UserWriting(
        id: 1,
        userId: tUserId,
        promptId: 456,
        submissionText: 'First writing submission.',
        aiFeedback: const {'grammar': 'Good'},
        aiScore: 7.5,
        submittedAt: DateTime(2024, 1, 17, 16, 45),
        evaluatedAt: DateTime(2024, 1, 17, 16, 50),
        updatedAt: DateTime(2024, 1, 17, 16, 50),
      ),
      UserWriting(
        id: 2,
        userId: tUserId,
        promptId: 789,
        submissionText: 'Second writing submission.',
        aiFeedback: const {'grammar': 'Excellent'},
        aiScore: 9,
        submittedAt: DateTime(2024, 1, 18, 10, 30),
        evaluatedAt: DateTime(2024, 1, 18, 10, 35),
        updatedAt: DateTime(2024, 1, 18, 10, 35),
      ),
    ];

    test('should get user writings by user ID successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.listUserWritingsByUserId(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => Right(tUserWritingsList));

      // act
      final result = await usecase(tUserId);

      // assert
      expect(result, Right(tUserWritingsList));
      verify(
        () =>
            mockUserWritingRepository.listUserWritingsByUserId(userId: tUserId),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test('should return empty list when user has no writings', () async {
      // arrange
      when(
        () => mockUserWritingRepository.listUserWritingsByUserId(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase(tUserId);

      // assert
      expect(result, const Right(<UserWriting>[]));
      verify(
        () =>
            mockUserWritingRepository.listUserWritingsByUserId(userId: tUserId),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test('should return ServerFailure when server error occurs', () async {
      // arrange
      const tFailure = ServerFailure(
        message: 'Failed to retrieve user writings',
      );
      when(
        () => mockUserWritingRepository.listUserWritingsByUserId(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tUserId);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () =>
            mockUserWritingRepository.listUserWritingsByUserId(userId: tUserId),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });
  });

  group('ListUserWritingsByPromptIdUseCase', () {
    late ListUserWritingsByPromptIdUseCase usecase;

    setUp(() {
      usecase = ListUserWritingsByPromptIdUseCase(mockUserWritingRepository);
    });

    const tPromptId = 456;
    final tUserWritingsList = [
      UserWriting(
        id: 1,
        userId: 123,
        promptId: tPromptId,
        submissionText: 'User 123 response to prompt.',
        aiFeedback: const {'grammar': 'Good'},
        aiScore: 7.5,
        submittedAt: DateTime(2024, 1, 17, 16, 45),
        evaluatedAt: DateTime(2024, 1, 17, 16, 50),
        updatedAt: DateTime(2024, 1, 17, 16, 50),
      ),
      UserWriting(
        id: 2,
        userId: 456,
        promptId: tPromptId,
        submissionText: 'User 456 response to prompt.',
        aiFeedback: const {'grammar': 'Excellent'},
        aiScore: 9,
        submittedAt: DateTime(2024, 1, 18, 10, 30),
        evaluatedAt: DateTime(2024, 1, 18, 10, 35),
        updatedAt: DateTime(2024, 1, 18, 10, 35),
      ),
    ];

    test('should get user writings by prompt ID successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.listUserWritingsByPromptId(
          promptId: any(named: 'promptId'),
        ),
      ).thenAnswer((_) async => Right(tUserWritingsList));

      // act
      final result = await usecase(tPromptId);

      // assert
      expect(result, Right(tUserWritingsList));
      verify(
        () => mockUserWritingRepository.listUserWritingsByPromptId(
          promptId: tPromptId,
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test('should return empty list when prompt has no writings', () async {
      // arrange
      when(
        () => mockUserWritingRepository.listUserWritingsByPromptId(
          promptId: any(named: 'promptId'),
        ),
      ).thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase(tPromptId);

      // assert
      expect(result, const Right(<UserWriting>[]));
      verify(
        () => mockUserWritingRepository.listUserWritingsByPromptId(
          promptId: tPromptId,
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test('should return ServerFailure when server error occurs', () async {
      // arrange
      const tFailure = ServerFailure(
        message: 'Failed to retrieve writings for prompt',
      );
      when(
        () => mockUserWritingRepository.listUserWritingsByPromptId(
          promptId: any(named: 'promptId'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tPromptId);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockUserWritingRepository.listUserWritingsByPromptId(
          promptId: tPromptId,
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });
  });

  group('UpdateUserWritingUseCase', () {
    late UpdateUserWritingUseCase usecase;

    setUp(() {
      usecase = UpdateUserWritingUseCase(mockUserWritingRepository);
    });

    const tUserWritingId = 1;
    final tUserWritingUpdateRequest = UserWritingUpdateRequest(
      submissionText: 'Updated submission text.',
      aiFeedback: const {'grammar': 'Excellent', 'vocabulary': 'Outstanding'},
      aiScore: 9.2,
      evaluatedAt: DateTime(2024, 1, 18, 10, 15),
    );

    final tUpdatedUserWriting = UserWriting(
      id: tUserWritingId,
      userId: 123,
      promptId: 456,
      submissionText: 'Updated submission text.',
      aiFeedback: const {'grammar': 'Excellent', 'vocabulary': 'Outstanding'},
      aiScore: 9.2,
      submittedAt: DateTime(2024, 1, 17, 16, 45),
      evaluatedAt: DateTime(2024, 1, 18, 10, 15),
      updatedAt: DateTime(2024, 1, 18, 10, 15),
    );

    test('should update user writing successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.updateUserWriting(
          id: any(named: 'id'),
          request: any(named: 'request'),
        ),
      ).thenAnswer((_) async => Right(tUpdatedUserWriting));

      // act
      final result = await usecase(
        UpdateUserWritingParams(
          id: tUserWritingId,
          request: tUserWritingUpdateRequest,
        ),
      );

      // assert
      expect(result, Right(tUpdatedUserWriting));
      verify(
        () => mockUserWritingRepository.updateUserWriting(
          id: tUserWritingId,
          request: tUserWritingUpdateRequest,
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test(
      'should return ServerFailure when user writing does not exist',
      () async {
        // arrange
        const tFailure = ServerFailure(message: 'User writing not found');
        when(
          () => mockUserWritingRepository.updateUserWriting(
            id: any(named: 'id'),
            request: any(named: 'request'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(
          UpdateUserWritingParams(
            id: tUserWritingId,
            request: tUserWritingUpdateRequest,
          ),
        );

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.updateUserWriting(
            id: tUserWritingId,
            request: tUserWritingUpdateRequest,
          ),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );

    test(
      'should return ServerFailure when AI score is out of range',
      () async {
        // arrange
        const tFailure = ServerFailure(
          message: 'AI score must be between 0 and 10',
        );
        when(
          () => mockUserWritingRepository.updateUserWriting(
            id: any(named: 'id'),
            request: any(named: 'request'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(
          UpdateUserWritingParams(
            id: tUserWritingId,
            request: tUserWritingUpdateRequest,
          ),
        );

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.updateUserWriting(
            id: tUserWritingId,
            request: tUserWritingUpdateRequest,
          ),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );
  });

  group('DeleteUserWritingUseCase', () {
    late DeleteUserWritingUseCase usecase;

    setUp(() {
      usecase = DeleteUserWritingUseCase(mockUserWritingRepository);
    });

    const tUserWritingId = 1;

    test('should delete user writing successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.deleteUserWriting(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(Success()));

      // act
      final result = await usecase(tUserWritingId);

      // assert
      expect(result, const Right(Success()));
      verify(
        () => mockUserWritingRepository.deleteUserWriting(id: tUserWritingId),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test(
      'should return ServerFailure when user writing does not exist',
      () async {
        // arrange
        const tFailure = ServerFailure(message: 'User writing not found');
        when(
          () =>
              mockUserWritingRepository.deleteUserWriting(id: any(named: 'id')),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(tUserWritingId);

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.deleteUserWriting(id: tUserWritingId),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );

    test(
      'should return ServerFailure when user lacks permission',
      () async {
        // arrange
        const tFailure = ServerFailure(
          message: 'Not authorized to delete this writing',
        );
        when(
          () =>
              mockUserWritingRepository.deleteUserWriting(id: any(named: 'id')),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(tUserWritingId);

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.deleteUserWriting(id: tUserWritingId),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );
  });

  group('SubmitWritingForEvaluationUseCase', () {
    late SubmitWritingForEvaluationUseCase usecase;

    setUp(() {
      usecase = SubmitWritingForEvaluationUseCase(mockUserWritingRepository);
    });

    const tUserId = 123;
    const tPromptId = 456;
    const tSubmissionText = 'My writing submission for evaluation.';

    final tUserWriting = UserWriting(
      id: 1,
      userId: tUserId,
      promptId: tPromptId,
      submissionText: tSubmissionText,
      submittedAt: DateTime(2024, 1, 17, 16, 45),
      updatedAt: DateTime(2024, 1, 17, 16, 45),
    );

    test('should submit writing for evaluation successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.createUserWriting(
          request: any(named: 'request'),
        ),
      ).thenAnswer((_) async => Right(tUserWriting));

      // act
      final result = await usecase(
        const SubmitWritingForEvaluationParams(
          userId: tUserId,
          promptId: tPromptId,
          submissionText: tSubmissionText,
        ),
      );

      // assert
      expect(result, Right(tUserWriting));
      verify(
        () => mockUserWritingRepository.createUserWriting(
          request: const UserWritingRequest(
            userId: tUserId,
            promptId: tPromptId,
            submissionText: tSubmissionText,
          ),
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test('should submit writing without prompt ID successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.createUserWriting(
          request: any(named: 'request'),
        ),
      ).thenAnswer((_) async => Right(tUserWriting));

      // act
      final result = await usecase(
        const SubmitWritingForEvaluationParams(
          userId: tUserId,
          submissionText: tSubmissionText,
        ),
      );

      // assert
      expect(result, Right(tUserWriting));
      verify(
        () => mockUserWritingRepository.createUserWriting(
          request: const UserWritingRequest(
            userId: tUserId,
            submissionText: tSubmissionText,
          ),
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test(
      'should return ServerFailure when submission text is empty',
      () async {
        // arrange
        const tFailure = ServerFailure(
          message: 'Submission text cannot be empty',
        );
        when(
          () => mockUserWritingRepository.createUserWriting(
            request: any(named: 'request'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(
          const SubmitWritingForEvaluationParams(
            userId: tUserId,
            promptId: tPromptId,
            submissionText: tSubmissionText,
          ),
        );

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.createUserWriting(
            request: any(named: 'request'),
          ),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );
  });

  group('AddAIFeedbackUseCase', () {
    late AddAIFeedbackUseCase usecase;

    setUp(() {
      usecase = AddAIFeedbackUseCase(mockUserWritingRepository);
    });

    const tSubmissionId = 1;
    const tAiFeedback = {
      'grammar': 'Excellent',
      'vocabulary': 'Outstanding',
      'coherence': 'Very good',
    };
    const tAiScore = 9.2;

    final tUpdatedUserWriting = UserWriting(
      id: tSubmissionId,
      userId: 123,
      promptId: 456,
      submissionText: 'Writing submission text.',
      aiFeedback: tAiFeedback,
      aiScore: tAiScore,
      submittedAt: DateTime(2024, 1, 17, 16, 45),
      evaluatedAt: DateTime(2024, 1, 18, 10, 15),
      updatedAt: DateTime(2024, 1, 18, 10, 15),
    );

    test('should add AI feedback successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.updateUserWriting(
          id: any(named: 'id'),
          request: any(named: 'request'),
        ),
      ).thenAnswer((_) async => Right(tUpdatedUserWriting));

      // act
      final result = await usecase(
        const AddAIFeedbackParams(
          submissionId: tSubmissionId,
          aiFeedback: tAiFeedback,
          aiScore: tAiScore,
        ),
      );

      // assert
      expect(result, Right(tUpdatedUserWriting));
      verify(
        () => mockUserWritingRepository.updateUserWriting(
          id: tSubmissionId,
          request: any(named: 'request'),
        ),
      );
      verifyNoMoreInteractions(mockWritingRepository);
    });

    test(
      'should return ServerFailure when submission does not exist',
      () async {
        // arrange
        const tFailure = ServerFailure(message: 'User writing not found');
        when(
          () => mockUserWritingRepository.updateUserWriting(
            id: any(named: 'id'),
            request: any(named: 'request'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(
          const AddAIFeedbackParams(
            submissionId: tSubmissionId,
            aiFeedback: tAiFeedback,
            aiScore: tAiScore,
          ),
        );

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.updateUserWriting(
            id: tSubmissionId,
            request: any(named: 'request'),
          ),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );

    test('should returnServerFailure when AI score is invalid', () async {
      // arrange
      const tFailure = ServerFailure(
        message: 'AI score must be between 0 and 10',
      );
      when(
        () => mockUserWritingRepository.updateUserWriting(
          id: any(named: 'id'),
          request: any(named: 'request'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(
        const AddAIFeedbackParams(
          submissionId: tSubmissionId,
          aiFeedback: tAiFeedback,
          aiScore: 15,
        ),
      );

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockUserWritingRepository.updateUserWriting(
          id: tSubmissionId,
          request: any(named: 'request'),
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });
  });

  group('GetUserWritingProgressUseCase', () {
    late GetUserWritingProgressUseCase usecase;

    setUp(() {
      usecase = GetUserWritingProgressUseCase(mockUserWritingRepository);
    });

    const tUserId = 123;

    test('should return ServerFailure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure(
        message: 'Failed to retrieve user writings',
      );
      when(
        () => mockUserWritingRepository.listUserWritingsByUserId(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tUserId);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () =>
            mockUserWritingRepository.listUserWritingsByUserId(userId: tUserId),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });
  });

  group('ReviseWritingSubmissionUseCase', () {
    late ReviseWritingSubmissionUseCase usecase;

    setUp(() {
      usecase = ReviseWritingSubmissionUseCase(mockUserWritingRepository);
    });

    const tSubmissionId = 1;
    const tRevisedText = 'Revised and improved writing text.';

    final tRevisedUserWriting = UserWriting(
      id: tSubmissionId,
      userId: 123,
      promptId: 456,
      submissionText: tRevisedText,
      submittedAt: DateTime(2024, 1, 17, 16, 45),
      updatedAt: DateTime(2024, 1, 18, 10, 15),
    );

    test('should revise writing submission successfully', () async {
      // arrange
      when(
        () => mockUserWritingRepository.updateUserWriting(
          id: any(named: 'id'),
          request: any(named: 'request'),
        ),
      ).thenAnswer((_) async => Right(tRevisedUserWriting));

      // act
      final result = await usecase(
        const ReviseWritingSubmissionParams(
          submissionId: tSubmissionId,
          revisedText: tRevisedText,
        ),
      );

      // assert
      expect(result, Right(tRevisedUserWriting));
      verify(
        () => mockUserWritingRepository.updateUserWriting(
          id: tSubmissionId,
          request: const UserWritingUpdateRequest(
            submissionText: tRevisedText,
          ),
        ),
      );
      verifyNoMoreInteractions(mockUserWritingRepository);
    });

    test(
      'should return ServerFailure when submission does not exist',
      () async {
        // arrange
        const tFailure = ServerFailure(message: 'User writing not found');
        when(
          () => mockUserWritingRepository.updateUserWriting(
            id: any(named: 'id'),
            request: any(named: 'request'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(
          const ReviseWritingSubmissionParams(
            submissionId: tSubmissionId,
            revisedText: tRevisedText,
          ),
        );

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockUserWritingRepository.updateUserWriting(
            id: tSubmissionId,
            request: any(named: 'request'),
          ),
        );
        verifyNoMoreInteractions(mockUserWritingRepository);
      },
    );

    test('should clear AI feedback when revising text', () async {
      // arrange
      when(
        () => mockUserWritingRepository.updateUserWriting(
          id: any(named: 'id'),
          request: any(named: 'request'),
        ),
      ).thenAnswer((_) async => Right(tRevisedUserWriting));

      // act
      await usecase(
        const ReviseWritingSubmissionParams(
          submissionId: tSubmissionId,
          revisedText: tRevisedText,
        ),
      );

      // assert - Verify that AI feedback is cleared
      final captured =
          verify(
                () => mockUserWritingRepository.updateUserWriting(
                  id: tSubmissionId,
                  request: captureAny(named: 'request'),
                ),
              ).captured.single
              as UserWritingUpdateRequest;

      expect(captured.submissionText, tRevisedText);
      expect(captured.aiFeedback, null);
      expect(captured.aiScore, null);
      expect(captured.evaluatedAt, null);
      verifyNoMoreInteractions(mockUserWritingRepository);
    });
  });
}
