import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:uyava_core/uyava_core.dart';

/// Immutable snapshot of focused graph elements.
class GraphFocusState {
  GraphFocusState({
    Set<String> nodeIds = const <String>{},
    Set<String> edgeIds = const <String>{},
  }) : nodeIds = UnmodifiableSetView<String>(Set<String>.from(nodeIds)),
       edgeIds = UnmodifiableSetView<String>(Set<String>.from(edgeIds));

  /// Predefined empty state to avoid repeated allocations.
  static final GraphFocusState empty = GraphFocusState();

  final UnmodifiableSetView<String> nodeIds;
  final UnmodifiableSetView<String> edgeIds;

  bool get isEmpty => nodeIds.isEmpty && edgeIds.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphFocusState &&
        setEquals(other.nodeIds, nodeIds) &&
        setEquals(other.edgeIds, edgeIds);
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(nodeIds), Object.hashAll(edgeIds));
}

/// Controller tracking the current focus selection on the graph.
class GraphFocusController extends ChangeNotifier {
  GraphFocusState _state = GraphFocusState.empty;

  GraphFocusState get state => _state;

  bool containsNode(String nodeId) => _state.nodeIds.contains(nodeId);
  bool containsEdge(String edgeId) => _state.edgeIds.contains(edgeId);

  bool addNode(String nodeId) {
    if (_state.nodeIds.contains(nodeId)) return false;
    final nextNodes = LinkedHashSet<String>.from(_state.nodeIds)..add(nodeId);
    _update(nodeIds: nextNodes);
    return true;
  }

  bool removeNode(String nodeId) {
    if (!_state.nodeIds.contains(nodeId)) return false;
    final nextNodes = LinkedHashSet<String>.from(_state.nodeIds)
      ..remove(nodeId);
    _update(nodeIds: nextNodes);
    return true;
  }

  bool toggleNode(String nodeId) =>
      containsNode(nodeId) ? removeNode(nodeId) : addNode(nodeId);

  bool addEdge(String edgeId) {
    if (_state.edgeIds.contains(edgeId)) return false;
    final nextEdges = LinkedHashSet<String>.from(_state.edgeIds)..add(edgeId);
    _update(edgeIds: nextEdges);
    return true;
  }

  bool removeEdge(String edgeId) {
    if (!_state.edgeIds.contains(edgeId)) return false;
    final nextEdges = LinkedHashSet<String>.from(_state.edgeIds)
      ..remove(edgeId);
    _update(edgeIds: nextEdges);
    return true;
  }

  bool toggleEdge(String edgeId) =>
      containsEdge(edgeId) ? removeEdge(edgeId) : addEdge(edgeId);

  void clear() {
    if (_state.isEmpty) return;
    _update(nodeIds: <String>{}, edgeIds: <String>{});
  }

  void setState(GraphFocusState state) {
    _state = GraphFocusState(nodeIds: state.nodeIds, edgeIds: state.edgeIds);
    notifyListeners();
  }

  void _update({Set<String>? nodeIds, Set<String>? edgeIds}) {
    final nextNodes = nodeIds != null
        ? LinkedHashSet<String>.from(nodeIds)
        : null;
    final nextEdges = edgeIds != null
        ? LinkedHashSet<String>.from(edgeIds)
        : null;
    final GraphFocusState nextState = GraphFocusState(
      nodeIds: nextNodes ?? _state.nodeIds,
      edgeIds: nextEdges ?? _state.edgeIds,
    );
    if (nextState == _state) return;
    _state = nextState;
    notifyListeners();
  }
}

/// Result of applying a focus filter to the current graph view.
class GraphFocusFilterResult {
  GraphFocusFilterResult({
    required this.nodes,
    required this.edges,
    required this.focusNodeIds,
  });

  final List<UyavaNode> nodes;
  final List<UyavaEdge> edges;
  final Set<String> focusNodeIds;

  bool get hasFocus => focusNodeIds.isNotEmpty;
}

/// Applies the focus selection to the provided node and edge lists.
GraphFocusFilterResult applyFocusFilter({
  required GraphFocusState focusState,
  required List<UyavaNode> nodes,
  required List<UyavaEdge> edges,
  required Map<String, String?> parentById,
}) {
  if (focusState.isEmpty) {
    return GraphFocusFilterResult(
      nodes: nodes,
      edges: edges,
      focusNodeIds: const <String>{},
    );
  }

  final Set<String> focusNodeIds = <String>{}..addAll(focusState.nodeIds);
  final Set<String> focusEdgeIds = focusState.edgeIds.toSet();

  if (focusEdgeIds.isNotEmpty) {
    for (final UyavaEdge edge in edges) {
      if (focusEdgeIds.contains(edge.id)) {
        focusNodeIds.add(edge.source);
        focusNodeIds.add(edge.target);
      }
    }
  }

  // Include ancestors so that focused descendants remain attached to context.
  final List<String> seeds = focusNodeIds.toList(growable: false);
  for (final String id in seeds) {
    String? ancestor = parentById[id];
    while (ancestor != null) {
      focusNodeIds.add(ancestor);
      ancestor = parentById[ancestor];
    }
  }

  final List<UyavaNode> filteredNodes = nodes
      .where((node) => focusNodeIds.contains(node.id))
      .toList();
  final List<UyavaEdge> filteredEdges = edges.where((edge) {
    final bool edgeFocused = focusEdgeIds.contains(edge.id);
    final bool connectsFocusedNodes =
        focusNodeIds.contains(edge.source) &&
        focusNodeIds.contains(edge.target);
    return edgeFocused || connectsFocusedNodes;
  }).toList();

  return GraphFocusFilterResult(
    nodes: filteredNodes,
    edges: filteredEdges,
    focusNodeIds: focusNodeIds,
  );
}
