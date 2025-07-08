import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../models/grammar_model.dart';

part 'grammar_remote_data_source.g.dart';

@riverpod
GrammarRemoteDataSource grammarRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return GrammarRemoteDataSource(dio);
}

@RestApi(
  parser: Parser.FlutterCompute,
)
abstract class GrammarRemoteDataSource {
  factory GrammarRemoteDataSource(
    final Dio dio,
  ) = _GrammarRemoteDataSource;

  @GET('/api/v1/grammars')
  Future<List<GrammarModel>> getAllGrammars({
    @Query('limit') required final int limit,
    @Query('offset') required final int offset,
  });

  @GET('/api/v1/grammars/level')
  Future<List<GrammarModel>> getAllGrammarsByLevel({
    @Query('level') required final int level,
    @Query('limit') required final int limit,
    @Query('offset') required final int offset,
  });

  @GET('/api/v1/grammars/tag')
  Future<List<GrammarModel>> getAllGrammarsByTag({
    @Query('tag') required final String tag,
    @Query('limit') required final int limit,
    @Query('offset') required final int offset,
  });

  @POST('/api/v1/grammars/batch')
  Future<List<GrammarModel>> getRelatedGrammars({
    @Body() required final GetRelatedGrammarsRequest ids,
  });

  @GET('/api/v1/grammars/search')
  Future<List<GrammarModel>> searchGrammars({
    @Query('query') required final String query,
    @Query('limit') required final int limit,
    @Query('offset') required final int offset,
  });

  @GET('/api/v1/grammars/{id}')
  Future<GrammarModel> getGrammarById({
    @Path('id') required final int id,
  });

  @GET('/api/v1/grammars/random')
  Future<GrammarModel> getRandomGrammar();
}

List<GrammarModel> deserializeGrammarModelList(
  final List<dynamic> json,
) => json
    .map((final item) => GrammarModel.fromJson(item as Map<String, dynamic>))
    .toList();

GrammarModel deserializeGrammarModel(
  final Map<String, dynamic> json,
) => GrammarModel.fromJson(json);
