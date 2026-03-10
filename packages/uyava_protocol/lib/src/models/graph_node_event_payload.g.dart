// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_node_event_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UyavaGraphNodeEventPayloadImpl _$$UyavaGraphNodeEventPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaGraphNodeEventPayloadImpl(
  nodeId: json['nodeId'] as String,
  message: json['message'] as String,
  severity: _severityFromJson(json['severity'] as String?),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  timestamp: _dateTimeFromJson(json['timestamp'] as String),
  sourceRef: json['sourceRef'] as String?,
  payload: json['payload'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$$UyavaGraphNodeEventPayloadImplToJson(
  _$UyavaGraphNodeEventPayloadImpl instance,
) => <String, dynamic>{
  'nodeId': instance.nodeId,
  'message': instance.message,
  'severity': _severityToJson(instance.severity),
  'tags': instance.tags,
  'timestamp': _dateTimeToJson(instance.timestamp),
  'sourceRef': instance.sourceRef,
  'payload': instance.payload,
};
