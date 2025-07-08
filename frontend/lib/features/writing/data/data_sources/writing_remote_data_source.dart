import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../models/writing_prompt_model.dart';

part 'writing_remote_data_source.g.dart';

@riverpod
WritingRemoteDataSource writingRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return WritingRemoteDataSource(dio);
}

@RestApi(
  parser: Parser.FlutterCompute,
)
abstract class WritingRemoteDataSource {
  factory WritingRemoteDataSource(
    final Dio dio,
  ) = _WritingRemoteDataSource;
  @POST('/api/v1/writing/prompts')
  Future<WritingPromptModel> createWritingPrompt({
    @Body() required final WritingPromptRequestModel request,
  });

  @GET('/api/v1/writing/prompts/{id}')
  Future<WritingPromptModel> getWritingPrompt({
    @Path('id') required final int id,
  });

  @GET('/api/v1/writing/prompts')
  Future<List<WritingPromptModel>> listWritingPrompts();

  @PUT('/api/v1/writing/prompts/{id}')
  Future<WritingPromptModel> updateWritingPrompt({
    @Path('id') required final int id,
    @Body() required final WritingPromptRequestModel request,
  });

  @DELETE('/api/v1/writing/prompts/{id}')
  Future<void> deleteWritingPrompt({
    @Path('id') required final int id,
  });
}

// Deserialize functions for retrofit FlutterCompute
WritingPromptModel deserializeWritingPromptModel(
  final Map<String, dynamic> json,
) => WritingPromptModel.fromJson(json);

List<WritingPromptModel> deserializeWritingPromptModelList(
  final List<dynamic> json,
) => json
    .map(
      (final item) => WritingPromptModel.fromJson(item as Map<String, dynamic>),
    )
    .toList();
