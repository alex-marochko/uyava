// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_diagnostic_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UyavaGraphDiagnosticPayloadImpl _$$UyavaGraphDiagnosticPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaGraphDiagnosticPayloadImpl(
  code: json['code'] as String,
  codeEnum: _integrityCodeFromJson(json['codeEnum'] as String?),
  level: _diagnosticLevelFromJson(json['level'] as String?),
  nodeId: json['nodeId'] as String?,
  edgeId: json['edgeId'] as String?,
  context: json['context'] as Map<String, dynamic>?,
  timestamp: _dateTimeFromJson(json['timestamp'] as String?),
);

Map<String, dynamic> _$$UyavaGraphDiagnosticPayloadImplToJson(
  _$UyavaGraphDiagnosticPayloadImpl instance,
) => <String, dynamic>{
  'code': instance.code,
  'codeEnum': _integrityCodeToJson(instance.codeEnum),
  'level': _diagnosticLevelToJson(instance.level),
  'nodeId': instance.nodeId,
  'edgeId': instance.edgeId,
  'context': instance.context,
  'timestamp': _dateTimeToJson(instance.timestamp),
};
