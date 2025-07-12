import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/writing/data/data_sources/writing_remote_data_source.dart';
import 'package:learn/features/writing/data/models/writing_prompt_model.dart';
import 'package:learn/features/writing/data/repositories/writing_repository_impl.dart';
import 'package:learn/features/writing/domain/entities/writing_prompt.dart';

class FakeWritingRemoteDataSource implements WritingRemoteDataSource {
  @override
  Future<List<WritingPromptModel>> listWritingPrompts() async => [
    WritingPromptModel(
      id: 1,
      userId: 2,
      promptText: 'Test prompt',
      topic: 'Test topic',
      difficultyLevel: 'easy',
      createdAt: DateTime(2023),
    ),
  ];

  // Implement other methods as needed with throw UnimplementedError()
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  group('WritingRepositoryImpl', () {
    late WritingRepositoryImpl repository;
    late FakeWritingRemoteDataSource fakeRemoteDataSource;

    setUp(() {
      fakeRemoteDataSource = FakeWritingRemoteDataSource();
      repository = WritingRepositoryImpl(fakeRemoteDataSource);
    });
  });
}
