import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:collection/collection.dart';
import 'package:uyava_core/uyava_core.dart';

import '../adapters.dart';
import '../config.dart';
import '../highlight.dart';
import 'journal_link.dart';

/// Result of resolving a journal link into highlight + viewport guidance.
class GraphJournalFocusResult {
  const GraphJournalFocusResult({
    required this.highlight,
    this.focusPoint,
    this.focusBounds,
  });

  /// Highlight instructions to apply on the graph canvas.
  final GraphHighlight highlight;

  /// Optional point that should be centered within the viewport.
  final Offset? focusPoint;

  /// Optional bounding box that should be fully visible within the viewport.
  final Rect? focusBounds;

  bool get hasFocusPoint => focusPoint != null;
  bool get hasFocusBounds => focusBounds != null && !focusBounds!.isEmpty;
}

/// Resolves a [GraphJournalLinkTarget] using the given [graphController].
///
/// Returns null when the referenced element cannot be located (e.g. the node
/// has been filtered out or the graph has not rendered yet).
GraphJournalFocusResult? resolveJournalLinkTarget({
  required GraphJournalLinkTarget link,
  required GraphController graphController,
  required RenderConfig renderConfig,
}) {
  switch (link) {
    case GraphJournalNodeLink(:final nodeId):
      return _resolveNode(nodeId, graphController, renderConfig);
    case GraphJournalEdgeLink(:final from, :final to):
      return _resolveEdge(from, to, graphController, renderConfig);
    case GraphJournalSubjectLink(:final subjectId):
      final UyavaNode? node = graphController.nodes.firstWhereOrNull(
        (n) => n.id == subjectId,
      );
      if (node != null) {
        return _resolveNode(node.id, graphController, renderConfig);
      }
      final UyavaEdge? edge = graphController.edges.firstWhereOrNull(
        (e) => e.id == subjectId,
      );
      if (edge != null) {
        return _resolveEdge(
          edge.source,
          edge.target,
          graphController,
          renderConfig,
        );
      }
      return null;
  }
}

GraphJournalFocusResult? _resolveNode(
  String nodeId,
  GraphController graphController,
  RenderConfig renderConfig,
) {
  final UyavaNode? node = graphController.nodes.firstWhereOrNull(
    (n) => n.id == nodeId,
  );
  final Vector2? position = graphController.positions[nodeId];
  if (position == null) return null;
  final Offset point = toOffset(position);
  final GraphHighlight highlight = GraphHighlight(nodeIds: <String>{nodeId});
  final bool isParent =
      node != null &&
      graphController.nodes.any((candidate) => candidate.parentId == nodeId);
  final double baseRadius = isParent
      ? renderConfig.parentNodeRadius
      : renderConfig.childNodeRadius;
  final double radius = math.max(
    baseRadius * 4.0,
    renderConfig.childNodeRadius * 3,
  );
  final Rect bounds = Rect.fromCircle(center: point, radius: radius);
  return GraphJournalFocusResult(
    highlight: highlight,
    focusPoint: point,
    focusBounds: bounds,
  );
}

GraphJournalFocusResult? _resolveEdge(
  String from,
  String to,
  GraphController graphController,
  RenderConfig renderConfig,
) {
  final Vector2? source = graphController.positions[from];
  final Vector2? target = graphController.positions[to];
  if (source == null || target == null) return null;

  final Offset sourceOffset = toOffset(source);
  final Offset targetOffset = toOffset(target);

  final GraphHighlight highlight = GraphHighlight(
    nodeIds: <String>{from, to},
    edges: <GraphHighlightEdge>{
      GraphHighlightEdge(sourceId: from, targetId: to),
    },
  );

  final Rect rawBounds = Rect.fromPoints(sourceOffset, targetOffset);
  final double padding = math.max(
    renderConfig.childNodeRadius * 6,
    renderConfig.edgeArrowLength * 3,
  );
  Rect expanded = rawBounds.inflate(padding);
  const double minSpan = 160;
  if (expanded.width < minSpan) {
    final double dx = (minSpan - expanded.width) / 2;
    expanded = Rect.fromLTRB(
      expanded.left - dx,
      expanded.top,
      expanded.right + dx,
      expanded.bottom,
    );
  }
  if (expanded.height < minSpan) {
    final double dy = (minSpan - expanded.height) / 2;
    expanded = Rect.fromLTRB(
      expanded.left,
      expanded.top - dy,
      expanded.right,
      expanded.bottom + dy,
    );
  }
  final Offset mid = Offset(
    (sourceOffset.dx + targetOffset.dx) / 2,
    (sourceOffset.dy + targetOffset.dy) / 2,
  );
  return GraphJournalFocusResult(
    highlight: highlight,
    focusPoint: mid,
    focusBounds: expanded,
  );
}

/// Builds a viewport target covering the provided [highlight].
///
/// Returns null when none of the highlighted nodes are present in the current
/// layout (e.g. before the graph controller finishes its first tick).
GraphJournalFocusResult? focusResultForHighlight({
  required GraphController graphController,
  required RenderConfig renderConfig,
  required GraphHighlight highlight,
}) {
  if (highlight.isEmpty) return null;
  final Map<String, Vector2> positions = graphController.positions;
  if (positions.isEmpty) return null;

  final Set<String> relevantNodeIds = <String>{
    ...highlight.nodeIds,
    for (final GraphHighlightEdge edge in highlight.edges) ...[
      edge.sourceId,
      edge.targetId,
    ],
  };
  if (relevantNodeIds.isEmpty) return null;

  final Set<String> parentIds = {
    for (final UyavaNode node in graphController.nodes)
      if (node.parentId != null) node.parentId!,
  };

  double minX = double.infinity;
  double maxX = -double.infinity;
  double minY = double.infinity;
  double maxY = -double.infinity;
  bool foundPosition = false;

  for (final String nodeId in relevantNodeIds) {
    final Vector2? position = positions[nodeId];
    if (position == null) continue;
    foundPosition = true;
    final Offset point = toOffset(position);
    final bool isParent = parentIds.contains(nodeId);
    final double baseRadius = isParent
        ? renderConfig.parentNodeRadius
        : renderConfig.childNodeRadius;
    final double radius = math.max(
      baseRadius * 4.0,
      renderConfig.childNodeRadius * 3.0,
    );
    minX = math.min(minX, point.dx - radius);
    maxX = math.max(maxX, point.dx + radius);
    minY = math.min(minY, point.dy - radius);
    maxY = math.max(maxY, point.dy + radius);
  }

  if (!foundPosition) return null;

  final double minExtent = renderConfig.childNodeRadius * 8;
  double width = maxX - minX;
  double height = maxY - minY;
  if (!width.isFinite || !height.isFinite) return null;
  width = math.max(width, minExtent);
  height = math.max(height, minExtent);
  final Offset center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
  final Rect bounds = Rect.fromCenter(
    center: center,
    width: width,
    height: height,
  );
  return GraphJournalFocusResult(
    highlight: highlight,
    focusPoint: center,
    focusBounds: bounds,
  );
}
