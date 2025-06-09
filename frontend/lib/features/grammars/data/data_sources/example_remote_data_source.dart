import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../models/example_model.dart';

part 'example_remote_data_source.g.dart';

@riverpod
ExampleRemoteDataSource exampleRemoteDataSource(final Ref ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ExampleRemoteDataSource(dio);
}

@RestApi()
abstract class ExampleRemoteDataSource {

  factory ExampleRemoteDataSource(
    final Dio dio,
  ) = _ExampleRemoteDataSource;

  @GET('/api/v1/examples')
  Future<List<ExampleModel>> getExamples();

  @POST('/api/v1/examples/batch')
  Future<List<ExampleModel>> getExamplesByIds({
    @Body() required final ExampleRequest request,
  });

}
