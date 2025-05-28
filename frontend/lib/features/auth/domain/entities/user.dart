import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required final String id,
    required final String email,
    final String? name,
    final String? photoUrl,
  }) = _User;
}
