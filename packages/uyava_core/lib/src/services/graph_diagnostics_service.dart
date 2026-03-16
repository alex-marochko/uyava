import 'dart:async';

import 'package:uyava_protocol/uyava_protocol.dart';

import '../models/graph_diagnostics_buffer.dart';
import '../models/graph_filters.dart';
import '../models/graph_integrity.dart';
import '../models/graph_event_chains.dart';

/// Coordinates integrity tracking and diagnostic emissions.
class GraphDiagnosticsService {
  GraphDiagnosticsService({
    GraphIntegrity? integrity,
    GraphDiagnosticsBuffer? diagnostics,
    StreamController<List<GraphDiagnosticRecord>>? controller,
    DateTime Function()? clock,
  }) : integrity = integrity ?? GraphIntegrity(),
       diagnostics = diagnostics ?? GraphDiagnosticsBuffer(clock: clock),
       _controller =
           controller ??
           StreamController<List<GraphDiagnosticRecord>>.broadcast();

  final StreamController<List<GraphDiagnosticRecord>> _controller;

  /// Aggregated integrity state.
  final GraphIntegrity integrity;

  /// Stored diagnostics for both core and app sources.
  final GraphDiagnosticsBuffer diagnostics;

  Stream<List<GraphDiagnosticRecord>> get stream => _controller.stream;

  /// Records protocol payload diagnostics into integrity.
  void recordPayloadDiagnostics(
    Iterable<UyavaGraphDiagnosticPayload> payloadDiagnostics,
  ) {
    for (final UyavaGraphDiagnosticPayload diagnostic in payloadDiagnostics) {
      integrity.addPayload(diagnostic);
    }
  }

  /// Records filter-related diagnostics into integrity.
  void recordFilterDiagnostics(
    Iterable<GraphFilterDiagnostic> filterDiagnostics,
  ) {
    for (final GraphFilterDiagnostic diagnostic in filterDiagnostics) {
      integrity.add(code: diagnostic.code, context: diagnostic.context);
    }
  }

  /// Records event chain diagnostics into integrity.
  void recordEventChainDiagnostics(
    Iterable<GraphEventChainDiagnostic> chainDiagnostics,
  ) {
    for (final GraphEventChainDiagnostic diagnostic in chainDiagnostics) {
      integrity.add(code: diagnostic.code, context: diagnostic.context);
    }
  }

  /// Emits an app-level diagnostic to flag suspicious payloads.
  void logPayloadAnomaly({
    required String code,
    Map<String, Object?>? context,
    Iterable<String>? subjects,
    UyavaDiagnosticLevel level = UyavaDiagnosticLevel.warning,
    String? sourceId,
    String? sourceType,
  }) {
    diagnostics.addAppDiagnostic(
      code: code,
      level: level,
      subjects: subjects,
      context: context,
      sourceId: sourceId,
      sourceType: sourceType,
    );
    _emit();
  }

  /// Copies integrity issues to the buffer and emits them downstream.
  void publishIntegrity() {
    diagnostics.replaceCoreIssues(integrity.issues);
    _emit();
  }

  void clearDiagnostics() {
    diagnostics.clear();
    _emit();
  }

  void addAppDiagnostic({
    required String code,
    required UyavaDiagnosticLevel level,
    Iterable<String>? subjects,
    Map<String, Object?>? context,
    UyavaGraphIntegrityCode? codeEnum,
    DateTime? timestamp,
    String? sourceId,
    String? sourceType,
  }) {
    diagnostics.addAppDiagnostic(
      code: code,
      level: level,
      subjects: subjects ?? const <String>[],
      context: context,
      codeEnum: codeEnum,
      timestamp: timestamp,
      sourceId: sourceId,
      sourceType: sourceType,
    );
    _emit();
  }

  void addAppDiagnosticPayload(
    UyavaGraphDiagnosticPayload payload, {
    DateTime? timestamp,
    String? sourceId,
    String? sourceType,
  }) {
    diagnostics.addAppDiagnosticPayload(
      payload,
      timestamp: timestamp,
      sourceId: sourceId,
      sourceType: sourceType,
    );
    _emit();
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(diagnostics.records);
  }
}
