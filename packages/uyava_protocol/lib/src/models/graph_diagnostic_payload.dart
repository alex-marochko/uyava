// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../graph_diagnostic_level.dart';
import '../../graph_integrity_codes.dart';

part 'graph_diagnostic_payload.freezed.dart';
part 'graph_diagnostic_payload.g.dart';

/// Canonical payload for diagnostics exchanged between SDK, core, and hosts.
@Freezed(toJson: true)
class UyavaGraphDiagnosticPayload with _$UyavaGraphDiagnosticPayload {
  const UyavaGraphDiagnosticPayload._();

  const factory UyavaGraphDiagnosticPayload({
    required String code,
    @JsonKey(fromJson: _integrityCodeFromJson, toJson: _integrityCodeToJson)
    UyavaGraphIntegrityCode? codeEnum,
    @JsonKey(fromJson: _diagnosticLevelFromJson, toJson: _diagnosticLevelToJson)
    required UyavaDiagnosticLevel level,
    String? nodeId,
    String? edgeId,
    Map<String, Object?>? context,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? timestamp,
  }) = _UyavaGraphDiagnosticPayload;

  factory UyavaGraphDiagnosticPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphDiagnosticPayloadFromJson(json);

  /// Convenience subjects list derived from node/edge identifiers.
  List<String> get subjects {
    final List<String> values = <String>[];
    if (nodeId != null && nodeId!.isNotEmpty) {
      values.add(nodeId!);
    }
    if (edgeId != null && edgeId!.isNotEmpty) {
      values.add(edgeId!);
    }
    return List<String>.unmodifiable(values);
  }
}

UyavaGraphIntegrityCode? _integrityCodeFromJson(String? value) {
  if (value == null || value.isEmpty) return null;
  final UyavaGraphIntegrityCode? fromWire =
      UyavaGraphIntegrityCode.fromWireString(value);
  if (fromWire != null) {
    return fromWire;
  }
  for (final candidate in UyavaGraphIntegrityCode.values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  return null;
}

String? _integrityCodeToJson(UyavaGraphIntegrityCode? code) => code?.name;

UyavaDiagnosticLevel _diagnosticLevelFromJson(String? value) {
  return uyavaDiagnosticLevelFromWire(value) ?? UyavaDiagnosticLevel.warning;
}

String _diagnosticLevelToJson(UyavaDiagnosticLevel level) =>
    level.toWireString();

DateTime? _dateTimeFromJson(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.parse(value).toUtc();
}

String? _dateTimeToJson(DateTime? value) => value?.toUtc().toIso8601String();
