import 'dart:async';

import 'package:uyava_protocol/uyava_protocol.dart';

import '../models/graph_event_chains.dart';
import '../models/graph_filters.dart';
import '../models/graph_metrics.dart';
import '../models/uyava_edge.dart';
import '../models/uyava_node.dart';
import 'graph_diagnostics_service.dart';

class GraphFilterContext {
  const GraphFilterContext({
    required this.nodes,
    required this.edges,
    required this.metrics,
    required this.eventChains,
  });

  final List<UyavaNode> nodes;
  final List<UyavaEdge> edges;
  final List<GraphMetricSnapshot> metrics;
  final List<GraphEventChainSnapshot> eventChains;
}

/// Manages filter state and diagnostics independently from the controller.
class GraphFilterService {
  GraphFilterService({
    GraphFilterState initialState = GraphFilterState.empty,
    GraphDiagnosticsService? diagnosticsService,
    StreamController<GraphFilterResult>? controller,
  }) : _state = initialState,
       _result = GraphFilterResult.initial(),
       _diagnostics = diagnosticsService ?? GraphDiagnosticsService(),
       _controller =
           controller ?? StreamController<GraphFilterResult>.broadcast();

  final GraphDiagnosticsService _diagnostics;
  final StreamController<GraphFilterResult> _controller;
  GraphFilterState _state;
  GraphFilterResult _result;

  GraphFilterState get state => _state;
  GraphFilterResult get result => _result;
  Stream<GraphFilterResult> get stream => _controller.stream;

  GraphFilterUpdateResult updateFromCommand(
    Map<String, dynamic> rawCommand,
    GraphFilterContext context,
  ) {
    final UyavaGraphFilterSanitizationResult result =
        UyavaGraphFilterCommandPayload.sanitize(rawCommand);

    _diagnostics.recordPayloadDiagnostics(result.diagnostics);

    if (!result.isValid) {
      if (result.diagnostics.isNotEmpty) {
        _diagnostics.publishIntegrity();
        _diagnostics.logPayloadAnomaly(
          code: 'core.filters.rejected_payload',
          context: <String, Object?>{
            'diagnostics': result.diagnostics
                .map((diag) => diag.codeEnum?.toWireString() ?? diag.code)
                .toList(growable: false),
          },
        );
      }
      return GraphFilterUpdateResult(
        state: _state,
        applied: false,
        diagnostics: const <GraphFilterDiagnostic>[],
        payloadDiagnostics: List<UyavaGraphDiagnosticPayload>.unmodifiable(
          result.diagnostics,
        ),
      );
    }

    final GraphFilterState nextState = GraphFilterState.fromPayload(
      result.payload,
    );
    return _finishUpdate(
      context: context,
      nextState: nextState,
      payloadDiagnostics: result.diagnostics,
    );
  }

  GraphFilterUpdateResult update(
    GraphFilterState next,
    GraphFilterContext context,
  ) {
    return _finishUpdate(
      context: context,
      nextState: next,
      payloadDiagnostics: const <UyavaGraphDiagnosticPayload>[],
    );
  }

  void rebuild(GraphFilterContext context) {
    _applyFilters(context);
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  GraphFilterUpdateResult _finishUpdate({
    required GraphFilterContext context,
    required GraphFilterState nextState,
    required List<UyavaGraphDiagnosticPayload> payloadDiagnostics,
  }) {
    final List<GraphFilterDiagnostic> filterDiagnostics =
        <GraphFilterDiagnostic>[];

    if (context.nodes.isNotEmpty && nextState.nodes != null) {
      final Iterable<String> unknownIds = nextState.nodes!.unknownIds(
        context.nodes.map((node) => node.id),
      );
      for (final String id in unknownIds) {
        final GraphFilterDiagnostic diagnostic = GraphFilterDiagnostic(
          code: UyavaGraphIntegrityCode.filtersUnknownNode,
          context: <String, Object?>{'nodeId': id},
        );
        filterDiagnostics.add(diagnostic);
      }
      _diagnostics.recordFilterDiagnostics(filterDiagnostics);
    }

    final bool changed = nextState != _state;
    if (changed) {
      _state = nextState;
      _applyFilters(context);
    }
    if (payloadDiagnostics.isNotEmpty || filterDiagnostics.isNotEmpty) {
      _diagnostics.publishIntegrity();
    }

    return GraphFilterUpdateResult(
      state: _state,
      applied: changed,
      diagnostics: List<GraphFilterDiagnostic>.unmodifiable(filterDiagnostics),
      payloadDiagnostics: List<UyavaGraphDiagnosticPayload>.unmodifiable(
        payloadDiagnostics,
      ),
    );
  }

  void _applyFilters(GraphFilterContext context) {
    _result = GraphFilterEngine.apply(
      state: _state,
      nodes: context.nodes,
      edges: context.edges,
      metrics: context.metrics,
      eventChains: context.eventChains,
    );
    if (_controller.isClosed) return;
    _controller.add(_result);
  }
}
