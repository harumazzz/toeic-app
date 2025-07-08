import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../model/part_model.dart';

part 'part_remote_data_source.g.dart';

@riverpod
PartRemoteDataSource partRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return PartRemoteDataSource(dio);
}

@RestApi(
  parser: Parser.FlutterCompute,
)
abstract class PartRemoteDataSource {
  factory PartRemoteDataSource(
    final Dio dio,
  ) = _PartRemoteDataSource;

  @GET('/api/v1/parts/{part_id}')
  Future<PartModel> getPartById({
    @Path('part_id') required final int partId,
  });

  @GET('/api/v1/exam-parts/{exam_id}')
  Future<List<PartModel>> getPartsByExamId({
    @Path('exam_id') required final int examId,
  });
}

PartModel deserializePartModel(
  final Map<String, dynamic> json,
) => PartModel.fromJson(json);

List<PartModel> deserializePartModelList(
  final List<dynamic> json,
) => json
    .map((final item) => PartModel.fromJson(item as Map<String, dynamic>))
    .toList();
