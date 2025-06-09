import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/example.dart';
import '../../domain/repositories/example_repository.dart';
import '../data_sources/example_remote_data_source.dart';
import '../models/example_model.dart';

part 'example_repository_impl.g.dart';

@riverpod
ExampleRepository exampleRepository(final Ref ref) {
  final dataSource = ref.watch(exampleRemoteDataSourceProvider);
  return ExampleRepositoryImpl(dataSource);
}

class ExampleRepositoryImpl implements ExampleRepository {

  const ExampleRepositoryImpl(this.exampleRemoteDataSource);

  final ExampleRemoteDataSource exampleRemoteDataSource;

  @override
  Future<Either<Failure, List<Example>>> getExamples() async {
    try {
      final response = await exampleRemoteDataSource.getExamples();
      return Right([...response.map((final e) => e.toEntity())]);
    }
    on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Example>>> getExamplesByIds({
    required final List<int> ids,
  }) async {
    try {
      final response = await exampleRemoteDataSource.getExamplesByIds(
        request: ExampleRequest(
          ids: ids,
        ),
      );
      return Right([...response.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }



}
