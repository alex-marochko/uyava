// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../graph_integrity_codes.dart';
import '../base_types.dart';
import '../../data_policies.dart';
import '../../normalization.dart';

import 'graph_diagnostic_payload.dart';

part 'event_chain_definition_payload.freezed.dart';
part 'event_chain_definition_payload.g.dart';

/// Canonical payload representing an event-chain definition.
@Freezed(toJson: true)
class UyavaEventChainDefinitionPayload with _$UyavaEventChainDefinitionPayload {
  const UyavaEventChainDefinitionPayload._();

  const factory UyavaEventChainDefinitionPayload({
    required String id,
    @Default(<String>[]) List<String> tags,
    @JsonKey(name: 'tagsNormalized')
    @Default(<String>[])
    List<String> tagsNormalized,
    @JsonKey(name: 'tagsCatalog') List<String>? tagsCatalog,
    @Deprecated('Use tags instead') String? tag,
    String? label,
    String? description,
    @Default(<UyavaEventChainStepPayload>[])
    List<UyavaEventChainStepPayload> steps,
  }) = _UyavaEventChainDefinitionPayload;

  factory UyavaEventChainDefinitionPayload.fromJson(
    Map<String, dynamic> json,
  ) => _$UyavaEventChainDefinitionPayloadFromJson(json);

  /// Normalizes raw chain definition maps, collecting diagnostics.
  static UyavaEventChainDefinitionSanitizationResult sanitize(
    Map<String, dynamic> raw,
  ) {
    final Map<String, dynamic> working = Map<String, dynamic>.from(raw);
    final List<UyavaGraphDiagnosticPayload> diagnostics =
        <UyavaGraphDiagnosticPayload>[];

    final String? id = _trimmedOrNull(working['id']);
    if (id == null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.chainsMissingId.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.chainsMissingId,
          level: UyavaGraphIntegrityCode.chainsMissingId.defaultLevel,
          context: <String, Object?>{'rawId': working['id']},
        ),
      );
      return UyavaEventChainDefinitionSanitizationResult(
        payload: null,
        diagnostics: diagnostics,
        isValid: false,
      );
    }

    final Object? rawTagsInput = working.containsKey('tags')
        ? working['tags']
        : working['tag'];
    if (!working.containsKey('tags')) {
      final String? legacyTag = _trimmedOrNull(working['tag']);
      if (legacyTag != null) {
        working['tags'] = <String>[legacyTag];
      }
    }

    final UyavaTagNormalizationResult tagData = normalizeTags(working['tags']);
    if (!tagData.hasValues) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.chainsMissingTag.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.chainsMissingTag,
          level: UyavaGraphIntegrityCode.chainsMissingTag.defaultLevel,
          context: <String, Object?>{'rawTags': rawTagsInput},
        ),
      );
      return UyavaEventChainDefinitionSanitizationResult(
        payload: null,
        diagnostics: diagnostics,
        isValid: false,
      );
    }

    final String label = _resolveLabel(working['label'], fallback: id);
    working
      ..['id'] = id
      ..['label'] = label
      ..['tags'] = tagData.values
      ..['tagsNormalized'] = tagData.normalized;

    final List<String> catalogMatches = UyavaDataPolicies.catalogMatches(
      tagData.values,
    );
    if (catalogMatches.isNotEmpty) {
      working['tagsCatalog'] = catalogMatches;
    } else {
      working.remove('tagsCatalog');
    }

    // Preserve legacy `tag` field for backwards compatibility.
    working['tag'] = tagData.values.first;

    final _StepParseResult stepResult = _parseSteps(working['steps']);
    diagnostics.addAll(stepResult.diagnostics);
    working['steps'] = stepResult.steps.map((step) => step.toJson()).toList();

    final UyavaEventChainDefinitionPayload payload =
        UyavaEventChainDefinitionPayload.fromJson(working);

    return UyavaEventChainDefinitionSanitizationResult(
      payload: payload,
      diagnostics: diagnostics,
      isValid:
          stepResult.steps.isNotEmpty &&
          diagnostics.every((d) {
            return d.codeEnum != UyavaGraphIntegrityCode.chainsInvalidStep;
          }),
    );
  }
}

/// Canonical step entry for event-chain definitions.
@Freezed(toJson: true)
class UyavaEventChainStepPayload with _$UyavaEventChainStepPayload {
  const UyavaEventChainStepPayload._();

  const factory UyavaEventChainStepPayload({
    required String stepId,
    required String nodeId,
    String? edgeId,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    UyavaSeverity? expectedSeverity,
  }) = _UyavaEventChainStepPayload;

  factory UyavaEventChainStepPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaEventChainStepPayloadFromJson(json);
}

class UyavaEventChainDefinitionSanitizationResult {
  const UyavaEventChainDefinitionSanitizationResult({
    required this.payload,
    required this.diagnostics,
    required this.isValid,
  });

  final UyavaEventChainDefinitionPayload? payload;
  final List<UyavaGraphDiagnosticPayload> diagnostics;
  final bool isValid;
}

class _StepParseResult {
  const _StepParseResult({required this.steps, required this.diagnostics});

  final List<UyavaEventChainStepPayload> steps;
  final List<UyavaGraphDiagnosticPayload> diagnostics;
}

_StepParseResult _parseSteps(Object? raw) {
  final List<UyavaEventChainStepPayload> steps = <UyavaEventChainStepPayload>[];
  final List<UyavaGraphDiagnosticPayload> diagnostics =
      <UyavaGraphDiagnosticPayload>[];

  if (raw is! Iterable) {
    if (raw != null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.chainsInvalidStep.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.chainsInvalidStep,
          level: UyavaGraphIntegrityCode.chainsInvalidStep.defaultLevel,
          context: <String, Object?>{'rawSteps': raw},
        ),
      );
    }
    return _StepParseResult(
      steps: const <UyavaEventChainStepPayload>[],
      diagnostics: diagnostics,
    );
  }

  final Set<String> seenStepIds = <String>{};
  bool hasDuplicateIds = false;

  for (final Object? entry in raw) {
    if (entry is! Map) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.chainsInvalidStep.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.chainsInvalidStep,
          level: UyavaGraphIntegrityCode.chainsInvalidStep.defaultLevel,
          context: <String, Object?>{'rawStep': entry},
        ),
      );
      continue;
    }

    final Map<String, dynamic> stepMap = Map<String, dynamic>.from(entry);
    final String? stepId = _trimmedOrNull(stepMap['stepId']);
    final String? nodeId = _trimmedOrNull(stepMap['nodeId']);
    if (stepId == null || nodeId == null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.chainsInvalidStep.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.chainsInvalidStep,
          level: UyavaGraphIntegrityCode.chainsInvalidStep.defaultLevel,
          context: <String, Object?>{'step': entry},
        ),
      );
      continue;
    }

    if (!seenStepIds.add(stepId)) {
      hasDuplicateIds = true;
      continue;
    }

    final String? edgeId = _trimmedOrNull(stepMap['edgeId']);
    final UyavaSeverity? expectedSeverity = _severityFromJson(
      _trimmedOrNull(stepMap['expectedSeverity']),
    );

    steps.add(
      UyavaEventChainStepPayload(
        stepId: stepId,
        nodeId: nodeId,
        edgeId: edgeId,
        expectedSeverity: expectedSeverity,
      ),
    );
  }

  if (hasDuplicateIds) {
    diagnostics.add(
      UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.chainsConflictingStep.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.chainsConflictingStep,
        level: UyavaGraphIntegrityCode.chainsConflictingStep.defaultLevel,
      ),
    );
  }

  if (steps.isEmpty) {
    diagnostics.add(
      UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.chainsInvalidStep.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.chainsInvalidStep,
        level: UyavaGraphIntegrityCode.chainsInvalidStep.defaultLevel,
      ),
    );
  }

  return _StepParseResult(
    steps: List<UyavaEventChainStepPayload>.unmodifiable(steps),
    diagnostics: diagnostics,
  );
}

String? _trimmedOrNull(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

String _resolveLabel(Object? raw, {required String fallback}) {
  final String? value = _trimmedOrNull(raw);
  return value ?? fallback;
}

UyavaSeverity? _severityFromJson(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final candidate in UyavaSeverity.values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  return null;
}

String? _severityToJson(UyavaSeverity? value) => value?.name;
