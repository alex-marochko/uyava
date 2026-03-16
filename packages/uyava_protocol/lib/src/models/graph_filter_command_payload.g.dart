// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_filter_command_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UyavaGraphFilterCommandPayloadImpl
_$$UyavaGraphFilterCommandPayloadImplFromJson(Map<String, dynamic> json) =>
    _$UyavaGraphFilterCommandPayloadImpl(
      search: json['search'] == null
          ? null
          : UyavaGraphFilterSearchPayload.fromJson(
              json['search'] as Map<String, dynamic>,
            ),
      tags: json['tags'] == null
          ? null
          : UyavaGraphFilterTagsPayload.fromJson(
              json['tags'] as Map<String, dynamic>,
            ),
      nodes: json['nodes'] == null
          ? null
          : UyavaGraphFilterIdSetPayload.fromJson(
              json['nodes'] as Map<String, dynamic>,
            ),
      edges: json['edges'] == null
          ? null
          : UyavaGraphFilterIdSetPayload.fromJson(
              json['edges'] as Map<String, dynamic>,
            ),
      parent: json['parent'] == null
          ? null
          : UyavaGraphFilterParentPayload.fromJson(
              json['parent'] as Map<String, dynamic>,
            ),
      grouping: json['grouping'] == null
          ? null
          : UyavaGraphFilterGroupingPayload.fromJson(
              json['grouping'] as Map<String, dynamic>,
            ),
      severity: json['severity'] == null
          ? null
          : UyavaGraphFilterSeverityPayload.fromJson(
              json['severity'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$$UyavaGraphFilterCommandPayloadImplToJson(
  _$UyavaGraphFilterCommandPayloadImpl instance,
) => <String, dynamic>{
  'search': instance.search?.toJson(),
  'tags': instance.tags?.toJson(),
  'nodes': instance.nodes?.toJson(),
  'edges': instance.edges?.toJson(),
  'parent': instance.parent?.toJson(),
  'grouping': instance.grouping?.toJson(),
  'severity': instance.severity?.toJson(),
};

_$UyavaGraphFilterSearchPayloadImpl
_$$UyavaGraphFilterSearchPayloadImplFromJson(Map<String, dynamic> json) =>
    _$UyavaGraphFilterSearchPayloadImpl(
      mode: $enumDecode(_$UyavaFilterSearchModeEnumMap, json['mode']),
      pattern: json['pattern'] as String,
      caseSensitive: json['caseSensitive'] as bool? ?? false,
      flags: json['flags'] as String?,
    );

Map<String, dynamic> _$$UyavaGraphFilterSearchPayloadImplToJson(
  _$UyavaGraphFilterSearchPayloadImpl instance,
) => <String, dynamic>{
  'mode': _$UyavaFilterSearchModeEnumMap[instance.mode]!,
  'pattern': instance.pattern,
  'caseSensitive': instance.caseSensitive,
  'flags': instance.flags,
};

const _$UyavaFilterSearchModeEnumMap = {
  UyavaFilterSearchMode.substring: 'substring',
  UyavaFilterSearchMode.mask: 'mask',
  UyavaFilterSearchMode.regex: 'regex',
};

_$UyavaGraphFilterTagsPayloadImpl _$$UyavaGraphFilterTagsPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaGraphFilterTagsPayloadImpl(
  mode: $enumDecode(_$UyavaFilterTagsModeEnumMap, json['mode']),
  values:
      (json['values'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  valuesNormalized:
      (json['valuesNormalized'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  logic:
      $enumDecodeNullable(_$UyavaFilterTagLogicEnumMap, json['logic']) ??
      UyavaFilterTagLogic.any,
);

Map<String, dynamic> _$$UyavaGraphFilterTagsPayloadImplToJson(
  _$UyavaGraphFilterTagsPayloadImpl instance,
) => <String, dynamic>{
  'mode': _$UyavaFilterTagsModeEnumMap[instance.mode]!,
  'values': instance.values,
  'valuesNormalized': instance.valuesNormalized,
  'logic': _$UyavaFilterTagLogicEnumMap[instance.logic]!,
};

const _$UyavaFilterTagsModeEnumMap = {
  UyavaFilterTagsMode.include: 'include',
  UyavaFilterTagsMode.exclude: 'exclude',
  UyavaFilterTagsMode.exact: 'exact',
};

const _$UyavaFilterTagLogicEnumMap = {
  UyavaFilterTagLogic.any: 'any',
  UyavaFilterTagLogic.all: 'all',
};

_$UyavaGraphFilterIdSetPayloadImpl _$$UyavaGraphFilterIdSetPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UyavaGraphFilterIdSetPayloadImpl(
  include:
      (json['include'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  exclude:
      (json['exclude'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$$UyavaGraphFilterIdSetPayloadImplToJson(
  _$UyavaGraphFilterIdSetPayloadImpl instance,
) => <String, dynamic>{
  'include': instance.include,
  'exclude': instance.exclude,
};

_$UyavaGraphFilterParentPayloadImpl
_$$UyavaGraphFilterParentPayloadImplFromJson(Map<String, dynamic> json) =>
    _$UyavaGraphFilterParentPayloadImpl(
      rootId: json['rootId'] as String?,
      depth: (json['depth'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$UyavaGraphFilterParentPayloadImplToJson(
  _$UyavaGraphFilterParentPayloadImpl instance,
) => <String, dynamic>{'rootId': instance.rootId, 'depth': instance.depth};

_$UyavaGraphFilterGroupingPayloadImpl
_$$UyavaGraphFilterGroupingPayloadImplFromJson(Map<String, dynamic> json) =>
    _$UyavaGraphFilterGroupingPayloadImpl(
      mode: $enumDecode(_$UyavaFilterGroupingModeEnumMap, json['mode']),
      levelDepth: (json['levelDepth'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$UyavaGraphFilterGroupingPayloadImplToJson(
  _$UyavaGraphFilterGroupingPayloadImpl instance,
) => <String, dynamic>{
  'mode': _$UyavaFilterGroupingModeEnumMap[instance.mode]!,
  'levelDepth': instance.levelDepth,
};

const _$UyavaFilterGroupingModeEnumMap = {
  UyavaFilterGroupingMode.none: 'none',
  UyavaFilterGroupingMode.level: 'level',
};

_$UyavaGraphFilterSeverityPayloadImpl
_$$UyavaGraphFilterSeverityPayloadImplFromJson(Map<String, dynamic> json) =>
    _$UyavaGraphFilterSeverityPayloadImpl(
      operator: $enumDecode(
        _$UyavaFilterSeverityOperatorEnumMap,
        json['operator'],
      ),
      level: $enumDecode(_$UyavaSeverityEnumMap, json['level']),
    );

Map<String, dynamic> _$$UyavaGraphFilterSeverityPayloadImplToJson(
  _$UyavaGraphFilterSeverityPayloadImpl instance,
) => <String, dynamic>{
  'operator': _$UyavaFilterSeverityOperatorEnumMap[instance.operator]!,
  'level': _$UyavaSeverityEnumMap[instance.level]!,
};

const _$UyavaFilterSeverityOperatorEnumMap = {
  UyavaFilterSeverityOperator.atLeast: 'atLeast',
  UyavaFilterSeverityOperator.atMost: 'atMost',
  UyavaFilterSeverityOperator.exact: 'exact',
};

const _$UyavaSeverityEnumMap = {
  UyavaSeverity.trace: 'trace',
  UyavaSeverity.debug: 'debug',
  UyavaSeverity.info: 'info',
  UyavaSeverity.warn: 'warn',
  UyavaSeverity.error: 'error',
  UyavaSeverity.fatal: 'fatal',
};
