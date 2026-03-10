// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use_from_same_package

part of 'event_chain_definition_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UyavaEventChainDefinitionPayloadImpl
_$$UyavaEventChainDefinitionPayloadImplFromJson(Map<String, dynamic> json) =>
    _$UyavaEventChainDefinitionPayloadImpl(
      id: json['id'] as String,
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
      tag: json['tag'] as String?,
      label: json['label'] as String?,
      description: json['description'] as String?,
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map(
                (e) => UyavaEventChainStepPayload.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <UyavaEventChainStepPayload>[],
    );

Map<String, dynamic> _$$UyavaEventChainDefinitionPayloadImplToJson(
  _$UyavaEventChainDefinitionPayloadImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'tags': instance.tags,
  'tagsNormalized': instance.tagsNormalized,
  'tagsCatalog': instance.tagsCatalog,
  'tag': instance.tag,
  'label': instance.label,
  'description': instance.description,
  'steps': instance.steps,
};

_$UyavaEventChainStepPayloadImpl _$$UyavaEventChainStepPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaEventChainStepPayloadImpl(
  stepId: json['stepId'] as String,
  nodeId: json['nodeId'] as String,
  edgeId: json['edgeId'] as String?,
  expectedSeverity: _severityFromJson(json['expectedSeverity'] as String?),
);

Map<String, dynamic> _$$UyavaEventChainStepPayloadImplToJson(
  _$UyavaEventChainStepPayloadImpl instance,
) => <String, dynamic>{
  'stepId': instance.stepId,
  'nodeId': instance.nodeId,
  'edgeId': instance.edgeId,
  'expectedSeverity': _severityToJson(instance.expectedSeverity),
};
