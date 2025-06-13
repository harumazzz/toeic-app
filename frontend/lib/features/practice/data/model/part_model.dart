import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/part.dart';

part 'part_model.freezed.dart';
part 'part_model.g.dart';

@freezed
sealed class PartModel with _$PartModel {
    const factory PartModel({
      @JsonKey(name: 'exam_id')
      required final int examId,
      @JsonKey(name: 'part_id')
      required final int partId,
      @JsonKey(name: 'title')
      required final String title,
    }) = _PartModel;

    factory PartModel.fromJson(
      final Map<String, dynamic> json,
    ) => _$PartModelFromJson(json);
}

extension PartModelExtension on PartModel {

  Part toEntity() => Part(
    examId: examId, 
    partId: partId, 
    title: title,
  );

}
