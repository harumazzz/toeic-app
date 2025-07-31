import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../models/user_writing_model.dart';

part 'user_writing_remote_data_source.g.dart';

@riverpod
UserWritingRemoteDataSource userWritingRemoteDataSource(
  final Ref ref,
) {
  final dio = ref.watch(dioClientProvider).dio;
  return UserWritingRemoteDataSource(dio);
}

@RestApi(
  parser: Parser.FlutterCompute,
)
abstract class UserWritingRemoteDataSource {
  factory UserWritingRemoteDataSource(
    final Dio dio,
  ) = _UserWritingRemoteDataSource;

  @POST('/api/v1/writing/submissions')
  Future<UserWritingModel> createUserWriting({
    @Body() required final UserWritingRequestModel request,
  });

  @GET('/api/v1/writing/submissions/{id}')
  Future<UserWritingModel> getUserWriting({
    @Path('id') required final int id,
  });

  @GET('/api/v1/writing/users/{userId}/submissions')
  Future<List<UserWritingModel>> listUserWritingsByUserId({
    @Path('userId') required final int userId,
  });

  @GET('/api/v1/writing/prompt-submissions/{promptId}')
  Future<List<UserWritingModel>> listUserWritingsByPromptId({
    @Path('promptId') required final int promptId,
  });

  @PUT('/api/v1/writing/submissions/{id}')
  Future<UserWritingModel> updateUserWriting({
    @Path('id') required final int id,
    @Body() required final UserWritingUpdateRequestModel request,
  });

  @DELETE('/api/v1/writing/submissions/{id}')
  Future<void> deleteUserWriting({
    @Path('id') required final int id,
  });
}

UserWritingModel deserializeUserWritingModel(
  final Map<String, dynamic> json,
) => UserWritingModel.fromJson(json);

List<UserWritingModel> deserializeUserWritingModelList(
  final List<dynamic> json,
) => json
    .map(
      (final item) => UserWritingModel.fromJson(item as Map<String, dynamic>),
    )
    .toList();
