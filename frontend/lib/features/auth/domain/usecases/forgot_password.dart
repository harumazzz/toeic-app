import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

part 'forgot_password.freezed.dart';
part 'forgot_password.g.dart';

@riverpod
ForgotPassword forgotPassword(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ForgotPassword(repository);
}

final class ForgotPassword implements UseCase<bool, ForgotPasswordParams> {
  const ForgotPassword(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, bool>> call(
    final ForgotPasswordParams params,
  ) async => repository.forgotPassword(params.email);
}

@freezed
sealed class ForgotPasswordParams with _$ForgotPasswordParams {
  const factory ForgotPasswordParams({
    required final String email,
  }) = _ForgotPasswordParams;
}
