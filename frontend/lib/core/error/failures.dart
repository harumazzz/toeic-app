import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
abstract class Failure with _$Failure {
  const factory Failure.serverFailure({required String message}) = ServerFailure;
  const factory Failure.cacheFailure({required String message}) = CacheFailure;
  const factory Failure.networkFailure({required String message}) = NetworkFailure;
  const factory Failure.authenticationFailure({required String message}) = AuthenticationFailure;
}
