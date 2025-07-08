import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../model/exam_model.dart';

part 'exam_remote_data_source.g.dart';

@riverpod
ExamRemoteDataSource examRemoteDataSource(final Ref ref) {
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

  @GET('/api/v1/exams/{exam_id}')
  Future<ExamModel> getExamById({
    @Path('exam_id') required final int examId,
  });

  @GET('/api/v1/exams')
  Future<List<ExamModel>> getExams({
    @Query('limit') required final int limit,
    @Query('offset') required final int offset,
  });
}

ExamModel deserializeExamModel(
  final Map<String, dynamic> json,
) => ExamModel.fromJson(json);

List<ExamModel> deserializeExamModelList(
  final List<dynamic> json,
) => json
    .map((final item) => ExamModel.fromJson(item as Map<String, dynamic>))
    .toList();
