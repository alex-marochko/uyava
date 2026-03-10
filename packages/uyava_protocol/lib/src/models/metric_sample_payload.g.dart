// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metric_sample_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UyavaMetricSamplePayloadImpl _$$UyavaMetricSamplePayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaMetricSamplePayloadImpl(
  id: json['id'] as String,
  value: (json['value'] as num).toDouble(),
  timestamp: _dateTimeFromJson(json['timestamp'] as String?),
);

Map<String, dynamic> _$$UyavaMetricSamplePayloadImplToJson(
  _$UyavaMetricSamplePayloadImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'value': instance.value,
  'timestamp': _dateTimeToJson(instance.timestamp),
};
