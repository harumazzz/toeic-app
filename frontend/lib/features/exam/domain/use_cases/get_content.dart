import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../entities/content.dart';
import '../repositories/content_repository.dart';

part 'get_content.freezed.dart';
part 'get_content.g.dart';

@riverpod
GetContent getContent(final Ref ref) {
  final repository = ref.watch(contentRepositoryProvider);
  return GetContent(repository);
}

@riverpod
GetContentByParts getContentByParts(final Ref ref) {
  final repository = ref.watch(contentRepositoryProvider);
  return GetContentByParts(repository);
}

@freezed
sealed class GetContentParams with _$GetContentParams {
  const factory GetContentParams({
    required final int contentId,
  }) = _GetContentParams;
}

@freezed
sealed class GetContentByPartsParams with _$GetContentByPartsParams {
  const factory GetContentByPartsParams({
    required final int partId,
  }) = _GetContentByPartsParams;
}

class GetContent implements UseCase<Content, GetContentParams> {
  const GetContent(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<Failure, Content>> call(
    final GetContentParams params,
  ) => _contentRepository.getContentById(
    contentId: params.contentId,
  );
}

class GetContentByParts implements 
UseCase<List<Content>, GetContentByPartsParams> {
  const GetContentByParts(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<Failure, List<Content>>> call(
    final GetContentByPartsParams params,
  ) => _contentRepository.getContentByParts(
    partId: params.partId,
  );
}
