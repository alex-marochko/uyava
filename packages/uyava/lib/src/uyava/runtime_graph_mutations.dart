part of 'package:uyava/uyava.dart';

extension _UyavaGraphMutations on _UyavaRuntime {
  /// Adds a single node to the graph.
  ///
  /// Optional [sourceRef] overrides auto-captured call-site (debug/profile only).
  void addNode(UyavaNode node, {String? sourceRef}) {
    final UyavaNode? previous = graph.nodes[node.id];
    final Map<String, dynamic>? previousSnapshot = previous != null
        ? nodeSnapshot(previous)
        : null;
    final Map<String, dynamic> nextSnapshot = nodeSnapshot(node);
    if (previousSnapshot != null) {
      _logNodeStyleConflicts(node.id, previousSnapshot, nextSnapshot);
      postDiagnostic(
        code: UyavaGraphIntegrityCode.nodesDuplicateId,
        level: UyavaDiagnosticLevel.warning,
        nodeId: node.id,
        context: const {'source': 'addNode'},
      );
    }

    graph.nodes[node.id] = node;
    nodeLifecycleStates.putIfAbsent(node.id, () => defaultLifecycleState);

    final String? init = sourceRef ?? _captureCallSite();
    if (init != null) {
      nodeInitSources[node.id] = init;
      developer.log('Uyava addNode: ${node.id} @ $init', name: 'Uyava');
      nextSnapshot['initSource'] = init;
    } else {
      developer.log('Uyava addNode: ${node.id}', name: 'Uyava');
    }

    postEvent('addNode', nextSnapshot);
  }

  /// Adds a single edge to the graph.
  void addEdge(UyavaEdge edge) {
    if (!graph.nodes.containsKey(edge.from)) {
      postDiagnostic(
        code: UyavaGraphIntegrityCode.edgesDanglingSource,
        level: UyavaDiagnosticLevel.error,
        edgeId: edge.id,
        context: {'source': edge.from, 'origin': 'addEdge'},
      );
      return;
    }
    if (!graph.nodes.containsKey(edge.to)) {
      postDiagnostic(
        code: UyavaGraphIntegrityCode.edgesDanglingTarget,
        level: UyavaDiagnosticLevel.error,
        edgeId: edge.id,
        context: {'target': edge.to, 'origin': 'addEdge'},
      );
      return;
    }
    if (edge.from == edge.to) {
      postDiagnostic(
        code: UyavaGraphIntegrityCode.edgesSelfLoop,
        level: UyavaDiagnosticLevel.error,
        edgeId: edge.id,
        context: {'nodeId': edge.from, 'origin': 'addEdge'},
      );
      return;
    }
    if (graph.edges.containsKey(edge.id)) {
      postDiagnostic(
        code: UyavaGraphIntegrityCode.edgesDuplicateId,
        level: UyavaDiagnosticLevel.warning,
        edgeId: edge.id,
        context: const {'source': 'addEdge'},
      );
    }
    graph.edges[edge.id] = edge;
    postEvent('addEdge', edge.toJson());
  }

  /// Removes a node from the graph and optionally cascades connected edges.
  ///
  /// When removing a node the SDK automatically drops any edges referencing it
  /// to keep the graph consistent. The payload emitted to hosts includes the
  /// removed node id and the list of edge ids that were cascaded.
  void removeNode(String nodeId) {
    final UyavaNode? removed = graph.nodes.remove(nodeId);
    if (removed == null) {
      developer.log(
        'Uyava removeNode ignored: unknown id $nodeId',
        name: 'Uyava',
      );
      return;
    }

    nodeLifecycleStates.remove(nodeId);
    nodeInitSources.remove(nodeId);

    final List<String> cascadeEdgeIds = <String>[];
    final List<String> toDelete = <String>[];
    graph.edges.forEach((edgeId, edge) {
      if (edge.from == nodeId || edge.to == nodeId) {
        toDelete.add(edgeId);
      }
    });
    for (final id in toDelete) {
      graph.edges.remove(id);
      cascadeEdgeIds.add(id);
    }

    developer.log(
      'Uyava removeNode: $nodeId (cascadeEdges=${cascadeEdgeIds.length})',
      name: 'Uyava',
    );

    postEvent(UyavaEventTypes.removeNode, <String, dynamic>{
      'id': nodeId,
      if (cascadeEdgeIds.isNotEmpty) 'cascadeEdgeIds': cascadeEdgeIds,
    });
  }

  /// Removes an edge from the graph.
  void removeEdge(String edgeId) {
    final UyavaEdge? removed = graph.edges.remove(edgeId);
    if (removed == null) {
      developer.log(
        'Uyava removeEdge ignored: unknown id $edgeId',
        name: 'Uyava',
      );
      return;
    }

    developer.log('Uyava removeEdge: $edgeId', name: 'Uyava');
    postEvent(UyavaEventTypes.removeEdge, <String, dynamic>{'id': edgeId});
  }

  Map<String, dynamic> nodeSnapshot(UyavaNode node) {
    final json = node.toJson();
    json['lifecycle'] =
        (nodeLifecycleStates[node.id] ?? defaultLifecycleState).name;
    return json;
  }

  void _logNodeStyleConflicts(
    String nodeId,
    Map<String, dynamic> previous,
    Map<String, dynamic> next,
  ) {
    final String? prevColor = previous['color'] as String?;
    final String? nextColor = next['color'] as String?;
    if (prevColor != null && nextColor != null && prevColor != nextColor) {
      developer.log(
        'Uyava node color overwritten for $nodeId: $prevColor → $nextColor',
        name: 'Uyava',
        level: 800,
      );
      postDiagnostic(
        code: UyavaGraphIntegrityCode.nodesConflictingColor,
        level: UyavaDiagnosticLevel.warning,
        nodeId: nodeId,
        context: {'previous': prevColor, 'next': nextColor},
      );
    }

    final List<String>? prevTags = (previous['tags'] as List?)
        ?.whereType<String>()
        .toList();
    final List<String>? nextTags = (next['tags'] as List?)
        ?.whereType<String>()
        .toList();
    if (prevTags != null &&
        nextTags != null &&
        !listEquals(prevTags, nextTags)) {
      developer.log(
        'Uyava node tags overwritten for $nodeId: $prevTags → $nextTags',
        name: 'Uyava',
        level: 800,
      );
      postDiagnostic(
        code: UyavaGraphIntegrityCode.nodesConflictingTags,
        level: UyavaDiagnosticLevel.warning,
        nodeId: nodeId,
        context: {'previous': prevTags, 'next': nextTags},
      );
    }
  }
}
