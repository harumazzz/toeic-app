import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../models/text_analyze_model.dart';

part 'text_analyze_remote_data_source.g.dart';

@riverpod
TextAnalyzeRemoteDataSource textAnalyzeRemoteDataSource(
  final Ref ref,
) {
  final dio = ref.watch(dioClientProvider).dio;
  return TextAnalyzeRemoteDataSource(dio);
}

@RestApi()
abstract class TextAnalyzeRemoteDataSource {

  factory TextAnalyzeRemoteDataSource (
    final Dio dio
  ) = _TextAnalyzeRemoteDataSource;

  @POST('/api/v1/analyze/text')
  Future<TextAnalyzeModel> analyzeText({
    required final TextAnalyzeRequestModel request,
  });

}
