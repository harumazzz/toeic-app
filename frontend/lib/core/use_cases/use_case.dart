import 'package:dart_either/dart_either.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(
    final Params params,
  );
}

final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
