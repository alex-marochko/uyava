// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_node_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UyavaGraphNodePayloadImpl _$$UyavaGraphNodePayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaGraphNodePayloadImpl(
  id: json['id'] as String,
  type: json['type'] as String? ?? 'unknown',
  label: json['label'] as String,
  description: json['description'] as String?,
  parentId: json['parentId'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  tagsNormalized:
      (json['tagsNormalized'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  tagsCatalog: (json['tagsCatalog'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  color: json['color'] as String?,
  colorPriorityIndex: (json['colorPriorityIndex'] as num?)?.toInt(),
  shape: json['shape'] as String?,
  lifecycle: json['lifecycle'] == null
      ? UyavaLifecycleState.unknown
      : _lifecycleFromJson(json['lifecycle'] as String?),
  initSource: json['initSource'] as String?,
);

Map<String, dynamic> _$$UyavaGraphNodePayloadImplToJson(
  _$UyavaGraphNodePayloadImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'label': instance.label,
  'description': instance.description,
  'parentId': instance.parentId,
  'tags': instance.tags,
  'tagsNormalized': instance.tagsNormalized,
  'tagsCatalog': instance.tagsCatalog,
  'color': instance.color,
  'colorPriorityIndex': instance.colorPriorityIndex,
  'shape': instance.shape,
  'lifecycle': _lifecycleToJson(instance.lifecycle),
  'initSource': instance.initSource,
};
