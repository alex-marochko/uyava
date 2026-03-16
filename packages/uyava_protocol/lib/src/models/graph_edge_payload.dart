// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../graph_integrity_codes.dart';

import 'graph_diagnostic_payload.dart';

part 'graph_edge_payload.freezed.dart';
part 'graph_edge_payload.g.dart';

/// Canonical wire-format payload for graph edges.
@Freezed(toJson: true)
class UyavaGraphEdgePayload with _$UyavaGraphEdgePayload {
  const UyavaGraphEdgePayload._();

  const factory UyavaGraphEdgePayload({
    required String id,
    @JsonKey(name: 'source') required String source,
    @JsonKey(name: 'target') required String target,
    String? label,
    String? description,
    @Default(false) bool remapped,
    @Default(false) bool bidirectional,
  }) = _UyavaGraphEdgePayload;

  factory UyavaGraphEdgePayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphEdgePayloadFromJson(json);

  static UyavaEdgeSanitizationResult sanitize(Map<String, dynamic> raw) {
    final Map<String, dynamic> working = Map<String, dynamic>.from(raw);
    final List<UyavaGraphDiagnosticPayload> diagnostics =
        <UyavaGraphDiagnosticPayload>[];

    final Object? rawId = working['id'];
    final String? id = rawId is String && rawId.isNotEmpty ? rawId : null;
    if (id == null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.edgesMissingId.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.edgesMissingId,
          level: UyavaGraphIntegrityCode.edgesMissingId.defaultLevel,
          context: <String, Object?>{'rawId': rawId},
        ),
      );
      return UyavaEdgeSanitizationResult(
        payload: null,
        diagnostics: diagnostics,
        isValid: false,
      );
    }

    final Object? rawSource = working['source'];
    final String? source = rawSource is String && rawSource.isNotEmpty
        ? rawSource
        : null;
    if (source == null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.edgesMissingSource.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.edgesMissingSource,
          level: UyavaGraphIntegrityCode.edgesMissingSource.defaultLevel,
          edgeId: id,
          context: <String, Object?>{'rawSource': rawSource},
        ),
      );
      return UyavaEdgeSanitizationResult(
        payload: null,
        diagnostics: diagnostics,
        isValid: false,
      );
    }

    final Object? rawTarget = working['target'];
    final String? target = rawTarget is String && rawTarget.isNotEmpty
        ? rawTarget
        : null;
    if (target == null) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.edgesMissingTarget.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.edgesMissingTarget,
          level: UyavaGraphIntegrityCode.edgesMissingTarget.defaultLevel,
          edgeId: id,
          context: <String, Object?>{'rawTarget': rawTarget},
        ),
      );
      return UyavaEdgeSanitizationResult(
        payload: null,
        diagnostics: diagnostics,
        isValid: false,
      );
    }

    working
      ..['id'] = id
      ..['source'] = source
      ..['target'] = target
      ..['remapped'] = working['remapped'] == true
      ..['bidirectional'] = working['bidirectional'] == true;

    final UyavaGraphEdgePayload payload = UyavaGraphEdgePayload.fromJson(
      working,
    );

    return UyavaEdgeSanitizationResult(
      payload: payload,
      diagnostics: diagnostics,
      isValid: true,
    );
  }
}

class UyavaEdgeSanitizationResult {
  const UyavaEdgeSanitizationResult({
    required this.payload,
    required this.diagnostics,
    required this.isValid,
  });

  final UyavaGraphEdgePayload? payload;
  final List<UyavaGraphDiagnosticPayload> diagnostics;
  final bool isValid;
}
