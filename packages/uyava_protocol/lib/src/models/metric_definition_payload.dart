// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../graph_integrity_codes.dart';
import '../../normalization.dart';
import '../base_types.dart';

import 'graph_diagnostic_payload.dart';

part 'metric_definition_payload.freezed.dart';
part 'metric_definition_payload.g.dart';

/// Canonical payload for metric definitions (`defineMetric` events).
@Freezed(toJson: true)
class UyavaMetricDefinitionPayload with _$UyavaMetricDefinitionPayload {
  const UyavaMetricDefinitionPayload._();

  const factory UyavaMetricDefinitionPayload({
    required String id,
    String? label,
    String? description,
    String? unit,
    @Default(<String>[]) List<String> tags,
    @JsonKey(name: 'tagsNormalized')
    @Default(<String>[])
    List<String> tagsNormalized,
    @Default(<UyavaMetricAggregator>[UyavaMetricAggregator.last])
    List<UyavaMetricAggregator> aggregators,
  }) = _UyavaMetricDefinitionPayload;

  factory UyavaMetricDefinitionPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaMetricDefinitionPayloadFromJson(json);

  /// Returns an immutable map representing the payload without null entries.
  Map<String, Object?> asMap() {
    final Map<String, Object?> json = Map<String, Object?>.from(toJson());
    json.removeWhere((key, value) => value == null);
    return Map<String, Object?>.unmodifiable(json);
  }

  /// Normalizes raw metric definition maps and emits diagnostics when needed.
  static UyavaMetricDefinitionSanitizationResult sanitize(
    Map<String, dynamic> raw,
  ) {
    final Map<String, dynamic> working = Map<String, dynamic>.from(raw);
    final List<UyavaGraphDiagnosticPayload> diagnostics =
        <UyavaGraphDiagnosticPayload>[];

    final String? id = _trimmedOrNull(working['id']);
    if (id == null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.metricsMissingId.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.metricsMissingId,
          level: UyavaGraphIntegrityCode.metricsMissingId.defaultLevel,
          context: <String, Object?>{'rawId': working['id']},
        ),
      );
      return UyavaMetricDefinitionSanitizationResult(
        payload: null,
        diagnostics: diagnostics,
        isValid: false,
      );
    }

    final String label = _resolveLabel(working['label'], fallback: id);
    working
      ..['id'] = id
      ..['label'] = label;

    final UyavaTagNormalizationResult tagData = normalizeTags(working['tags']);
    if (tagData.hasValues) {
      working['tags'] = tagData.values;
      working['tagsNormalized'] = tagData.normalized;
    } else {
      working.remove('tags');
      if (tagData.hadInput) {
        working['tagsNormalized'] = <String>[];
      } else {
        working.remove('tagsNormalized');
      }
    }

    final _AggregatorParseResult aggregatorResult = _parseAggregators(
      working['aggregators'],
    );
    if (aggregatorResult.diagnostic != null) {
      diagnostics.add(aggregatorResult.diagnostic!);
    }
    working['aggregators'] = aggregatorResult.values
        .map((mode) => mode.name)
        .toList();

    final UyavaMetricDefinitionPayload payload =
        UyavaMetricDefinitionPayload.fromJson(working);

    return UyavaMetricDefinitionSanitizationResult(
      payload: payload,
      diagnostics: diagnostics,
      isValid: true,
    );
  }
}

class UyavaMetricDefinitionSanitizationResult {
  const UyavaMetricDefinitionSanitizationResult({
    required this.payload,
    required this.diagnostics,
    required this.isValid,
  });

  final UyavaMetricDefinitionPayload? payload;
  final List<UyavaGraphDiagnosticPayload> diagnostics;
  final bool isValid;
}

class _AggregatorParseResult {
  const _AggregatorParseResult({required this.values, this.diagnostic});

  final List<UyavaMetricAggregator> values;
  final UyavaGraphDiagnosticPayload? diagnostic;
}

_AggregatorParseResult _parseAggregators(Object? raw) {
  final List<UyavaMetricAggregator> aggregators = <UyavaMetricAggregator>[];
  UyavaGraphDiagnosticPayload? diagnostic;
  bool hadInput = false;

  if (raw is Iterable) {
    hadInput = true;
    final Set<UyavaMetricAggregator> seen = <UyavaMetricAggregator>{};
    for (final Object? entry in raw) {
      final String? text = _trimmedOrNull(entry);
      if (text == null) continue;
      final UyavaMetricAggregator? parsed =
          UyavaMetricAggregatorCodec.fromWireString(text);
      if (parsed != null && seen.add(parsed)) {
        aggregators.add(parsed);
      }
    }
    if (aggregators.isEmpty) {
      diagnostic = UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.metricsInvalidAggregator.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.metricsInvalidAggregator,
        level: UyavaGraphIntegrityCode.metricsInvalidAggregator.defaultLevel,
        context: <String, Object?>{'rawAggregators': List<Object?>.from(raw)},
      );
    }
  } else if (raw != null) {
    hadInput = true;
    diagnostic = UyavaGraphDiagnosticPayload(
      code: UyavaGraphIntegrityCode.metricsInvalidAggregator.toWireString(),
      codeEnum: UyavaGraphIntegrityCode.metricsInvalidAggregator,
      level: UyavaGraphIntegrityCode.metricsInvalidAggregator.defaultLevel,
      context: <String, Object?>{'rawAggregators': raw},
    );
  }

  if (aggregators.isEmpty) {
    aggregators.add(UyavaMetricAggregator.last);
    if (!hadInput) {
      // No input provided; treat default as intentional without diagnostics.
      diagnostic = null;
    } else if (diagnostic == null) {
      diagnostic = UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.metricsInvalidAggregator.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.metricsInvalidAggregator,
        level: UyavaGraphIntegrityCode.metricsInvalidAggregator.defaultLevel,
      );
    }
  }

  return _AggregatorParseResult(
    values: List<UyavaMetricAggregator>.unmodifiable(aggregators),
    diagnostic: diagnostic,
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
