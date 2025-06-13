import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/part.dart';
import '../../domain/repositories/part_repository.dart';
import '../data_sources/part_remote_data_source.dart';
import '../model/part_model.dart';

part 'part_repository_impl.g.dart';

@riverpod
PartRepository partRepository(final Ref ref) {
  final dataSource = ref.watch(partRemoteDataSourceProvider);
  return PartRepositoryImpl(dataSource);
}

class PartRepositoryImpl implements PartRepository {

  const PartRepositoryImpl(this._remoteDataSource);

  final PartRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Part>> getPartById({
    required final int partId
  }) async {
    try {
      final response = await _remoteDataSource.getPartById(
        partId: partId,
      );
      return Right(response.toEntity());
    }
    on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } 
    catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Part>>> getPartsByExamId({
    required final int examId,
  }) async {
    try {
      final response = await _remoteDataSource.getPartsByExamId(
        examId: examId,
      );
      return Right([...response.map((final e) => e.toEntity())]);
    }
    on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } 
    catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

}
