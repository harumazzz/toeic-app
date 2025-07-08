import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_client.dart';
import '../models/exam_model.dart';

part 'exam_remote_data_source.g.dart';

@riverpod
ExamRemoteDataSource examRemoteDataSource(
  final Ref ref,
) {
  final dio = ref.watch(dioClientProvider).dio;
  return ExamRemoteDataSource(dio);
}

@RestApi(
  parser: Parser.FlutterCompute,
)
abstract class ExamRemoteDataSource {
  factory ExamRemoteDataSource(
    final Dio dio,
  ) = _ExamRemoteDataSource;

  @GET('/api/v1/exams/{id}/questions')
  Future<ExamModel> getExamQuestions({
    @Path('id') required final int examId,
  });
}

ExamModel deserializeExamModel(
  final Map<String, dynamic> json,
) => ExamModel.fromJson(json);
