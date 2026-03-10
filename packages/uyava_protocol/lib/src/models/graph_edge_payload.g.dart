// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_edge_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UyavaGraphEdgePayloadImpl _$$UyavaGraphEdgePayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaGraphEdgePayloadImpl(
  id: json['id'] as String,
  source: json['source'] as String,
  target: json['target'] as String,
  label: json['label'] as String?,
  description: json['description'] as String?,
  remapped: json['remapped'] as bool? ?? false,
  bidirectional: json['bidirectional'] as bool? ?? false,
);

Map<String, dynamic> _$$UyavaGraphEdgePayloadImplToJson(
  _$UyavaGraphEdgePayloadImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'source': instance.source,
  'target': instance.target,
  'label': instance.label,
  'description': instance.description,
  'remapped': instance.remapped,
  'bidirectional': instance.bidirectional,
};
