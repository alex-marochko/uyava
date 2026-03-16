import 'dart:async';

import 'package:uyava_protocol/uyava_protocol.dart';

import '../models/graph_event_chains.dart';
import 'graph_diagnostics_service.dart';
import 'payload_parsing.dart';

class GraphEventChainService {
  GraphEventChainService({
    GraphEventChainStore? store,
    GraphDiagnosticsService? diagnosticsService,
    StreamController<List<GraphEventChainSnapshot>>? controller,
  }) : _store = store ?? GraphEventChainStore(),
       _diagnostics = diagnosticsService ?? GraphDiagnosticsService(),
       _controller =
           controller ??
           StreamController<List<GraphEventChainSnapshot>>.broadcast();

  final GraphEventChainStore _store;
  final GraphDiagnosticsService _diagnostics;
  final StreamController<List<GraphEventChainSnapshot>> _controller;
  List<GraphEventChainSnapshot> _snapshots = const <GraphEventChainSnapshot>[];

  List<GraphEventChainSnapshot> get snapshots =>
      List<GraphEventChainSnapshot>.unmodifiable(_snapshots);
  Stream<List<GraphEventChainSnapshot>> get stream => _controller.stream;

  GraphEventChainRegistrationResult registerDefinition(
    Map<String, dynamic> rawDefinition,
  ) {
    final UyavaEventChainDefinitionSanitizationResult result =
        UyavaEventChainDefinitionPayload.sanitize(rawDefinition);

    bool hasDiagnostics = result.diagnostics.isNotEmpty;
    _diagnostics.recordPayloadDiagnostics(result.diagnostics);

    final UyavaEventChainDefinitionPayload? payload = result.payload;
    if (!result.isValid || payload == null) {
      if (hasDiagnostics) {
        _diagnostics.publishIntegrity();
        _diagnostics.logPayloadAnomaly(
          code: 'core.event_chains.rejected_definition',
          context: <String, Object?>{
            'definitionId': rawDefinition['id'],
            'hasSteps': rawDefinition['steps'] is List,
            'diagnostics': result.diagnostics
                .map((diag) => diag.codeEnum?.toWireString() ?? diag.code)
                .toList(growable: false),
          },
        );
      }
      return const GraphEventChainRegistrationResult(
        snapshot: null,
        updated: false,
        diagnostics: <GraphEventChainDiagnostic>[],
      );
    }

    final GraphEventChainRegistrationResult registration = _store.register(
      payload,
    );
    if (registration.updated) {
      _emit();
    }

    if (registration.diagnostics.isNotEmpty) {
      hasDiagnostics = true;
      _diagnostics.recordEventChainDiagnostics(registration.diagnostics);
    }

    if (hasDiagnostics) {
      _diagnostics.publishIntegrity();
    }

    return registration;
  }

  GraphEventChainProgressResult recordProgress({
    required String nodeId,
    required Map<String, dynamic> chain,
    String? edgeId,
    UyavaSeverity? severity,
    DateTime? timestamp,
  }) {
    final DateTime eventTimestamp = (timestamp ?? DateTime.now()).toUtc();
    final _ParsedChainPayload parsed = _parseChainPayload(chain);
    bool hasDiagnostics = parsed.diagnostics.isNotEmpty;

    if (parsed.diagnostics.isNotEmpty) {
      _diagnostics.recordEventChainDiagnostics(parsed.diagnostics);
    }

    if (!parsed.isValid) {
      if (hasDiagnostics) {
        _diagnostics.publishIntegrity();
      }
      return GraphEventChainProgressResult(
        snapshot: parsed.chainId != null
            ? _store.snapshotFor(parsed.chainId!)
            : null,
        status: GraphEventChainProgressStatus.ignored,
        diagnostics: parsed.diagnostics,
        attemptId: parsed.attemptId,
      );
    }

    final GraphEventChainEvent event = GraphEventChainEvent(
      chainId: parsed.chainId!,
      stepId: parsed.stepId!,
      nodeId: nodeId,
      edgeId: edgeId,
      attemptId: parsed.attemptId,
      severity: severity,
      timestamp: eventTimestamp,
      isFailure: parsed.isFailure,
    );
    final GraphEventChainProgressResult recorded = _store.record(event);

    if (recorded.diagnostics.isNotEmpty) {
      hasDiagnostics = true;
      _diagnostics.recordEventChainDiagnostics(recorded.diagnostics);
    }

    if (recorded.applied) {
      _emit();
    }

    if (hasDiagnostics) {
      _diagnostics.publishIntegrity();
    }

    if (parsed.diagnostics.isEmpty) {
      return recorded;
    }

    final List<GraphEventChainDiagnostic> combinedDiagnostics =
        <GraphEventChainDiagnostic>[
          ...parsed.diagnostics,
          ...recorded.diagnostics,
        ];

    return GraphEventChainProgressResult(
      snapshot: recorded.snapshot,
      status: recorded.status,
      diagnostics: combinedDiagnostics,
      attemptId: recorded.attemptId ?? parsed.attemptId,
    );
  }

  bool reset(String chainId) {
    final bool reset = _store.reset(chainId);
    if (reset) {
      _emit();
    }
    return reset;
  }

  bool resetAll() {
    final bool reset = _store.resetAll();
    if (reset) {
      _emit();
    }
    return reset;
  }

  bool clearDefinitions() {
    final bool cleared = _store.clear();
    if (cleared) {
      _emit();
    }
    return cleared;
  }

  GraphEventChainSnapshot? snapshotFor(String chainId) {
    return _store.snapshotFor(chainId);
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  void _emit() {
    _snapshots = List<GraphEventChainSnapshot>.unmodifiable(
      _store.allSnapshots(),
    );
    if (_controller.isClosed) return;
    _controller.add(_snapshots);
  }

  _ParsedChainPayload _parseChainPayload(Map<String, dynamic> chain) {
    final List<GraphEventChainDiagnostic> diagnostics =
        <GraphEventChainDiagnostic>[];
    final String? chainId = trimmedString(chain['id']);
    final String? stepId = trimmedString(chain['step']);
    final String? attemptId = trimmedString(chain['attempt']);
    final String? status = trimmedString(chain['status']);
    final String? statusNormalized = status?.toLowerCase();
    final bool isFailure =
        statusNormalized == 'failed' || statusNormalized == 'failure';

    if (chainId == null) {
      diagnostics.add(
        GraphEventChainDiagnostic(
          code: UyavaGraphIntegrityCode.chainsMissingId,
          context: <String, Object?>{'chain': chain},
        ),
      );
    }

    if (stepId == null) {
      diagnostics.add(
        GraphEventChainDiagnostic(
          code: UyavaGraphIntegrityCode.chainsUnknownStep,
          context: <String, Object?>{'chainId': chainId, 'chain': chain},
        ),
      );
    }

    return _ParsedChainPayload(
      chainId: chainId,
      stepId: stepId,
      attemptId: attemptId,
      isFailure: isFailure,
      diagnostics: diagnostics,
    );
  }
}

class _ParsedChainPayload {
  const _ParsedChainPayload({
    required this.chainId,
    required this.stepId,
    required this.attemptId,
    required this.isFailure,
    required this.diagnostics,
  });

  final String? chainId;
  final String? stepId;
  final String? attemptId;
  final bool isFailure;
  final List<GraphEventChainDiagnostic> diagnostics;

  bool get isValid => chainId != null && stepId != null;
}
