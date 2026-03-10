part of 'journal_view_model.dart';

class GraphJournalFocusContext {
  GraphJournalFocusContext._({
    required this.nodeIds,
    required this.edgeIds,
    required Set<_EdgeKey> edgePairs,
    required this.entries,
  }) : _edgePairs = edgePairs;

  factory GraphJournalFocusContext.fromGraph({
    required GraphFocusState focusState,
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
  }) {
    if (focusState.isEmpty) {
      return GraphJournalFocusContext.empty();
    }
    final Map<String, List<String>> childrenByParent = <String, List<String>>{};
    final Map<String, UyavaNode> nodeById = <String, UyavaNode>{};
    for (final UyavaNode node in nodes) {
      nodeById[node.id] = node;
      final String? parentId = node.parentId;
      if (parentId == null) continue;
      (childrenByParent[parentId] ??= <String>[]).add(node.id);
    }

    final Set<String> expandedNodeIds = _expandNodeFocus(
      focusState.nodeIds,
      childrenByParent,
    );

    final List<GraphJournalFocusEntry> entries = <GraphJournalFocusEntry>[];
    for (final String nodeId in focusState.nodeIds) {
      final UyavaNode? node = nodeById[nodeId];
      final String label = (node?.label ?? '').trim();
      entries.add(
        GraphJournalFocusEntry.node(
          id: nodeId,
          label: label.isEmpty ? nodeId : label,
        ),
      );
    }

    final Map<String, UyavaEdge> edgesById = {
      for (final UyavaEdge edge in edges) edge.id: edge,
    };
    final Set<String> focusEdgeIds = LinkedHashSet<String>.from(
      focusState.edgeIds,
    );
    final Set<_EdgeKey> focusEdgePairs = <_EdgeKey>{};
    for (final String edgeId in focusEdgeIds) {
      final UyavaEdge? edge = edgesById[edgeId];
      if (edge == null) continue;
      focusEdgePairs.add(_EdgeKey(edge.source, edge.target));
      expandedNodeIds.add(edge.source);
      expandedNodeIds.add(edge.target);
      entries.add(
        GraphJournalFocusEntry.edge(
          id: edgeId,
          label: '${edge.source} → ${edge.target}',
        ),
      );
    }

    return GraphJournalFocusContext._(
      nodeIds: expandedNodeIds,
      edgeIds: focusEdgeIds,
      edgePairs: focusEdgePairs,
      entries: entries,
    );
  }

  factory GraphJournalFocusContext.empty() => GraphJournalFocusContext._(
    nodeIds: const <String>{},
    edgeIds: const <String>{},
    edgePairs: const <_EdgeKey>{},
    entries: const <GraphJournalFocusEntry>[],
  );

  final Set<String> nodeIds;
  final Set<String> edgeIds;
  final Set<_EdgeKey> _edgePairs;
  final List<GraphJournalFocusEntry> entries;

  bool get hasFocus => nodeIds.isNotEmpty || edgeIds.isNotEmpty;

  bool containsEdgePair(String source, String target) {
    return _edgePairs.contains(_EdgeKey(source, target));
  }

  String get summaryLabel {
    final int nodeCount = nodeIds.length;
    final int edgeCount = edgeIds.length;
    if (nodeCount == 0 && edgeCount == 0) {
      return 'Focus';
    }
    if (nodeCount > 0 && edgeCount > 0) {
      return 'Focus · ${_pluralize(nodeCount, 'node')} · ${_pluralize(edgeCount, 'edge')}';
    }
    if (nodeCount > 0) {
      return 'Focus · ${_pluralize(nodeCount, 'node')}';
    }
    return 'Focus · ${_pluralize(edgeCount, 'edge')}';
  }
}

class GraphJournalFocusEntry {
  const GraphJournalFocusEntry._({
    required this.isNode,
    required this.id,
    required this.label,
  });

  const GraphJournalFocusEntry.node({required String id, required String label})
    : this._(isNode: true, id: id, label: label);

  const GraphJournalFocusEntry.edge({required String id, required String label})
    : this._(isNode: false, id: id, label: label);

  final bool isNode;
  final String id;
  final String label;
}

Set<String> _expandNodeFocus(
  Iterable<String> seeds,
  Map<String, List<String>> childrenByParent,
) {
  final Set<String> expanded = LinkedHashSet<String>.from(seeds);
  final List<String> queue = List<String>.from(seeds);
  while (queue.isNotEmpty) {
    final String current = queue.removeLast();
    final List<String>? children = childrenByParent[current];
    if (children == null) continue;
    for (final String child in children) {
      if (expanded.add(child)) {
        queue.add(child);
      }
    }
  }
  return expanded;
}

class _EdgeKey {
  const _EdgeKey(this.source, this.target);

  final String source;
  final String target;

  @override
  bool operator ==(Object other) {
    return other is _EdgeKey &&
        other.source == source &&
        other.target == target;
  }

  @override
  int get hashCode => Object.hash(source, target);
}

String _pluralize(int count, String noun) {
  final String suffix = count == 1 ? '' : 's';
  return '$count $noun$suffix';
}
