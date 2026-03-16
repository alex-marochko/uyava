import 'package:uyava_protocol/uyava_protocol.dart';

import 'graph_event_chains.dart';
import 'graph_filter_state.dart';
import 'graph_metrics.dart';
import 'uyava_edge.dart';
import 'uyava_node.dart';

/// Computed view after applying filters.
class GraphFilterResult {
  GraphFilterResult({
    required this.state,
    required List<UyavaNode> visibleNodes,
    required Set<String> visibleNodeIds,
    required Set<String> hiddenNodeIds,
    required Set<String> hiddenByDepthNodeIds,
    required Set<String> autoCollapsedParents,
    required List<UyavaEdge> visibleEdges,
    required Set<String> visibleEdgeIds,
    required List<GraphMetricSnapshot> visibleMetrics,
    required List<GraphEventChainSnapshot> visibleEventChains,
  }) : visibleNodes = List<UyavaNode>.unmodifiable(visibleNodes),
       visibleNodeIds = Set<String>.unmodifiable(visibleNodeIds),
       hiddenNodeIds = Set<String>.unmodifiable(hiddenNodeIds),
       hiddenByDepthNodeIds = Set<String>.unmodifiable(hiddenByDepthNodeIds),
       autoCollapsedParents = Set<String>.unmodifiable(autoCollapsedParents),
       visibleEdges = List<UyavaEdge>.unmodifiable(visibleEdges),
       visibleEdgeIds = Set<String>.unmodifiable(visibleEdgeIds),
       visibleMetrics = List<GraphMetricSnapshot>.unmodifiable(visibleMetrics),
       visibleEventChains = List<GraphEventChainSnapshot>.unmodifiable(
         visibleEventChains,
       );

  GraphFilterResult.initial()
    : state = GraphFilterState.empty,
      visibleNodes = const <UyavaNode>[],
      visibleNodeIds = const <String>{},
      hiddenNodeIds = const <String>{},
      hiddenByDepthNodeIds = const <String>{},
      autoCollapsedParents = const <String>{},
      visibleEdges = const <UyavaEdge>[],
      visibleEdgeIds = const <String>{},
      visibleMetrics = const <GraphMetricSnapshot>[],
      visibleEventChains = const <GraphEventChainSnapshot>[];

  /// Filters used to compute the result.
  final GraphFilterState state;

  /// Nodes that remain visible after applying filters.
  final List<UyavaNode> visibleNodes;

  /// Node ids that remain visible.
  final Set<String> visibleNodeIds;

  /// Node ids hidden by filters or grouping.
  final Set<String> hiddenNodeIds;

  /// Node ids hidden specifically due to depth/grouping limits.
  final Set<String> hiddenByDepthNodeIds;

  /// Parent ids that should be treated as auto-collapsed to surface hidden
  /// descendants.
  final Set<String> autoCollapsedParents;

  /// Edges with both endpoints visible.
  final List<UyavaEdge> visibleEdges;

  /// Identifiers of visible edges.
  final Set<String> visibleEdgeIds;

  /// Metric snapshots that pass the filter set.
  final List<GraphMetricSnapshot> visibleMetrics;

  /// Event chain snapshots that pass the filter set.
  final List<GraphEventChainSnapshot> visibleEventChains;
}

/// Diagnostic produced while applying filters (e.g. unknown ids).
class GraphFilterDiagnostic {
  const GraphFilterDiagnostic({required this.code, this.context});

  final UyavaGraphIntegrityCode code;
  final Map<String, Object?>? context;
}

/// Result of attempting to update the controller filters.
class GraphFilterUpdateResult {
  const GraphFilterUpdateResult({
    required this.state,
    required this.applied,
    required this.diagnostics,
    required this.payloadDiagnostics,
  });

  final GraphFilterState state;
  final bool applied;
  final List<GraphFilterDiagnostic> diagnostics;
  final List<UyavaGraphDiagnosticPayload> payloadDiagnostics;
}
