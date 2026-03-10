import 'dart:async';

import 'package:uyava_protocol/uyava_protocol.dart';

import '../models/graph_metrics.dart';
import 'graph_diagnostics_service.dart';
import 'payload_parsing.dart';

/// Manages metric definitions, aggregates, and diagnostics independently from
/// the controller.
class GraphMetricsService {
  GraphMetricsService({
    GraphMetricsStore? store,
    GraphDiagnosticsService? diagnosticsService,
    StreamController<List<GraphMetricSnapshot>>? controller,
    DateTime Function()? clock,
  }) : _store = store ?? GraphMetricsStore(),
       _diagnostics = diagnosticsService ?? GraphDiagnosticsService(),
       _controller =
           controller ??
           StreamController<List<GraphMetricSnapshot>>.broadcast(),
       _clock = clock ?? DateTime.now;

  final GraphMetricsStore _store;
  final GraphDiagnosticsService _diagnostics;
  final StreamController<List<GraphMetricSnapshot>> _controller;
  final DateTime Function() _clock;

  List<GraphMetricSnapshot> _snapshots = const <GraphMetricSnapshot>[];

  List<GraphMetricSnapshot> get snapshots =>
      List<GraphMetricSnapshot>.unmodifiable(_snapshots);
  Stream<List<GraphMetricSnapshot>> get stream => _controller.stream;

  GraphMetricSnapshot? snapshotFor(String metricId) =>
      _store.snapshotFor(metricId);

  Iterable<String> get metricIds => _store.metricIds;

  GraphMetricRegistrationResult registerDefinition(
    Map<String, dynamic> rawDefinition,
  ) {
    final UyavaMetricDefinitionSanitizationResult result =
        UyavaMetricDefinitionPayload.sanitize(rawDefinition);

    bool hasDiagnostics = result.diagnostics.isNotEmpty;
    _diagnostics.recordPayloadDiagnostics(result.diagnostics);

    final UyavaMetricDefinitionPayload? payload = result.payload;
    if (!result.isValid || payload == null) {
      if (hasDiagnostics) {
        _diagnostics.publishIntegrity();
      }
      return const GraphMetricRegistrationResult(
        snapshot: null,
        updated: false,
        diagnostics: <GraphMetricDiagnostic>[],
      );
    }

    final GraphMetricRegistrationResult registration = _store.register(payload);
    if (registration.updated) {
      _emit();
    }

    if (registration.diagnostics.isNotEmpty) {
      hasDiagnostics = true;
      for (final GraphMetricDiagnostic diagnostic in registration.diagnostics) {
        _diagnostics.integrity.add(
          code: diagnostic.code,
          context: diagnostic.context,
        );
      }
    }

    if (hasDiagnostics) {
      _diagnostics.publishIntegrity();
    }

    return registration;
  }

  GraphMetricSampleResult recordSample(
    Map<String, dynamic> rawSample, {
    DateTime? fallbackTimestamp,
    UyavaSeverity? severity,
  }) {
    final UyavaSeverity? parsedSeverity =
        severity ?? parseSeverity(rawSample['severity']);
    final UyavaMetricSampleSanitizationResult result =
        UyavaMetricSamplePayload.sanitize(rawSample);

    bool hasDiagnostics = result.diagnostics.isNotEmpty;
    _diagnostics.recordPayloadDiagnostics(result.diagnostics);

    final UyavaMetricSamplePayload? payload = result.payload;
    if (!result.isValid || payload == null) {
      if (hasDiagnostics) {
        _diagnostics.publishIntegrity();
      }
      return const GraphMetricSampleResult(
        snapshot: null,
        applied: false,
        diagnostics: <GraphMetricDiagnostic>[],
      );
    }

    final DateTime timestamp =
        (payload.timestamp ?? fallbackTimestamp ?? _clock()).toUtc();
    final GraphMetricSampleResult applied = _store.applySample(
      payload,
      timestamp: timestamp,
      severity: parsedSeverity,
    );

    if (applied.diagnostics.isNotEmpty) {
      hasDiagnostics = true;
      for (final GraphMetricDiagnostic diagnostic in applied.diagnostics) {
        _diagnostics.integrity.add(
          code: diagnostic.code,
          context: diagnostic.context,
        );
      }
    }

    if (applied.applied) {
      _emit();
    }

    if (hasDiagnostics) {
      _diagnostics.publishIntegrity();
    }

    return applied;
  }

  bool resetAggregates(String metricId) {
    final bool reset = _store.reset(metricId);
    if (reset) {
      _emit();
    }
    return reset;
  }

  void resetAllAggregates() {
    if (_store.resetAll()) {
      _emit();
    }
  }

  bool clearDefinitions() {
    final bool cleared = _store.clear();
    if (cleared) {
      _emit();
    }
    return cleared;
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  void _emit() {
    _snapshots = List<GraphMetricSnapshot>.unmodifiable(_store.allSnapshots());
    if (_controller.isClosed) return;
    _controller.add(_snapshots);
  }
}
