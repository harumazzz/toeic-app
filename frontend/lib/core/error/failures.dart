import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
abstract class Failure with _$Failure {
  const factory Failure.serverFailure({
    required final String message,
  }) = ServerFailure;

  const factory Failure.cacheFailure({
    required final String message,
  }) = CacheFailure;

  const factory Failure.networkFailure({
    required final String message,
  }) = NetworkFailure;

  const factory Failure.authenticationFailure({
    required final String message,
  }) = AuthenticationFailure;
}

@freezed
abstract class Success with _$Success {
  const factory Success() = _Success;

  const factory Success.withMessage({
    required final String message,
  }) = _SuccessWithMessage;
}
