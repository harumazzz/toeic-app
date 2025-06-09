import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/example_repository_impl.dart';
import '../entities/example.dart';
import '../repositories/example_repository.dart';

part 'get_example.g.dart';
part 'get_example.freezed.dart';

@riverpod
GetExamples getExamples(final Ref ref) {
  final exampleRepository = ref.watch(exampleRepositoryProvider);
  return GetExamples(exampleRepository);
}

@riverpod
GetExamplesByIds getExamplesByIds(final Ref ref) {
  final exampleRepository = ref.watch(exampleRepositoryProvider);
  return GetExamplesByIds(exampleRepository);
}

class GetExamples implements UseCase<List<Example>, NoParams> {

  const GetExamples(this.exampleRepository);

  final ExampleRepository exampleRepository;

  @override
  Future<Either<Failure, List<Example>>> call(
    final NoParams params,
  ) => exampleRepository.getExamples();
  
}

@freezed
sealed class GetExamplesByIdsParams with _$GetExamplesByIdsParams {
  const factory GetExamplesByIdsParams({
    required final List<int> ids,
  }) = _GetExamplesByIdsParams;
}

class GetExamplesByIds implements 
UseCase<List<Example>, GetExamplesByIdsParams> {

  const GetExamplesByIds(this.exampleRepository);

  final ExampleRepository exampleRepository;

  @override
  Future<Either<Failure, List<Example>>> call(
    final GetExamplesByIdsParams params
  ) => exampleRepository.getExamplesByIds(
    ids: params.ids,
  );

}
