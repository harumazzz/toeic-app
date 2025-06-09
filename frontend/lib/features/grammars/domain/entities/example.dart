import 'package:freezed_annotation/freezed_annotation.dart';

part 'example.freezed.dart';

@freezed
sealed class Example with _$Example {
    const factory Example({
      required final int id,
      required final String meaning,
      required final String title,
    }) = _Example;
}
