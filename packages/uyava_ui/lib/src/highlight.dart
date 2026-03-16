import 'package:flutter/foundation.dart';

/// Directed edge helper used when highlighting graph elements.
@immutable
class GraphHighlightEdge {
  const GraphHighlightEdge({required this.sourceId, required this.targetId});

  final String sourceId;
  final String targetId;

  @override
  int get hashCode => Object.hash(sourceId, targetId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphHighlightEdge &&
        other.sourceId == sourceId &&
        other.targetId == targetId;
  }
}

/// A simple value object describing nodes and edges that should be emphasized.
@immutable
class GraphHighlight {
  const GraphHighlight({
    this.nodeIds = const <String>{},
    this.edges = const <GraphHighlightEdge>{},
  });

  final Set<String> nodeIds;
  final Set<GraphHighlightEdge> edges;

  bool get isEmpty => nodeIds.isEmpty && edges.isEmpty;
}
