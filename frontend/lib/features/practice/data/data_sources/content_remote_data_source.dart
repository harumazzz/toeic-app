import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../model/content_model.dart';

part 'content_remote_data_source.g.dart';

@riverpod
ContentRemoteDataSource contentRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ContentRemoteDataSource(dio);
}

@RestApi(
  parser: Parser.FlutterCompute,
)
abstract class ContentRemoteDataSource {
  factory ContentRemoteDataSource(
    final Dio dio,
  ) = _ContentRemoteDataSource;

  @GET('/api/v1/contents/{content_id}')
  Future<ContentModel> getContentById({
    @Path('content_id') required final int contentId,
  });

  @GET('/api/v1/part-contents/{part_id}')
  Future<List<ContentModel>> getContentsByParts({
    @Path('part_id') required final int partId,
  });
}

ContentModel deserializeContentModel(
  final Map<String, dynamic> json,
) => ContentModel.fromJson(json);

List<ContentModel> deserializeContentModelList(
  final List<dynamic> json,
) => json
    .map((final item) => ContentModel.fromJson(item as Map<String, dynamic>))
    .toList();
