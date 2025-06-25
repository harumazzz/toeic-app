import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/exam.dart';
import '../models/exam_model.dart';
import '../models/result_model.dart' as result;

part 'user_answer_remote_data_source.g.dart';

@riverpod
UserAnswerRemoteDataSource userAnswerRemoteDataSource(
  final Ref ref,
) {
  final dio = ref.watch(dioClientProvider).dio;
  return UserAnswerRemoteDataSource(dio);
}

@RestApi()
abstract class UserAnswerRemoteDataSource {
  factory UserAnswerRemoteDataSource(
    final Dio dio,
  ) = _UserAnswerRemoteDataSource;

  @GET('/api/v1/user-answers')
  Future<UserAnswerResponseModel> getUserAnswers();

  @POST('/api/v1/user-answers')
  Future<UserAnswerModel> createUserAnswer({
    @Body() required final result.UserAnswerRequestModel userAnswer,
  });

  @GET('/api/v1/user-answers/{id}')
  Future<UserAnswerModel> getUserAnswerById({
    @Path('id') required final int id,
  });

  @PUT('/api/v1/user-answers/{id}')
  Future<UserAnswerModel> updateUserAnswer({
    @Path('id') required final int id,
    @Body() required final result.UpdateUserAnswerRequestModel userAnswer,
  });

  @DELETE('/api/v1/user-answers/{id}')
  Future<void> deleteUserAnswer({
    @Path('id') required final int id,
  });

  @POST('/api/v1/user-answers/{id}/abandon')
  Future<UserAnswerModel> abandonUserAnswer({
    @Path('id') required final int id,
  });

  @POST('/api/v1/user-answers/{id}/complete')
  Future<UserAnswerModel> completeUserAnswer({
    @Path('id') required final int id,
  });

  @POST('/api/v1/user-answers/bulk')
  Future<result.UserResultModel> submitAnswers({
    @Body() required final result.AnswerModel request,
  });
}
