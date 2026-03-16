// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_edge_event_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UyavaGraphEdgeEventPayloadImpl _$$UyavaGraphEdgeEventPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaGraphEdgeEventPayloadImpl(
  edgeId: json['edge'] as String?,
  from: json['from'] as String,
  to: json['to'] as String,
  message: json['message'] as String,
  severity: _severityFromJson(json['severity'] as String?),
  timestamp: _dateTimeFromJson(json['timestamp'] as String),
  sourceRef: json['sourceRef'] as String?,
);

Map<String, dynamic> _$$UyavaGraphEdgeEventPayloadImplToJson(
  _$UyavaGraphEdgeEventPayloadImpl instance,
) => <String, dynamic>{
  'edge': instance.edgeId,
  'from': instance.from,
  'to': instance.to,
  'message': instance.message,
  'severity': _severityToJson(instance.severity),
  'timestamp': _dateTimeToJson(instance.timestamp),
  'sourceRef': instance.sourceRef,
};
