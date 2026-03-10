part of 'package:uyava/uyava.dart';

extension _UyavaGraphLoadOps on _UyavaRuntime {
  /// A convenience method to add multiple nodes and/or edges to the existing graph.
  void loadGraph({List<UyavaNode>? nodes, List<UyavaEdge>? edges}) {
    final init = _captureCallSite();
    List<Map<String, dynamic>>? nodeSnapshots;
    if (nodes != null) {
      nodeSnapshots = <Map<String, dynamic>>[];
      final List<_IndexedNode> indexedNodes = <_IndexedNode>[];
      for (var i = 0; i < nodes.length; i++) {
        indexedNodes.add(_IndexedNode(node: nodes[i], index: i));
      }
      final UyavaDeduplicationResult<_IndexedNode> nodeDedup =
          dedupeById<_IndexedNode>(indexedNodes, (entry) => entry.node.id);
      final Set<String> duplicateBatchNodeIds = nodeDedup.duplicates
          .map((duplicate) => duplicate.id)
          .toSet();
      final List<_IndexedNode> uniqueNodes =
          nodeDedup.latestById.values.map((entry) => entry.value).toList()
            ..sort((a, b) => a.index.compareTo(b.index));
      final Set<String> overwrittenNodeIds = <String>{};
      for (final _IndexedNode entry in uniqueNodes) {
        final UyavaNode node = entry.node;
        final UyavaNode? previous = graph.nodes[node.id];
        final Map<String, dynamic>? previousSnapshot = previous != null
            ? nodeSnapshot(previous)
            : null;
        final Map<String, dynamic> snapshot = nodeSnapshot(node);
        if (previousSnapshot != null) {
          _logNodeStyleConflicts(node.id, previousSnapshot, snapshot);
        }
        if (previous != null && overwrittenNodeIds.add(node.id)) {
          postDiagnostic(
            code: UyavaGraphIntegrityCode.nodesDuplicateId,
            level: UyavaDiagnosticLevel.warning,
            nodeId: node.id,
            context: const {'source': 'loadGraph_existing'},
          );
        }
        if (init != null) {
          snapshot['initSource'] = init;
        }
        nodeSnapshots.add(snapshot);
      }
      for (final String id in duplicateBatchNodeIds) {
        postDiagnostic(
          code: UyavaGraphIntegrityCode.nodesDuplicateId,
          level: UyavaDiagnosticLevel.warning,
          nodeId: id,
          context: const {'source': 'loadGraph_batch'},
        );
      }
      for (final _IndexedNode entry in uniqueNodes) {
        final UyavaNode node = entry.node;
        graph.nodes[node.id] = node;
        nodeLifecycleStates.putIfAbsent(node.id, () => defaultLifecycleState);
        if (init != null) {
          nodeInitSources[node.id] = init;
        }
      }
    }
    final Set<String> nodeIds = graph.nodes.keys.toSet();
    List<Map<String, dynamic>>? edgeSnapshots;
    if (edges != null) {
      edgeSnapshots = <Map<String, dynamic>>[];
      final List<_IndexedEdge> indexedEdges = <_IndexedEdge>[];
      for (var i = 0; i < edges.length; i++) {
        indexedEdges.add(_IndexedEdge(edge: edges[i], index: i));
      }
      final UyavaDeduplicationResult<_IndexedEdge> edgeDedup =
          dedupeById<_IndexedEdge>(indexedEdges, (entry) => entry.edge.id);
      final Set<String> duplicateBatchEdgeIds = edgeDedup.duplicates
          .map((duplicate) => duplicate.id)
          .toSet();
      final List<_IndexedEdge> uniqueEdges =
          edgeDedup.latestById.values.map((entry) => entry.value).toList()
            ..sort((a, b) => a.index.compareTo(b.index));
      final Set<String> overwrittenEdgeIds = <String>{};
      for (final _IndexedEdge entry in uniqueEdges) {
        final UyavaEdge edge = entry.edge;
        bool skip = false;
        if (!nodeIds.contains(edge.from)) {
          postDiagnostic(
            code: UyavaGraphIntegrityCode.edgesDanglingSource,
            level: UyavaDiagnosticLevel.error,
            edgeId: edge.id,
            context: {'source': edge.from, 'origin': 'loadGraph'},
          );
          skip = true;
        } else if (!nodeIds.contains(edge.to)) {
          postDiagnostic(
            code: UyavaGraphIntegrityCode.edgesDanglingTarget,
            level: UyavaDiagnosticLevel.error,
            edgeId: edge.id,
            context: {'target': edge.to, 'origin': 'loadGraph'},
          );
          skip = true;
        } else if (edge.from == edge.to) {
          postDiagnostic(
            code: UyavaGraphIntegrityCode.edgesSelfLoop,
            level: UyavaDiagnosticLevel.error,
            edgeId: edge.id,
            context: {'nodeId': edge.from, 'origin': 'loadGraph'},
          );
          skip = true;
        }
        if (skip) {
          continue;
        }
        if (graph.edges.containsKey(edge.id) &&
            overwrittenEdgeIds.add(edge.id)) {
          postDiagnostic(
            code: UyavaGraphIntegrityCode.edgesDuplicateId,
            level: UyavaDiagnosticLevel.warning,
            edgeId: edge.id,
            context: const {'source': 'loadGraph_existing'},
          );
        }
        graph.edges[edge.id] = edge;
        edgeSnapshots.add(edge.toJson());
      }
      for (final String id in duplicateBatchEdgeIds) {
        postDiagnostic(
          code: UyavaGraphIntegrityCode.edgesDuplicateId,
          level: UyavaDiagnosticLevel.warning,
          edgeId: id,
          context: const {'source': 'loadGraph_batch'},
        );
      }
    }
    final graphData = {
      if (nodeSnapshots != null) 'nodes': nodeSnapshots,
      if (edgeSnapshots != null) 'edges': edgeSnapshots,
    };
    if (init != null) {
      developer.log(
        'Uyava loadGraph: ${nodes?.length ?? 0} node(s) initialized @ $init',
        name: 'Uyava',
      );
    }
    postEvent(
      UyavaEventTypes.loadGraph,
      graphData,
      scope: UyavaTransportScope.snapshot,
    );
  }

  /// Clears the current graph in DevTools and loads a new one.
  void replaceGraph({List<UyavaNode>? nodes, List<UyavaEdge>? edges}) {
    // Clear the local state first.
    graph.nodes.clear();
    graph.edges.clear();
    nodeInitSources.clear();
    nodeLifecycleStates.clear();

    // Populate the local state with the new graph.
    final init = _captureCallSite();
    if (nodes != null) {
      final List<_IndexedNode> indexedNodes = <_IndexedNode>[];
      for (var i = 0; i < nodes.length; i++) {
        indexedNodes.add(_IndexedNode(node: nodes[i], index: i));
      }
      final UyavaDeduplicationResult<_IndexedNode> nodeDedup =
          dedupeById<_IndexedNode>(indexedNodes, (entry) => entry.node.id);
      final List<_IndexedNode> uniqueNodes =
          nodeDedup.latestById.values.map((entry) => entry.value).toList()
            ..sort((a, b) => a.index.compareTo(b.index));
      for (final _IndexedNode entry in uniqueNodes) {
        final UyavaNode node = entry.node;
        graph.nodes[node.id] = node;
        nodeLifecycleStates[node.id] = defaultLifecycleState;
        if (init != null) nodeInitSources[node.id] = init;
      }
      final Set<String> duplicateNodeIds = nodeDedup.duplicates
          .map((duplicate) => duplicate.id)
          .toSet();
      for (final String id in duplicateNodeIds) {
        postDiagnostic(
          code: UyavaGraphIntegrityCode.nodesDuplicateId,
          level: UyavaDiagnosticLevel.warning,
          nodeId: id,
          context: const {'source': 'replaceGraph_batch'},
        );
      }
    }
    final Set<String> nodeIds = graph.nodes.keys.toSet();
    List<Map<String, dynamic>>? edgePayload;
    if (edges != null) {
      final List<_IndexedEdge> indexedEdges = <_IndexedEdge>[];
      for (var i = 0; i < edges.length; i++) {
        indexedEdges.add(_IndexedEdge(edge: edges[i], index: i));
      }
      final UyavaDeduplicationResult<_IndexedEdge> edgeDedup =
          dedupeById<_IndexedEdge>(indexedEdges, (entry) => entry.edge.id);
      final List<_IndexedEdge> uniqueEdges =
          edgeDedup.latestById.values.map((entry) => entry.value).toList()
            ..sort((a, b) => a.index.compareTo(b.index));
      final List<UyavaEdge> acceptedEdges = <UyavaEdge>[];
      for (final _IndexedEdge entry in uniqueEdges) {
        final UyavaEdge edge = entry.edge;
        bool skip = false;
        if (!nodeIds.contains(edge.from)) {
          postDiagnostic(
            code: UyavaGraphIntegrityCode.edgesDanglingSource,
            level: UyavaDiagnosticLevel.error,
            edgeId: edge.id,
            context: {'source': edge.from, 'origin': 'replaceGraph'},
          );
          skip = true;
        } else if (!nodeIds.contains(edge.to)) {
          postDiagnostic(
            code: UyavaGraphIntegrityCode.edgesDanglingTarget,
            level: UyavaDiagnosticLevel.error,
            edgeId: edge.id,
            context: {'target': edge.to, 'origin': 'replaceGraph'},
          );
          skip = true;
        } else if (edge.from == edge.to) {
          postDiagnostic(
            code: UyavaGraphIntegrityCode.edgesSelfLoop,
            level: UyavaDiagnosticLevel.error,
            edgeId: edge.id,
            context: {'nodeId': edge.from, 'origin': 'replaceGraph'},
          );
          skip = true;
        }
        if (skip) {
          continue;
        }
        graph.edges[edge.id] = edge;
        acceptedEdges.add(edge);
      }
      final Set<String> duplicateEdgeIds = edgeDedup.duplicates
          .map((duplicate) => duplicate.id)
          .toSet();
      for (final String id in duplicateEdgeIds) {
        postDiagnostic(
          code: UyavaGraphIntegrityCode.edgesDuplicateId,
          level: UyavaDiagnosticLevel.warning,
          edgeId: id,
          context: const {'source': 'replaceGraph_batch'},
        );
      }
      edgePayload = acceptedEdges.map((e) => e.toJson()).toList();
    }

    // Post an event to tell the extension to replace its state.
    final graphData = {
      if (nodes != null)
        'nodes': nodes.map((n) {
          final snapshot = nodeSnapshot(n);
          if (init != null) snapshot['initSource'] = init;
          return snapshot;
        }).toList(),
      if (edgePayload != null) 'edges': edgePayload,
    };
    if (init != null) {
      developer.log(
        'Uyava replaceGraph: ${nodes?.length ?? 0} node(s) initialized @ $init',
        name: 'Uyava',
      );
    }
    postEvent(
      UyavaEventTypes.replaceGraph,
      graphData,
      scope: UyavaTransportScope.snapshot,
    );
  }
}
