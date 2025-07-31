import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../models/word_model.dart';

part 'word_remote_datasources.g.dart';

@riverpod
WordRemoteDataSource wordRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return WordRemoteDataSource(dio);
}

@RestApi(
  parser: Parser.FlutterCompute,
)
abstract class WordRemoteDataSource {
  factory WordRemoteDataSource(final Dio dio) = _WordRemoteDataSource;

  @GET('/api/v1/words')
  Future<List<WordModel>> getWords({
    @Query('offset') required final int offset,
    @Query('limit') required final int limit,
  });

  @GET('/api/v1/words/{id}')
  Future<WordModel> getWord(
    @Path('id') final int id,
  );

  @GET('/api/v1/words/search')
  Future<List<WordModel>> searchWords({
    @Query('query') required final String query,
    @Query('offset') required final int offset,
    @Query('limit') required final int limit,
  });
}

WordModel deserializeWordModel(
  final Map<String, dynamic> json,
) => WordModel.fromJson(json);

List<WordModel> deserializeWordModelList(
  final List<dynamic> json,
) => json
    .map((final item) => WordModel.fromJson(item as Map<String, dynamic>))
    .toList();
