import 'package:dio/dio.dart';
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

@RestApi()
sealed class WordRemoteDataSource {
  factory WordRemoteDataSource(final Dio dio) = _WordRemoteDataSource;

  @GET('/api/v1/words')
  Future<List<WordModel>> getWords({
    @Query('offset') final int? offset,
    @Query('limit') final int? limit,
  });

  @GET('/api/v1/words/{id}')
  Future<WordModel> getWord(
    @Path('id') final int id,
  );
}
