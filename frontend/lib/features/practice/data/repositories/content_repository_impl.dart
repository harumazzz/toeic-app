import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/content.dart';
import '../../domain/repositories/content_repository.dart';
import '../data_sources/content_remote_data_source.dart';
import '../model/content_model.dart';

part 'content_repository_impl.g.dart';

@riverpod
ContentRepository contentRepository(final Ref ref) {
  final dataSource = ref.watch(contentRemoteDataSourceProvider);
  return ContentRepositoryImpl(dataSource);
}

class ContentRepositoryImpl implements ContentRepository {

  const ContentRepositoryImpl(this._remoteDataSource);

  final ContentRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Content>> getContentById({
    required final int contentId,
  }) async {
    try {
      final response = await _remoteDataSource.getContentById(
        contentId: contentId,
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
  Future<Either<Failure, List<Content>>> getContentByParts({
    required final int partId,
  }) async {
    try {
      final response = await _remoteDataSource.getContentsByParts(
        partId: partId,
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
