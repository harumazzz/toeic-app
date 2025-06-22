import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/text_analyze.dart';
import '../../domain/repositories/text_analyze_repository.dart';
import '../data_sources/text_analyze_remote_data_source.dart';
import '../models/text_analyze_model.dart';

part 'text_analyze_repository_impl.g.dart';

@riverpod
TextAnalyzeRepository textAnalyzeRepository(
  final Ref ref,
) {
  final dataSource = ref.watch(textAnalyzeRemoteDataSourceProvider);
  return TextAnalyzeRepositoryImpl(
    textAnalyzeRemoteDataSource: dataSource,
  );
}

class TextAnalyzeRepositoryImpl implements TextAnalyzeRepository {

  const TextAnalyzeRepositoryImpl({
    required final TextAnalyzeRemoteDataSource textAnalyzeRemoteDataSource,
  }) : _textAnalyzeRemoteDataSource = textAnalyzeRemoteDataSource;

  final TextAnalyzeRemoteDataSource _textAnalyzeRemoteDataSource;

  @override
  Future<Either<Failure, TextAnalyze>> analyzeText({
    required final TextAnalyzeRequest request,
  }) async {
    try {
      final response = await _textAnalyzeRemoteDataSource.analyzeText(
        request: request.toModel(),
      );
      return Right(response.toEntity());
    }
    on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    }
    catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

}
