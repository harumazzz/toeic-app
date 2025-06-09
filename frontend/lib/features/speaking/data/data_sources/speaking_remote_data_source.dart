import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../models/speaking_model.dart';

part 'speaking_remote_data_source.g.dart';

@riverpod
SpeakingRemoteDataSource speakingRemoteDataSource(
  final Ref ref,
) {
  final dio = ref.watch(dioClientProvider).dio;
  return SpeakingRemoteDataSource(dio);
}

@RestApi()
abstract class SpeakingRemoteDataSource {
  factory SpeakingRemoteDataSource(
    final Dio dio,
  ) = _SpeakingRemoteDataSource;

  @POST('/api/v1/speaking/sessions')
  Future<SpeakingModel> createSession({
    @Body() required final SpeakingRequestModel speakingRequest,
  });

  @GET('/api/v1/speaking/sessions/{id}')
  Future<SpeakingModel> getSessionById({
    @Path('id') required final int id,
  });

  @PUT('/api/v1/speaking/sessions/{id}')
  Future<SpeakingModel> updateSession({
    @Path('id') required final int id,
    @Body() required final SpeakingRequestModel speakingRequest,
  });
  @DELETE('/api/v1/speaking/sessions/{id}')
  Future<void> deleteSession({
    @Path('id') required final int id,
  });

  @GET('/api/v1/speaking/sessions/{id}/turns')
  Future<List<SpeakingTurnModel>> getSpeakingTurns({
    @Path('id') required final int sessionId,
  });

  @POST('/api/v1/speaking/sessions/turns')
  Future<SpeakingTurnModel> createNewTurn({
    @Body() required final SpeakingTurnRequestModel request,
  });

  @GET('/api/v1/speaking/sessions/turns/{id}')
  Future<SpeakingTurnModel> getTurnById({
    @Path('id') required final int id,
  });

  @PUT('/api/v1/speaking/sessions/turns/{id}')
  Future<SpeakingTurnModel> updateTurn({
    @Path('id') required final int id,
    @Body() required final SpeakingTurnRequestModel request,
  });

  @DELETE('/api/v1/speaking/sessions/turns/{id}')
  Future<void> deleteTurn({
    @Path('id') required final int id,
  });
  @GET('/api/v1/speaking/users/{userId}/sessions')
  Future<List<SpeakingModel>> getSpeakingSessions({
    @Path('userId') required final int userId,
  });
}
