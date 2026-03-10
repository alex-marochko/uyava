import 'dart:async';

import 'package:collection/collection.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import './layout/layout.dart';
import './layout/layout_config.dart';
import './layout/layout_engine.dart';
import './models/graph_event_chains.dart';
import './models/graph_filters.dart';
import './models/graph_metrics.dart';
import './models/uyava_edge.dart';
import './models/uyava_node.dart';
import './models/node_lifecycle.dart';
import './math/vector2.dart';
import './math/size2d.dart';
import './models/graph_diagnostics_buffer.dart';
import './models/graph_integrity.dart';
import './services/graph_diagnostics_service.dart';
import './services/graph_event_chain_service.dart';
import './services/graph_filter_service.dart';
import './services/graph_metrics_service.dart';

/// The central class for managing the state of the Uyava graph.
///
/// This controller handles the graph's data (nodes and edges) and
/// orchestrates the layout engine to calculate node positions.
class GraphController {
  List<UyavaNode> nodes = [];
  List<UyavaEdge> edges = [];
  final LayoutEngine _engine;
  bool _initialized = false;
  final GraphDiagnosticsService _diagnostics;
  late final GraphFilterService _filtersService;
  late final GraphEventChainService _eventChainsService;
  late final GraphMetricsService _metricsService;
  final ListEquality<String> _stringListEquality = const ListEquality<String>();

  /// The calculated positions of the nodes, keyed by node ID.
  Map<String, Vector2> positions = {};

  bool get isInitialized => _initialized;
  bool get isConverged => _engine.isConverged;
  GraphDiagnosticsBuffer get diagnostics => _diagnostics.diagnostics;
  GraphIntegrity get integrity => _diagnostics.integrity;
  Stream<List<GraphDiagnosticRecord>> get diagnosticsStream =>
      _diagnostics.stream;
  List<GraphMetricSnapshot> get metrics => _metricsService.snapshots;
  Stream<List<GraphMetricSnapshot>> get metricsStream => _metricsService.stream;
  GraphMetricSnapshot? metricFor(String metricId) =>
      _metricsService.snapshotFor(metricId);
  List<GraphEventChainSnapshot> get eventChains =>
      _eventChainsService.snapshots;
  Stream<List<GraphEventChainSnapshot>> get eventChainsStream =>
      _eventChainsService.stream;
  GraphEventChainSnapshot? eventChainFor(String chainId) =>
      _eventChainsService.snapshotFor(chainId);
  GraphFilterState get filters => _filtersService.state;
  GraphFilterResult get filterResult => _filtersService.result;
  Stream<GraphFilterResult> get filtersStream => _filtersService.stream;
  List<UyavaNode> get filteredNodes => _filtersService.result.visibleNodes;
  List<UyavaEdge> get filteredEdges => _filtersService.result.visibleEdges;
  List<GraphMetricSnapshot> get filteredMetrics =>
      _filtersService.result.visibleMetrics;
  List<GraphEventChainSnapshot> get filteredEventChains =>
      _filtersService.result.visibleEventChains;
  Set<String> get autoCollapsedParents =>
      _filtersService.result.autoCollapsedParents;

  GraphController({
    LayoutEngine? engine,
    LayoutConfig? layoutConfig,
    GraphDiagnosticsBuffer? diagnostics,
    GraphDiagnosticsService? diagnosticsService,
    GraphFilterService? filterService,
    GraphEventChainService? eventChainService,
    GraphMetricsService? metricsService,
  }) : _engine = engine ?? ForceDirectedLayout(config: layoutConfig),
       _diagnostics =
           diagnosticsService ??
           GraphDiagnosticsService(diagnostics: diagnostics) {
    _filtersService =
        filterService ?? GraphFilterService(diagnosticsService: _diagnostics);
    _eventChainsService =
        eventChainService ??
        GraphEventChainService(diagnosticsService: _diagnostics);
    _metricsService =
        metricsService ?? GraphMetricsService(diagnosticsService: _diagnostics);
  }

  /// Replaces the entire graph and initializes the layout engine.
  ///
  /// If [initialPositions] is provided, the layout engine will seed existing
  /// node positions from it to preserve continuity during incremental updates.
  void replaceGraph(
    Map<String, dynamic> graphData,
    Size2D size, {
    Map<String, Vector2>? initialPositions,
  }) {
    final Map<String, UyavaNode> previousNodes = <String, UyavaNode>{
      for (final node in nodes) node.id: node,
    };
    integrity.clear();
    final _SanitizedGraphData sanitized = _sanitizeGraphData(graphData);

    final List<UyavaNode> nextNodes = <UyavaNode>[];
    for (final payload in sanitized.nodes) {
      final node = UyavaNode.fromPayload(payload);
      final UyavaNode? previous = previousNodes[node.id];
      if (previous != null) {
        _recordStyleConflicts(previous, node);
      }
      nextNodes.add(node);
    }
    nodes = nextNodes;
    edges = sanitized.edges.map(UyavaEdge.fromPayload).toList(growable: false);

    _diagnostics.publishIntegrity();

    _engine.initialize(
      nodes: nodes,
      edges: edges,
      size: size,
      initialPositions: initialPositions,
    );
    positions = Map.of(_engine.positions);
    _initialized = true;
    _rebuildFilters();
  }

  /// Advances the physics simulation by one step.
  void step() {
    if (!_initialized || _engine.isConverged) return;
    _engine.step();
    positions = Map.of(_engine.positions);
  }

  /// Update lifecycle for a node by id. No-op if node not found.
  /// Allows transitions from any state; last-writer-wins.
  void updateNodeLifecycle(String nodeId, NodeLifecycle state) {
    final idx = nodes.indexWhere((n) => n.id == nodeId);
    if (idx == -1) return;
    final current = nodes[idx];
    if (current.lifecycle == state) return;
    nodes[idx] = current.copyWithLifecycle(state);
    _rebuildFilters();
  }

  /// Updates lifecycle state for multiple nodes at once. Unknown ids are ignored.
  void updateNodesListLifecycle(List<String> nodeIds, NodeLifecycle state) {
    if (nodeIds.isEmpty || nodes.isEmpty) return;
    final Set<String> uniqueIds = <String>{...nodeIds};
    final Map<String, int> indexById = <String, int>{
      for (var i = 0; i < nodes.length; i++) nodes[i].id: i,
    };
    bool changed = false;
    for (final id in uniqueIds) {
      final idx = indexById[id];
      if (idx == null) continue;
      final current = nodes[idx];
      if (current.lifecycle == state) continue;
      nodes[idx] = current.copyWithLifecycle(state);
      changed = true;
    }
    if (changed) {
      _rebuildFilters();
    }
  }

  /// Updates lifecycle state for a node and all of its descendants.
  ///
  /// Descendants are determined via the `parentId` field on each node. Unknown
  /// [rootNodeId] values are ignored. When [includeRoot] is `false`, only the
  /// descendants are updated while the root node keeps its current state.
  void updateSubtreeLifecycle(
    String rootNodeId,
    NodeLifecycle state, {
    bool includeRoot = true,
  }) {
    if (nodes.isEmpty) return;

    final Map<String, int> indexById = <String, int>{
      for (var i = 0; i < nodes.length; i++) nodes[i].id: i,
    };
    if (!indexById.containsKey(rootNodeId)) return;

    final Map<String, List<String>> childrenByParent = <String, List<String>>{};
    for (final node in nodes) {
      final String? parentId = node.parentId;
      if (parentId == null) continue;
      childrenByParent.putIfAbsent(parentId, () => <String>[]).add(node.id);
    }

    final Set<String> visited = <String>{rootNodeId};
    final List<String> stack = <String>[rootNodeId];
    final List<String> targetIds = <String>[];

    if (includeRoot) {
      targetIds.add(rootNodeId);
    }

    while (stack.isNotEmpty) {
      final String current = stack.removeLast();
      final List<String>? children = childrenByParent[current];
      if (children == null) continue;
      for (final childId in children) {
        if (!visited.add(childId)) continue;
        targetIds.add(childId);
        stack.add(childId);
      }
    }

    if (targetIds.isEmpty) return;
    updateNodesListLifecycle(targetIds, state);
  }

  /// Returns the node matching [nodeId], or null if absent.
  UyavaNode? nodeForId(String nodeId) {
    return nodes.firstWhereOrNull((node) => node.id == nodeId);
  }

  /// Returns the current lifecycle state of the node with [nodeId], if present.
  NodeLifecycle? lifecycleForNode(String nodeId) {
    return nodeForId(nodeId)?.lifecycle;
  }

  void dispose() {
    _diagnostics.dispose();
    _filtersService.dispose();
    _eventChainsService.dispose();
    _metricsService.dispose();
  }

  /// Clears all recorded diagnostics (both core and app-sourced).
  void clearDiagnostics() {
    _diagnostics.clearDiagnostics();
  }

  GraphFilterUpdateResult updateFiltersCommand(
    Map<String, dynamic> rawCommand,
  ) {
    return _filtersService.updateFromCommand(
      rawCommand,
      _currentFilterContext(),
    );
  }

  GraphFilterUpdateResult updateFilters(GraphFilterState next) {
    return _filtersService.update(next, _currentFilterContext());
  }

  GraphMetricRegistrationResult registerMetricDefinition(
    Map<String, dynamic> rawDefinition,
  ) {
    final GraphMetricRegistrationResult registration = _metricsService
        .registerDefinition(rawDefinition);
    if (registration.updated) {
      _rebuildFilters();
    }

    return registration;
  }

  GraphMetricSampleResult recordMetricSample(
    Map<String, dynamic> rawSample, {
    DateTime? fallbackTimestamp,
    UyavaSeverity? severity,
  }) {
    final GraphMetricSampleResult applied = _metricsService.recordSample(
      rawSample,
      fallbackTimestamp: fallbackTimestamp,
      severity: severity,
    );

    if (applied.applied) {
      _rebuildFilters();
    }

    return applied;
  }

  bool resetMetricAggregates(String metricId) {
    final bool reset = _metricsService.resetAggregates(metricId);
    if (reset) {
      _rebuildFilters();
    }
    return reset;
  }

  void resetAllMetricAggregates() {
    _metricsService.resetAllAggregates();
    _rebuildFilters();
  }

  void clearMetricDefinitions() {
    if (_metricsService.clearDefinitions()) {
      _rebuildFilters();
    }
  }

  GraphEventChainRegistrationResult registerEventChainDefinition(
    Map<String, dynamic> rawDefinition,
  ) {
    final GraphEventChainRegistrationResult registration = _eventChainsService
        .registerDefinition(rawDefinition);
    if (registration.updated) {
      _rebuildFilters();
    }
    return registration;
  }

  GraphEventChainProgressResult recordEventChainProgress({
    required String nodeId,
    required Map<String, dynamic> chain,
    String? edgeId,
    UyavaSeverity? severity,
    DateTime? timestamp,
  }) {
    final GraphEventChainProgressResult recorded = _eventChainsService
        .recordProgress(
          nodeId: nodeId,
          chain: chain,
          edgeId: edgeId,
          severity: severity,
          timestamp: timestamp,
        );
    if (recorded.applied) {
      _rebuildFilters();
    }
    return recorded;
  }

  bool resetEventChain(String chainId) {
    final bool reset = _eventChainsService.reset(chainId);
    if (reset) {
      _rebuildFilters();
    }
    return reset;
  }

  void resetAllEventChains() {
    if (_eventChainsService.resetAll()) {
      _rebuildFilters();
    }
  }

  void clearEventChainDefinitions() {
    if (_eventChainsService.clearDefinitions()) {
      _rebuildFilters();
    }
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
    _diagnostics.addAppDiagnostic(
      code: code,
      level: level,
      subjects: subjects,
      context: context,
      codeEnum: codeEnum,
      timestamp: timestamp,
      sourceId: sourceId,
      sourceType: sourceType,
    );
  }

  void addAppDiagnosticPayload(
    UyavaGraphDiagnosticPayload payload, {
    DateTime? timestamp,
    String? sourceId,
    String? sourceType,
  }) {
    _diagnostics.addAppDiagnosticPayload(
      payload,
      timestamp: timestamp,
      sourceId: sourceId,
      sourceType: sourceType,
    );
  }

  _SanitizedGraphData _sanitizeGraphData(Map<String, dynamic> graphData) {
    final List<_NodeCandidate> nodeCandidates = <_NodeCandidate>[];
    final List<dynamic> rawNodes = graphData['nodes'] is List
        ? List<dynamic>.from(graphData['nodes'] as List)
        : const <dynamic>[];
    for (var index = 0; index < rawNodes.length; index++) {
      final dynamic entry = rawNodes[index];
      if (entry is! Map) {
        integrity.add(
          code: UyavaGraphIntegrityCode.nodesMissingId,
          context: <String, Object?>{
            'index': index,
            'reason': 'invalid_payload',
          },
          level: UyavaGraphIntegrityCode.nodesMissingId.defaultLevel,
        );
        continue;
      }
      final Map<String, dynamic> mutable = Map<String, dynamic>.from(entry);
      try {
        final UyavaNodeSanitizationResult result =
            UyavaGraphNodePayload.sanitize(mutable);
        for (final diagnostic in result.diagnostics) {
          integrity.addPayload(diagnostic);
        }
        final UyavaGraphNodePayload? payload = result.payload;
        if (!result.isValid || payload == null) {
          continue;
        }
        nodeCandidates.add(_NodeCandidate(payload: payload, index: index));
      } on ArgumentError {
        // Missing id or other fatal issue already recorded via diagnostics.
        continue;
      }
    }

    final UyavaDeduplicationResult<_NodeCandidate> nodeDedup =
        dedupeById<_NodeCandidate>(
          nodeCandidates,
          (candidate) => candidate.payload.id,
        );
    if (nodeDedup.hasDuplicates) {
      for (final UyavaDuplicateRecord duplicate in nodeDedup.duplicates) {
        integrity.add(
          code: UyavaGraphIntegrityCode.nodesDuplicateId,
          nodeId: duplicate.id,
          context: <String, Object?>{
            'previousIndex': duplicate.previousIndex,
            'nextIndex': duplicate.nextIndex,
          },
          level: UyavaGraphIntegrityCode.nodesDuplicateId.defaultLevel,
        );
      }
    }

    final List<UyavaGraphNodePayload> nodePayloads = nodeDedup.latestById.values
        .map((entry) => entry.value.payload)
        .toList(growable: false);
    nodePayloads.sort((a, b) => a.id.compareTo(b.id));
    final List<UyavaGraphNodePayload> sortedNodes =
        List<UyavaGraphNodePayload>.unmodifiable(nodePayloads);
    final Set<String> nodeIds = nodeDedup.latestById.keys.toSet();

    final List<_EdgeCandidate> edgeCandidates = <_EdgeCandidate>[];
    final List<dynamic> rawEdges = graphData['edges'] is List
        ? List<dynamic>.from(graphData['edges'] as List)
        : const <dynamic>[];
    for (var index = 0; index < rawEdges.length; index++) {
      final dynamic entry = rawEdges[index];
      if (entry is! Map) {
        integrity.add(
          code: UyavaGraphIntegrityCode.edgesMissingId,
          context: <String, Object?>{
            'index': index,
            'reason': 'invalid_payload',
          },
          level: UyavaGraphIntegrityCode.edgesMissingId.defaultLevel,
        );
        continue;
      }
      final Map<String, dynamic> mutable = Map<String, dynamic>.from(entry);
      try {
        final UyavaEdgeSanitizationResult result =
            UyavaGraphEdgePayload.sanitize(mutable);
        for (final diagnostic in result.diagnostics) {
          integrity.addPayload(diagnostic);
        }
        final UyavaGraphEdgePayload? payload = result.payload;
        if (!result.isValid || payload == null) {
          continue;
        }
        edgeCandidates.add(_EdgeCandidate(payload: payload, index: index));
      } on ArgumentError {
        // Missing id/source/target already recorded via diagnostics.
        continue;
      }
    }

    final UyavaDeduplicationResult<_EdgeCandidate> edgeDedup =
        dedupeById<_EdgeCandidate>(
          edgeCandidates,
          (candidate) => candidate.payload.id,
        );
    if (edgeDedup.hasDuplicates) {
      for (final UyavaDuplicateRecord duplicate in edgeDedup.duplicates) {
        integrity.add(
          code: UyavaGraphIntegrityCode.edgesDuplicateId,
          edgeId: duplicate.id,
          context: <String, Object?>{
            'previousIndex': duplicate.previousIndex,
            'nextIndex': duplicate.nextIndex,
          },
          level: UyavaGraphIntegrityCode.edgesDuplicateId.defaultLevel,
        );
      }
    }

    final List<UyavaGraphEdgePayload> edgePayloads = <UyavaGraphEdgePayload>[];
    edgeDedup.latestById.forEach((id, entry) {
      final UyavaGraphEdgePayload payload = entry.value.payload;
      if (!nodeIds.contains(payload.source)) {
        integrity.add(
          code: UyavaGraphIntegrityCode.edgesDanglingSource,
          edgeId: id,
          context: <String, Object?>{'source': payload.source},
          level: UyavaGraphIntegrityCode.edgesDanglingSource.defaultLevel,
        );
        return;
      }
      if (!nodeIds.contains(payload.target)) {
        integrity.add(
          code: UyavaGraphIntegrityCode.edgesDanglingTarget,
          edgeId: id,
          context: <String, Object?>{'target': payload.target},
          level: UyavaGraphIntegrityCode.edgesDanglingTarget.defaultLevel,
        );
        return;
      }
      if (payload.source == payload.target) {
        integrity.add(
          code: UyavaGraphIntegrityCode.edgesSelfLoop,
          edgeId: id,
          context: <String, Object?>{'nodeId': payload.source},
          level: UyavaGraphIntegrityCode.edgesSelfLoop.defaultLevel,
        );
        return;
      }
      edgePayloads.add(payload);
    });

    edgePayloads.sort((a, b) => a.id.compareTo(b.id));
    final List<UyavaGraphEdgePayload> sortedEdges =
        List<UyavaGraphEdgePayload>.unmodifiable(edgePayloads);

    return _SanitizedGraphData(nodes: sortedNodes, edges: sortedEdges);
  }

  void _recordStyleConflicts(UyavaNode previous, UyavaNode next) {
    final String? prevColor = previous.payload.color;
    final String? nextColor = next.payload.color;
    if (prevColor != null && nextColor != null && prevColor != nextColor) {
      integrity.add(
        code: UyavaGraphIntegrityCode.nodesConflictingColor,
        nodeId: next.id,
        context: <String, Object?>{'previous': prevColor, 'next': nextColor},
      );
    }

    final List<String> prevTags = previous.payload.tags;
    final List<String> nextTags = next.payload.tags;
    final bool hasPrevTags = prevTags.isNotEmpty;
    final bool hasNextTags = nextTags.isNotEmpty;
    if (hasPrevTags &&
        hasNextTags &&
        !_stringListEquality.equals(prevTags, nextTags)) {
      integrity.add(
        code: UyavaGraphIntegrityCode.nodesConflictingTags,
        nodeId: next.id,
        context: <String, Object?>{
          'previous': List<String>.unmodifiable(prevTags),
          'next': List<String>.unmodifiable(nextTags),
        },
      );
    }
  }

  GraphFilterContext _currentFilterContext() {
    return GraphFilterContext(
      nodes: nodes,
      edges: edges,
      metrics: _metricsService.snapshots,
      eventChains: _eventChainsService.snapshots,
    );
  }

  void _rebuildFilters() {
    _filtersService.rebuild(_currentFilterContext());
  }
}

class _SanitizedGraphData {
  const _SanitizedGraphData({required this.nodes, required this.edges});

  final List<UyavaGraphNodePayload> nodes;
  final List<UyavaGraphEdgePayload> edges;
}

class _NodeCandidate {
  const _NodeCandidate({required this.payload, required this.index});

  final UyavaGraphNodePayload payload;
  final int index;
}

class _EdgeCandidate {
  const _EdgeCandidate({required this.payload, required this.index});

  final UyavaGraphEdgePayload payload;
  final int index;
}
