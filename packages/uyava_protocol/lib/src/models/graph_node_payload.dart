// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../base_types.dart';
import '../../graph_integrity_codes.dart';
import '../../normalization.dart';
import '../../data_policies.dart';

import 'graph_diagnostic_payload.dart';

part 'graph_node_payload.freezed.dart';
part 'graph_node_payload.g.dart';

/// Canonical wire-format payload for graph nodes.
@Freezed(toJson: true)
class UyavaGraphNodePayload with _$UyavaGraphNodePayload {
  const UyavaGraphNodePayload._();

  const factory UyavaGraphNodePayload({
    required String id,
    @Default('unknown') String type,
    required String label,
    String? description,
    String? parentId,
    @Default(<String>[]) List<String> tags,
    @JsonKey(name: 'tagsNormalized')
    @Default(<String>[])
    List<String> tagsNormalized,
    @JsonKey(name: 'tagsCatalog') List<String>? tagsCatalog,
    String? color,
    @JsonKey(name: 'colorPriorityIndex') int? colorPriorityIndex,
    String? shape,
    @JsonKey(fromJson: _lifecycleFromJson, toJson: _lifecycleToJson)
    @Default(UyavaLifecycleState.unknown)
    UyavaLifecycleState lifecycle,
    @JsonKey(name: UyavaPayloadKeys.initSource) String? initSource,
  }) = _UyavaGraphNodePayload;

  factory UyavaGraphNodePayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphNodePayloadFromJson(json);

  /// Returns an immutable map representing the sanitized payload.
  Map<String, Object?> asMap() {
    final Map<String, Object?> json = Map<String, Object?>.from(toJson());
    json.removeWhere((key, value) => value == null);
    return Map<String, Object?>.unmodifiable(json);
  }

  /// Normalizes raw node maps emitted by SDK/hosts and records diagnostics.
  static UyavaNodeSanitizationResult sanitize(Map<String, dynamic> raw) {
    final Map<String, dynamic> working = Map<String, dynamic>.from(raw);
    final List<UyavaGraphDiagnosticPayload> diagnostics =
        <UyavaGraphDiagnosticPayload>[];

    final Object? rawId = working['id'];
    final String? id = rawId is String && rawId.isNotEmpty ? rawId : null;
    if (id == null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.nodesMissingId.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.nodesMissingId,
          level: UyavaGraphIntegrityCode.nodesMissingId.defaultLevel,
          context: <String, Object?>{'rawId': rawId},
        ),
      );
      return UyavaNodeSanitizationResult(
        payload: null,
        diagnostics: diagnostics,
        isValid: false,
      );
    }

    final String type = (working['type'] as String?)?.trim().isNotEmpty == true
        ? (working['type'] as String).trim()
        : 'unknown';

    final String label = _resolveLabel(working['label'], fallback: id);
    working
      ..['id'] = id
      ..['type'] = type
      ..['label'] = label;

    final UyavaTagNormalizationResult tagData = normalizeTags(working['tags']);
    if (tagData.hasValues) {
      working['tags'] = tagData.values;
      working['tagsNormalized'] = tagData.normalized;
      final List<String> catalogMatches = UyavaDataPolicies.catalogMatches(
        tagData.values,
      );
      if (catalogMatches.isNotEmpty) {
        working['tagsCatalog'] = catalogMatches;
      } else {
        working.remove('tagsCatalog');
      }
    } else {
      working.remove('tags');
      working.remove('tagsNormalized');
      working.remove('tagsCatalog');
    }

    final UyavaColorNormalizationResult color = normalizeColor(
      working['color'],
    );
    if (color.value != null) {
      working['color'] = color.value;
      final int? priorityIndex = UyavaDataPolicies.priorityColorIndex(
        color.value,
      );
      if (priorityIndex != null) {
        working['colorPriorityIndex'] = priorityIndex;
      } else {
        working.remove('colorPriorityIndex');
      }
    } else {
      if (color.shouldReportInvalid) {
        diagnostics.add(
          UyavaGraphDiagnosticPayload(
            code: UyavaGraphIntegrityCode.nodesInvalidColor.toWireString(),
            codeEnum: UyavaGraphIntegrityCode.nodesInvalidColor,
            level: UyavaGraphIntegrityCode.nodesInvalidColor.defaultLevel,
            nodeId: id,
            context: <String, Object?>{'value': color.original},
          ),
        );
      }
      working.remove('color');
      working.remove('colorPriorityIndex');
    }

    final UyavaShapeNormalizationResult shape = normalizeShape(
      working['shape'],
    );
    if (shape.value != null) {
      working['shape'] = shape.value;
    } else {
      if (shape.shouldReportInvalid) {
        diagnostics.add(
          UyavaGraphDiagnosticPayload(
            code: UyavaGraphIntegrityCode.nodesInvalidShape.toWireString(),
            codeEnum: UyavaGraphIntegrityCode.nodesInvalidShape,
            level: UyavaGraphIntegrityCode.nodesInvalidShape.defaultLevel,
            nodeId: id,
            context: <String, Object?>{'value': shape.original},
          ),
        );
      }
      working.remove('shape');
    }

    working['lifecycle'] = _lifecycleToJson(
      _lifecycleFromJson(working['lifecycle'] as String?),
    );

    final UyavaGraphNodePayload payload = UyavaGraphNodePayload.fromJson(
      working,
    );

    return UyavaNodeSanitizationResult(
      payload: payload,
      diagnostics: diagnostics,
      isValid: true,
    );
  }
}

String _lifecycleToJson(UyavaLifecycleState value) => value.name;

UyavaLifecycleState _lifecycleFromJson(String? value) {
  if (value == null || value.isEmpty) return UyavaLifecycleState.unknown;
  for (final candidate in UyavaLifecycleState.values) {
    if (candidate.name == value) return candidate;
  }
  return UyavaLifecycleState.unknown;
}

String _resolveLabel(Object? raw, {required String fallback}) {
  final String? value = (raw is String) ? raw.trim() : null;
  if (value == null || value.isEmpty) {
    return fallback;
  }
  return value;
}

/// Bundles the sanitized payload with diagnostics raised during canonicalization.
class UyavaNodeSanitizationResult {
  const UyavaNodeSanitizationResult({
    required this.payload,
    required this.diagnostics,
    required this.isValid,
  });

  final UyavaGraphNodePayload? payload;
  final List<UyavaGraphDiagnosticPayload> diagnostics;
  final bool isValid;
}
