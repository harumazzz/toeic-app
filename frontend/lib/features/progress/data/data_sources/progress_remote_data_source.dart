import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../model/progress_model.dart';

part 'progress_remote_data_source.g.dart';

@riverpod
ProgressRemoteDataSource progressRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ProgressRemoteDataSource(dio);
}

@RestApi()
abstract class ProgressRemoteDataSource {

  factory ProgressRemoteDataSource(
    final Dio dio,
  ) = _ProgressRemoteDataSource;

  @POST('/api/v1/user-word-progress')
  Future<WordProgressModel> addNewProgress({
    @Body() required final WordProgressRequestModel request,
  });

  @GET('/api/v1/user-word-progress/reviews')
  Future<List<WordProgressModel>> getReviewWords({
    @Query('limit') required final int limit,
  });

  @GET('/api/v1/user-word-progress/word/{word_id}')
  Future<WordProgressModel> getWordProgressById({
    @Path('word_id') required final int wordId,
  });

  @GET('/api/v1/user-word-progress/{word_id}')
  Future<ProgressModel> getProgressById({
    @Path('word_id') required final int progressId,
  });

  @PUT('/api/v1/user-word-progress/{word_id}')
  Future<WordProgressModel> updateWordProgress({
    @Path('word_id') required final int wordId,
    @Body() required final WordProgressRequestModel request,
  });

  @DELETE('/api/v1/user-word-progress/{word_id}')
  Future<void> deleteWordProgress({
    @Path('word_id') required final int wordId,
  });


}
