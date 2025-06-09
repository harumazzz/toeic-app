import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../model/question_model.dart';

part 'question_remote_data_source.g.dart';

@riverpod
QuestionRemoteDataSource questionRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return QuestionRemoteDataSource(dio);
}

@RestApi() 
abstract class QuestionRemoteDataSource {

  factory QuestionRemoteDataSource(
    final Dio dio,
  ) = _QuestionRemoteDataSource; 

  @GET('/api/v1/content-questions/{content_id}')
  Future<List<QuestionModel>> getQuestionsByContentId({
    @Query('content_id') required final int contentId,
  });

  @GET('/api/v1/questions/{question_id}')
  Future<QuestionModel> getQuestionById({
    @Path('question_id') required final int questionId,
  });

}
