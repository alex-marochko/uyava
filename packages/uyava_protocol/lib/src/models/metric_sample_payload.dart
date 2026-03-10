// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../graph_integrity_codes.dart';
import 'graph_diagnostic_payload.dart';

part 'metric_sample_payload.freezed.dart';
part 'metric_sample_payload.g.dart';

/// Canonical payload representing a single metric measurement.
@Freezed(toJson: true)
class UyavaMetricSamplePayload with _$UyavaMetricSamplePayload {
  const UyavaMetricSamplePayload._();

  const factory UyavaMetricSamplePayload({
    required String id,
    required double value,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? timestamp,
  }) = _UyavaMetricSamplePayload;

  factory UyavaMetricSamplePayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaMetricSamplePayloadFromJson(json);

  /// Normalizes raw measurement maps and returns sanitized payload + diagnostics.
  static UyavaMetricSampleSanitizationResult sanitize(
    Map<String, dynamic> raw,
  ) {
    final Map<String, dynamic> working = Map<String, dynamic>.from(raw);
    final List<UyavaGraphDiagnosticPayload> diagnostics =
        <UyavaGraphDiagnosticPayload>[];

    final String? id = _trimmedOrNull(working['id']);
    if (id == null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.metricsUnknownId.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.metricsUnknownId,
          level: UyavaGraphIntegrityCode.metricsUnknownId.defaultLevel,
          context: <String, Object?>{'rawId': working['id']},
        ),
      );
      return UyavaMetricSampleSanitizationResult(
        payload: null,
        diagnostics: diagnostics,
        isValid: false,
      );
    }

    final Object? rawValue = working['value'];
    double? value;
    if (rawValue is num) {
      value = rawValue.toDouble();
    } else if (rawValue is String) {
      final String trimmed = rawValue.trim();
      if (trimmed.isNotEmpty) {
        value = double.tryParse(trimmed);
      }
    }
    if (value == null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.metricsInvalidValue.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.metricsInvalidValue,
          level: UyavaGraphIntegrityCode.metricsInvalidValue.defaultLevel,
          context: <String, Object?>{'rawValue': rawValue},
        ),
      );
      return UyavaMetricSampleSanitizationResult(
        payload: null,
        diagnostics: diagnostics,
        isValid: false,
      );
    }

    DateTime? timestamp;
    final Object? rawTimestamp = working['timestamp'];
    if (rawTimestamp is String && rawTimestamp.trim().isNotEmpty) {
      timestamp = DateTime.tryParse(rawTimestamp)?.toUtc();
      if (timestamp == null) {
        diagnostics.add(
          UyavaGraphDiagnosticPayload(
            code: UyavaGraphIntegrityCode.metricsInvalidValue.toWireString(),
            codeEnum: UyavaGraphIntegrityCode.metricsInvalidValue,
            level: UyavaGraphIntegrityCode.metricsInvalidValue.defaultLevel,
            context: <String, Object?>{'rawTimestamp': rawTimestamp},
          ),
        );
      }
    }

    final UyavaMetricSamplePayload payload = UyavaMetricSamplePayload(
      id: id,
      value: value,
      timestamp: timestamp,
    );

    return UyavaMetricSampleSanitizationResult(
      payload: payload,
      diagnostics: diagnostics,
      isValid: diagnostics.isEmpty,
    );
  }
}

class UyavaMetricSampleSanitizationResult {
  const UyavaMetricSampleSanitizationResult({
    required this.payload,
    required this.diagnostics,
    required this.isValid,
  });

  final UyavaMetricSamplePayload? payload;
  final List<UyavaGraphDiagnosticPayload> diagnostics;
  final bool isValid;
}

String? _trimmedOrNull(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

DateTime? _dateTimeFromJson(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.parse(value).toUtc();
}

String? _dateTimeToJson(DateTime? value) => value?.toUtc().toIso8601String();
