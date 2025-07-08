import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_client.dart';
import '../models/exam_model.dart';

part 'exam_attempt_remote_data_source.g.dart';

@riverpod
ExamAttemptRemoteDataSource examAttemptRemoteDataSource(
  final Ref ref,
) {
  final dio = ref.watch(dioClientProvider).dio;
  return ExamAttemptRemoteDataSource(dio);
}

@RestApi(
  parser: Parser.FlutterCompute,
)
abstract class ExamAttemptRemoteDataSource {
  factory ExamAttemptRemoteDataSource(
    final Dio dio,
  ) = _ExamAttemptRemoteDataSource;

  @GET('/api/v1/exam-attempts')
  Future<List<ExamAttemptModel>> getExamAttempts();

  @POST('/api/v1/exam-attempts')
  Future<ExamAttemptModel> createExamAttempt({
    @Body() required final ExamModelRequest examAttempt,
  });

  @GET('/api/v1/exam-attempts/stats')
  Future<ExamStatsModel> getExamAttemptStats();

  @GET('/api/v1/exam-attempts/{id}')
  Future<ExamAttemptModel> getExamAttemptById({
    @Path('id') required final int id,
  });

  @PUT('/api/v1/exam-attempts/{id}')
  Future<ExamAttemptModel> updateExamAttempt({
    @Path('id') required final int id,
    @Body() required final UpdateExamAttemptModel examAttempt,
  });

  @DELETE('/api/v1/exam-attempts/{id}')
  Future<void> deleteExamAttempt({
    @Path('id') required final int id,
  });

  @POST('/api/v1/exam-attempts/{id}/abandon')
  Future<ExamAttemptModel> abandonExamAttempt({
    @Path('id') required final int id,
  });

  @POST('/api/v1/exam-attempts/{id}/complete')
  Future<ExamAttemptModel> completeExamAttempt({
    @Path('id') required final int id,
  });
}

List<ExamAttemptModel> deserializeExamAttemptModelList(
  final List<dynamic> json,
) => json
    .map(
      (final item) => ExamAttemptModel.fromJson(item as Map<String, dynamic>),
    )
    .toList();

ExamAttemptModel deserializeExamAttemptModel(
  final Map<String, dynamic> json,
) => ExamAttemptModel.fromJson(json);

ExamStatsModel deserializeExamStatsModel(
  final Map<String, dynamic> json,
) => ExamStatsModel.fromJson(json);
