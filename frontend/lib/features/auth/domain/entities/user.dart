import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required final int id,
    required final String email,
    required final String username,
  }) = _User;
}
