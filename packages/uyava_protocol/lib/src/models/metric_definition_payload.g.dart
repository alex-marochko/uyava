// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metric_definition_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UyavaMetricDefinitionPayloadImpl _$$UyavaMetricDefinitionPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaMetricDefinitionPayloadImpl(
  id: json['id'] as String,
  label: json['label'] as String?,
  description: json['description'] as String?,
  unit: json['unit'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  tagsNormalized:
      (json['tagsNormalized'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  aggregators:
      (json['aggregators'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$UyavaMetricAggregatorEnumMap, e))
          .toList() ??
      const <UyavaMetricAggregator>[UyavaMetricAggregator.last],
);

Map<String, dynamic> _$$UyavaMetricDefinitionPayloadImplToJson(
  _$UyavaMetricDefinitionPayloadImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'description': instance.description,
  'unit': instance.unit,
  'tags': instance.tags,
  'tagsNormalized': instance.tagsNormalized,
  'aggregators': instance.aggregators
      .map((e) => _$UyavaMetricAggregatorEnumMap[e]!)
      .toList(),
};

const _$UyavaMetricAggregatorEnumMap = {
  UyavaMetricAggregator.last: 'last',
  UyavaMetricAggregator.min: 'min',
  UyavaMetricAggregator.max: 'max',
  UyavaMetricAggregator.sum: 'sum',
  UyavaMetricAggregator.count: 'count',
};
