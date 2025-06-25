// ignore_for_file: lines_longer_than_80_chars

import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/writing/domain/entities/user_writing.dart';
import 'package:learn/features/writing/domain/entities/writing_prompt.dart';
import 'package:learn/features/writing/domain/repositories/user_writing_repository.dart';
import 'package:learn/features/writing/domain/repositories/writing_repository.dart';
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

  group('WritingRepository', () {
    // Test data
    const tWritingPromptId = 1;
    const tUserId = 123;
    const tPromptId = 456;
    const tUserWritingId = 789;

    const tWritingPromptRequest = WritingPromptRequest(
      userId: tUserId,
      promptText: 'Describe your favorite hobby and explain why you enjoy it.',
      topic: 'Personal Experience',
      difficultyLevel: 'Intermediate',
    );

    final tWritingPrompt = WritingPrompt(
      id: tWritingPromptId,
      userId: tUserId,
      promptText: 'Describe your favorite hobby and explain why you enjoy it.',
      topic: 'Personal Experience',
      difficultyLevel: 'Intermediate',
      createdAt: DateTime(2024, 1, 15, 10, 30),
    );

    final tWritingPromptsList = [
      tWritingPrompt,
      WritingPrompt(
        id: 2,
        userId: tUserId,
        promptText: 'Discuss the advantages and disadvantages of remote work.',
        topic: 'Work and Career',
        difficultyLevel: 'Advanced',
        createdAt: DateTime(2024, 1, 16, 14, 20),
      ),
    ];

    const tUserWritingRequest = UserWritingRequest(
      userId: tUserId,
      promptId: tPromptId,
      submissionText:
          'My favorite hobby is reading because it expands my knowledge and vocabulary. I enjoy reading fiction and non-fiction books during my free time.',
      aiFeedback: {
        'grammar': 'Good',
        'vocabulary': 'Excellent',
        'coherence': 'Very good',
      },
      aiScore: 8.5,
    );

    final tUserWriting = UserWriting(
      id: tUserWritingId,
      userId: tUserId,
      promptId: tPromptId,
      submissionText:
          'My favorite hobby is reading because it expands my knowledge and vocabulary. I enjoy reading fiction and non-fiction books during my free time.',
      aiFeedback: {
        'grammar': 'Good',
        'vocabulary': 'Excellent',
        'coherence': 'Very good',
      },
      aiScore: 8.5,
      submittedAt: DateTime(2024, 1, 17, 16, 45),
      evaluatedAt: DateTime(2024, 1, 17, 16, 50),
      updatedAt: DateTime(2024, 1, 17, 16, 50),
    );

    final tUserWritingUpdateRequest = UserWritingUpdateRequest(
      submissionText:
          'My favorite hobby is reading because it significantly expands my knowledge, vocabulary, and perspective on life.',
      aiFeedback: {
        'grammar': 'Excellent',
        'vocabulary': 'Outstanding',
        'coherence': 'Excellent',
      },
      aiScore: 9.2,
      evaluatedAt: DateTime(2024, 1, 18, 10, 15),
    );

    final tUserWritingsList = [
      tUserWriting,
      UserWriting(
        id: 2,
        userId: tUserId,
        promptId: tPromptId,
        submissionText: 'Another writing submission for testing purposes.',
        aiFeedback: {
          'grammar': 'Fair',
          'vocabulary': 'Good',
          'coherence': 'Good',
        },
        aiScore: 7,
        submittedAt: DateTime(2024, 1, 18, 9, 30),
        evaluatedAt: DateTime(2024, 1, 18, 9, 35),
        updatedAt: DateTime(2024, 1, 18, 9, 35),
      ),
    ];

    // Writing Prompt Tests
    group('Writing Prompt Operations', () {
      group('createWritingPrompt', () {
        test(
          'should return WritingPrompt when creation is successful',
          () async {
            // arrange
            when(
              () => mockWritingRepository.createWritingPrompt(
                request: any(named: 'request'),
              ),
            ).thenAnswer((_) async => Right(tWritingPrompt));

            // act
            final result = await mockWritingRepository.createWritingPrompt(
              request: tWritingPromptRequest,
            );

            // assert
            expect(result, Right(tWritingPrompt));
            verify(
              () => mockWritingRepository.createWritingPrompt(
                request: tWritingPromptRequest,
              ),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test('should return ServerFailure when creation fails', () async {
          // arrange
          const tFailure = ServerFailure(
            message: 'Failed to create writing prompt',
          );
          when(
            () => mockWritingRepository.createWritingPrompt(
              request: any(named: 'request'),
            ),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockWritingRepository.createWritingPrompt(
            request: tWritingPromptRequest,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () => mockWritingRepository.createWritingPrompt(
              request: tWritingPromptRequest,
            ),
          );
          verifyNoMoreInteractions(mockWritingRepository);
        });

        test(
          'should return NetworkFailure when network error occurs',
          () async {
            // arrange
            const tFailure = NetworkFailure(
              message: 'Network connection failed',
            );
            when(
              () => mockWritingRepository.createWritingPrompt(
                request: any(named: 'request'),
              ),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockWritingRepository.createWritingPrompt(
              request: tWritingPromptRequest,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () => mockWritingRepository.createWritingPrompt(
                request: tWritingPromptRequest,
              ),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );
      });

      group('getWritingPrompt', () {
        test(
          'should return WritingPrompt when retrieval is successful',
          () async {
            // arrange
            when(
              () =>
                  mockWritingRepository.getWritingPrompt(id: any(named: 'id')),
            ).thenAnswer((_) async => Right(tWritingPrompt));

            // act
            final result = await mockWritingRepository.getWritingPrompt(
              id: tWritingPromptId,
            );

            // assert
            expect(result, Right(tWritingPrompt));
            verify(
              () =>
                  mockWritingRepository.getWritingPrompt(id: tWritingPromptId),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test(
          'should return ServerFailure when prompt does not exist',
          () async {
            // arrange
            const tFailure = ServerFailure(
              message: 'Writing prompt not found',
            );
            when(
              () =>
                  mockWritingRepository.getWritingPrompt(id: any(named: 'id')),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockWritingRepository.getWritingPrompt(
              id: tWritingPromptId,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () =>
                  mockWritingRepository.getWritingPrompt(id: tWritingPromptId),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test('should return ServerFailure when server error occurs', () async {
          // arrange
          const tFailure = ServerFailure(message: 'Internal server error');
          when(
            () => mockWritingRepository.getWritingPrompt(id: any(named: 'id')),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockWritingRepository.getWritingPrompt(
            id: tWritingPromptId,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () => mockWritingRepository.getWritingPrompt(id: tWritingPromptId),
          );
          verifyNoMoreInteractions(mockWritingRepository);
        });
      });

      group('listWritingPrompts', () {
        test(
          'should return list of WritingPrompts when retrieval is successful',
          () async {
            // arrange
            when(
              () => mockWritingRepository.listWritingPrompts(),
            ).thenAnswer((_) async => Right(tWritingPromptsList));

            // act
            final result = await mockWritingRepository.listWritingPrompts();

            // assert
            expect(result, Right(tWritingPromptsList));
            verify(() => mockWritingRepository.listWritingPrompts());
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test('should return empty list when no prompts exist', () async {
          // arrange
          when(
            () => mockWritingRepository.listWritingPrompts(),
          ).thenAnswer((_) async => const Right([]));

          // act
          final result = await mockWritingRepository.listWritingPrompts();

          // assert
          expect(result, const Right(<WritingPrompt>[]));
          verify(() => mockWritingRepository.listWritingPrompts());
          verifyNoMoreInteractions(mockWritingRepository);
        });

        test('should return ServerFailure when server error occurs', () async {
          // arrange
          const tFailure = ServerFailure(
            message: 'Failed to retrieve writing prompts',
          );
          when(
            () => mockWritingRepository.listWritingPrompts(),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockWritingRepository.listWritingPrompts();

          // assert
          expect(result, const Left(tFailure));
          verify(() => mockWritingRepository.listWritingPrompts());
          verifyNoMoreInteractions(mockWritingRepository);
        });
      });

      group('updateWritingPrompt', () {
        test(
          'should return updated WritingPrompt when update is successful',
          () async {
            // arrange
            final updatedPrompt = tWritingPrompt.copyWith(
              promptText: 'Updated prompt text',
              topic: 'Updated Topic',
            );
            when(
              () => mockWritingRepository.updateWritingPrompt(
                id: any(named: 'id'),
                request: any(named: 'request'),
              ),
            ).thenAnswer((_) async => Right(updatedPrompt));

            // act
            final result = await mockWritingRepository.updateWritingPrompt(
              id: tWritingPromptId,
              request: tWritingPromptRequest,
            );

            // assert
            expect(result, Right(updatedPrompt));
            verify(
              () => mockWritingRepository.updateWritingPrompt(
                id: tWritingPromptId,
                request: tWritingPromptRequest,
              ),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test(
          'should return ServerFailure when prompt does not exist',
          () async {
            // arrange
            const tFailure = ServerFailure(
              message: 'Writing prompt not found',
            );
            when(
              () => mockWritingRepository.updateWritingPrompt(
                id: any(named: 'id'),
                request: any(named: 'request'),
              ),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockWritingRepository.updateWritingPrompt(
              id: tWritingPromptId,
              request: tWritingPromptRequest,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () => mockWritingRepository.updateWritingPrompt(
                id: tWritingPromptId,
                request: tWritingPromptRequest,
              ),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test(
          'should return ServerFailure when request data is invalid',
          () async {
            // arrange
            const tFailure = ServerFailure(message: 'Invalid prompt text');
            when(
              () => mockWritingRepository.updateWritingPrompt(
                id: any(named: 'id'),
                request: any(named: 'request'),
              ),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockWritingRepository.updateWritingPrompt(
              id: tWritingPromptId,
              request: tWritingPromptRequest,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () => mockWritingRepository.updateWritingPrompt(
                id: tWritingPromptId,
                request: tWritingPromptRequest,
              ),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );
      });

      group('deleteWritingPrompt', () {
        test('should return Right(void) when deletion is successful', () async {
          // arrange
          when(
            () =>
                mockWritingRepository.deleteWritingPrompt(id: any(named: 'id')),
          ).thenAnswer((_) async => const Right(Success()));

          // act
          final result = await mockWritingRepository.deleteWritingPrompt(
            id: tWritingPromptId,
          );

          // assert
          expect(result, const Right(Success()));
          verify(
            () =>
                mockWritingRepository.deleteWritingPrompt(id: tWritingPromptId),
          );
          verifyNoMoreInteractions(mockWritingRepository);
        });

        test(
          'should return ServerFailure when prompt does not exist',
          () async {
            // arrange
            const tFailure = ServerFailure(
              message: 'Writing prompt not found',
            );
            when(
              () => mockWritingRepository.deleteWritingPrompt(
                id: any(named: 'id'),
              ),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockWritingRepository.deleteWritingPrompt(
              id: tWritingPromptId,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () => mockWritingRepository.deleteWritingPrompt(
                id: tWritingPromptId,
              ),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test('should return ServerFailure when server error occurs', () async {
          // arrange
          const tFailure = ServerFailure(
            message: 'Failed to delete writing prompt',
          );
          when(
            () =>
                mockWritingRepository.deleteWritingPrompt(id: any(named: 'id')),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockWritingRepository.deleteWritingPrompt(
            id: tWritingPromptId,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () =>
                mockWritingRepository.deleteWritingPrompt(id: tWritingPromptId),
          );
          verifyNoMoreInteractions(mockWritingRepository);
        });
      });
    });

    // User Writing Tests
    group('User Writing Operations', () {
      group('createUserWriting', () {
        test('should return UserWriting when creation is successful', () async {
          // arrange
          when(
            () => mockUserWritingRepository.createUserWriting(
              request: any(named: 'request'),
            ),
          ).thenAnswer((_) async => Right(tUserWriting));

          // act
          final result = await mockUserWritingRepository.createUserWriting(
            request: tUserWritingRequest,
          );

          // assert
          expect(result, Right(tUserWriting));
          verify(
            () => mockUserWritingRepository.createUserWriting(
              request: tUserWritingRequest,
            ),
          );
          verifyNoMoreInteractions(mockUserWritingRepository);
        });

        test('should return ServerFailure when creation fails', () async {
          // arrange
          const tFailure = ServerFailure(
            message: 'Failed to create user writing',
          );
          when(
            () => mockUserWritingRepository.createUserWriting(
              request: any(named: 'request'),
            ),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockUserWritingRepository.createUserWriting(
            request: tUserWritingRequest,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () => mockUserWritingRepository.createUserWriting(
              request: tUserWritingRequest,
            ),
          );
          verifyNoMoreInteractions(mockWritingRepository);
        });

        test(
          'should return ServerFailure when user ID is invalid',
          () async {
            // arrange
            const tFailure = ServerFailure(message: 'Invalid user ID');
            when(
              () => mockUserWritingRepository.createUserWriting(
                request: any(named: 'request'),
              ),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockUserWritingRepository.createUserWriting(
              request: tUserWritingRequest,
            );

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
      });

      group('getUserWriting', () {
        test(
          'should return UserWriting when retrieval is successful',
          () async {
            // arrange
            when(
              () => mockUserWritingRepository.getUserWriting(
                id: any(named: 'id'),
              ),
            ).thenAnswer((_) async => Right(tUserWriting));

            // act
            final result = await mockUserWritingRepository.getUserWriting(
              id: tUserWritingId,
            );

            // assert
            expect(result, Right(tUserWriting));
            verify(
              () =>
                  mockUserWritingRepository.getUserWriting(id: tUserWritingId),
            );
            verifyNoMoreInteractions(mockUserWritingRepository);
          },
        );

        test(
          'should return ServerFailure when user writing does not exist',
          () async {
            // arrange
            const tFailure = ServerFailure(message: 'User writing not found');
            when(
              () => mockUserWritingRepository.getUserWriting(
                id: any(named: 'id'),
              ),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockUserWritingRepository.getUserWriting(
              id: tUserWritingId,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () =>
                  mockUserWritingRepository.getUserWriting(id: tUserWritingId),
            );
            verifyNoMoreInteractions(mockUserWritingRepository);
          },
        );

        test('should return ServerFailure when server error occurs', () async {
          // arrange
          const tFailure = ServerFailure(message: 'Internal server error');
          when(
            () =>
                mockUserWritingRepository.getUserWriting(id: any(named: 'id')),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockUserWritingRepository.getUserWriting(
            id: tUserWritingId,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () => mockUserWritingRepository.getUserWriting(id: tUserWritingId),
          );
          verifyNoMoreInteractions(mockUserWritingRepository);
        });
      });

      group('listUserWritingsByUserId', () {
        test(
          'should return list of UserWritings when retrieval is successful',
          () async {
            // arrange
            when(
              () => mockUserWritingRepository.listUserWritingsByUserId(
                userId: any(named: 'userId'),
              ),
            ).thenAnswer((_) async => Right(tUserWritingsList));

            // act
            final result = await mockUserWritingRepository
                .listUserWritingsByUserId(
                  userId: tUserId,
                );

            // assert
            expect(result, Right(tUserWritingsList));
            verify(
              () => mockUserWritingRepository.listUserWritingsByUserId(
                userId: tUserId,
              ),
            );
            verifyNoMoreInteractions(mockUserWritingRepository);
          },
        );

        test('should return empty list when user has no writings', () async {
          // arrange
          when(
            () => mockUserWritingRepository.listUserWritingsByUserId(
              userId: any(named: 'userId'),
            ),
          ).thenAnswer((_) async => const Right([]));

          // act
          final result = await mockUserWritingRepository
              .listUserWritingsByUserId(
                userId: tUserId,
              );

          // assert
          expect(result, const Right(<UserWriting>[]));
          verify(
            () => mockUserWritingRepository.listUserWritingsByUserId(
              userId: tUserId,
            ),
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
          final result = await mockUserWritingRepository
              .listUserWritingsByUserId(
                userId: tUserId,
              );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () => mockUserWritingRepository.listUserWritingsByUserId(
              userId: tUserId,
            ),
          );
          verifyNoMoreInteractions(mockUserWritingRepository);
        });
      });

      group('listUserWritingsByPromptId', () {
        test(
          'should return list of UserWritings when retrieval is successful',
          () async {
            // arrange
            when(
              () => mockUserWritingRepository.listUserWritingsByPromptId(
                promptId: any(named: 'promptId'),
              ),
            ).thenAnswer((_) async => Right(tUserWritingsList));

            // act
            final result = await mockUserWritingRepository
                .listUserWritingsByPromptId(
                  promptId: tPromptId,
                );

            // assert
            expect(result, Right(tUserWritingsList));
            verify(
              () => mockUserWritingRepository.listUserWritingsByPromptId(
                promptId: tPromptId,
              ),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test('should return empty list when prompt has no writings', () async {
          // arrange
          when(
            () => mockUserWritingRepository.listUserWritingsByPromptId(
              promptId: any(named: 'promptId'),
            ),
          ).thenAnswer((_) async => const Right([]));

          // act
          final result = await mockUserWritingRepository
              .listUserWritingsByPromptId(
                promptId: tPromptId,
              );

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
          final result = await mockUserWritingRepository
              .listUserWritingsByPromptId(
                promptId: tPromptId,
              );

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

      group('updateUserWriting', () {
        test(
          'should return updated UserWriting when update is successful',
          () async {
            // arrange
            final updatedUserWriting = tUserWriting.copyWith(
              submissionText: tUserWritingUpdateRequest.submissionText!,
              aiFeedback: tUserWritingUpdateRequest.aiFeedback,
              aiScore: tUserWritingUpdateRequest.aiScore,
              evaluatedAt: tUserWritingUpdateRequest.evaluatedAt,
            );
            when(
              () => mockUserWritingRepository.updateUserWriting(
                id: any(named: 'id'),
                request: any(named: 'request'),
              ),
            ).thenAnswer((_) async => Right(updatedUserWriting));

            // act
            final result = await mockUserWritingRepository.updateUserWriting(
              id: tUserWritingId,
              request: tUserWritingUpdateRequest,
            );

            // assert
            expect(result, Right(updatedUserWriting));
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
            final result = await mockUserWritingRepository.updateUserWriting(
              id: tUserWritingId,
              request: tUserWritingUpdateRequest,
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
            final result = await mockUserWritingRepository.updateUserWriting(
              id: tUserWritingId,
              request: tUserWritingUpdateRequest,
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

      group('deleteUserWriting', () {
        test('should return Right(void) when deletion is successful', () async {
          // arrange
          when(
            () => mockUserWritingRepository.deleteUserWriting(
              id: any(named: 'id'),
            ),
          ).thenAnswer((_) async => const Right(Success()));

          // act
          final result = await mockUserWritingRepository.deleteUserWriting(
            id: tUserWritingId,
          );

          // assert
          expect(result, const Right(null));
          verify(
            () =>
                mockUserWritingRepository.deleteUserWriting(id: tUserWritingId),
          );
          verifyNoMoreInteractions(mockUserWritingRepository);
        });

        test(
          'should return ServerFailure when user writing does not exist',
          () async {
            // arrange
            const tFailure = ServerFailure(message: 'User writing not found');
            when(
              () => mockUserWritingRepository.deleteUserWriting(
                id: any(named: 'id'),
              ),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockUserWritingRepository.deleteUserWriting(
              id: tUserWritingId,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () => mockUserWritingRepository.deleteUserWriting(
                id: tUserWritingId,
              ),
            );
            verifyNoMoreInteractions(mockUserWritingRepository);
          },
        );

        test('should return ServerFailure when server error occurs', () async {
          // arrange
          const tFailure = ServerFailure(
            message: 'Failed to delete user writing',
          );
          when(
            () => mockUserWritingRepository.deleteUserWriting(
              id: any(named: 'id'),
            ),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockUserWritingRepository.deleteUserWriting(
            id: tUserWritingId,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () =>
                mockUserWritingRepository.deleteUserWriting(id: tUserWritingId),
          );
          verifyNoMoreInteractions(mockUserWritingRepository);
        });
      });
    });

    // Parameter Validation Tests
    group('Parameter Validation', () {
      group('ID Validation', () {
        test(
          'should handle negative ID gracefully in getWritingPrompt',
          () async {
            // arrange
            const negativeId = -1;
            const tFailure = ServerFailure(
              message: 'Invalid ID: must be positive',
            );
            when(
              () => mockWritingRepository.getWritingPrompt(id: negativeId),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockWritingRepository.getWritingPrompt(
              id: negativeId,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () => mockWritingRepository.getWritingPrompt(id: negativeId),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test('should handle zero ID gracefully in deleteUserWriting', () async {
          // arrange
          const zeroId = 0;
          const tFailure = ServerFailure(
            message: 'Invalid ID: must be positive',
          );
          when(
            () => mockUserWritingRepository.deleteUserWriting(id: zeroId),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockUserWritingRepository.deleteUserWriting(
            id: zeroId,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(() => mockUserWritingRepository.deleteUserWriting(id: zeroId));
          verifyNoMoreInteractions(mockUserWritingRepository);
        });
      });

      group('Request Validation', () {
        test(
          'should handle empty prompt text in createWritingPrompt',
          () async {
            // arrange
            const invalidRequest = WritingPromptRequest(
              userId: tUserId,
              promptText: '', // Empty prompt text
              topic: 'Valid Topic',
              difficultyLevel: 'Beginner',
            );
            const tFailure = ServerFailure(
              message: 'Prompt text cannot be empty',
            );
            when(
              () => mockWritingRepository.createWritingPrompt(
                request: invalidRequest,
              ),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockWritingRepository.createWritingPrompt(
              request: invalidRequest,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () => mockWritingRepository.createWritingPrompt(
                request: invalidRequest,
              ),
            );
            verifyNoMoreInteractions(mockWritingRepository);
          },
        );

        test(
          'should handle empty submission text in createUserWriting',
          () async {
            // arrange
            const invalidRequest = UserWritingRequest(
              userId: tUserId,
              promptId: tPromptId,
              submissionText: '', // Empty submission text
              aiFeedback: {'test': 'feedback'},
              aiScore: 5,
            );
            const tFailure = ServerFailure(
              message: 'Submission text cannot be empty',
            );
            when(
              () => mockUserWritingRepository.createUserWriting(
                request: invalidRequest,
              ),
            ).thenAnswer((_) async => const Left(tFailure));

            // act
            final result = await mockUserWritingRepository.createUserWriting(
              request: invalidRequest,
            );

            // assert
            expect(result, const Left(tFailure));
            verify(
              () => mockUserWritingRepository.createUserWriting(
                request: invalidRequest,
              ),
            );
            verifyNoMoreInteractions(mockUserWritingRepository);
          },
        );
      });
    });
  });
}
