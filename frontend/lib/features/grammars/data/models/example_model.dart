import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/example.dart';

part 'example_model.freezed.dart';
part 'example_model.g.dart';

@freezed
abstract class ExampleModel with _$ExampleModel {
  const factory ExampleModel({
    @JsonKey(name: 'id') required final int id,
    @JsonKey(name: 'meaning') required final String meaning,
    @JsonKey(name: 'title') required final String title,
  }) = _ExampleModel;

  factory ExampleModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$ExampleModelFromJson(json);
}

@freezed
abstract class ExampleRequest with _$ExampleRequest {
  const factory ExampleRequest({
    @JsonKey(name: 'ids') required final List<int> ids,
  }) = _ExampleRequest;

  factory ExampleRequest.fromJson(
    final Map<String, dynamic> json,
  ) => _$ExampleRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

extension ExampleModelExtension on ExampleModel {
  Example toEntity() => Example(
    id: id,
    meaning: meaning,
    title: title,
  );
}

Map<String, dynamic> serializeExampleRequest(
  final ExampleRequest object,
) => object.toJson();
