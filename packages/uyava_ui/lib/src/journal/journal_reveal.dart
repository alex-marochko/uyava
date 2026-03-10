import 'package:collection/collection.dart';
import 'package:uyava_core/uyava_core.dart';

import '../config.dart';
import '../highlight.dart';

/// Describes the visibility state of a journal link target and what actions
/// are required to make it visible in the viewport.
class JournalRevealPlan {
  const JournalRevealPlan({
    required this.filteredNodeIds,
    required this.filteredEdges,
    required this.parentsToExpand,
  });

  /// Node identifiers that are currently excluded by active filters.
  final Set<String> filteredNodeIds;

  /// Edge segments that are currently excluded by active filters.
  final Set<GraphHighlightEdge> filteredEdges;

  /// Collapsed parent groups that must be expanded to surface the target.
  final Set<String> parentsToExpand;

  /// Whether filters are hiding parts of the target.
  bool get hiddenByFilters =>
      filteredNodeIds.isNotEmpty || filteredEdges.isNotEmpty;

  /// Whether collapsed groups are hiding parts of the target.
  bool get hiddenByGrouping => parentsToExpand.isNotEmpty;

  /// Whether the target is fully visible without additional actions.
  bool get isFullyVisible => !hiddenByFilters && !hiddenByGrouping;
}

JournalRevealPlan evaluateJournalReveal({
  required GraphController controller,
  required GraphHighlight highlight,
  required RenderConfig renderConfig,
  required Set<String> manualCollapsedParents,
  required Map<String, double> collapseProgress,
  required Set<String> autoCollapseOverrides,
}) {
  final Set<String> allNodeIds = controller.nodes
      .map((node) => node.id)
      .toSet();

  final Set<String> visibleNodeIds = controller.filteredNodes
      .map((node) => node.id)
      .toSet();

  final Set<String> filteredNodeIds = <String>{};
  for (final String id in highlight.nodeIds) {
    if (!visibleNodeIds.contains(id) && allNodeIds.contains(id)) {
      filteredNodeIds.add(id);
    }
  }

  final List<UyavaEdge> visibleEdges = controller.filteredEdges;
  final Set<GraphHighlightEdge> filteredEdges = <GraphHighlightEdge>{};
  for (final GraphHighlightEdge edge in highlight.edges) {
    final bool edgeVisible =
        visibleEdges.firstWhereOrNull(
          (UyavaEdge e) =>
              e.source == edge.sourceId && e.target == edge.targetId,
        ) !=
        null;
    if (!edgeVisible) {
      filteredEdges.add(edge);
    }
  }

  final Map<String, String?> parentById = <String, String?>{
    for (final UyavaNode node in controller.nodes)
      if (node.parentId != null) node.id: node.parentId,
  };

  final Set<String> effectiveCollapsedParents =
      <String>{...controller.autoCollapsedParents}
        ..removeAll(autoCollapseOverrides)
        ..addAll(manualCollapsedParents);

  final Map<String, double> effectiveProgress = Map<String, double>.from(
    collapseProgress,
  );
  for (final String parentId in controller.autoCollapsedParents) {
    if (autoCollapseOverrides.contains(parentId)) {
      effectiveProgress.remove(parentId);
    } else {
      effectiveProgress[parentId] = 1.0;
    }
  }
  for (final String parentId in manualCollapsedParents) {
    effectiveProgress[parentId] = effectiveProgress[parentId] ?? 1.0;
  }

  final Set<String> parentsToExpand = <String>{};
  final Set<String> candidateNodeIds = <String>{
    ...highlight.nodeIds.where(allNodeIds.contains),
    ...highlight.edges
        .expand((edge) => <String>[edge.sourceId, edge.targetId])
        .where(allNodeIds.contains),
  };

  for (final String nodeId in candidateNodeIds) {
    final Set<String> ancestors = _collapsedAncestorsFor(
      nodeId,
      parentById,
      effectiveCollapsedParents,
      effectiveProgress,
      renderConfig,
    );
    parentsToExpand.addAll(ancestors);
  }

  return JournalRevealPlan(
    filteredNodeIds: filteredNodeIds,
    filteredEdges: filteredEdges,
    parentsToExpand: parentsToExpand,
  );
}

Set<String> _collapsedAncestorsFor(
  String nodeId,
  Map<String, String?> parentById,
  Set<String> collapsedParents,
  Map<String, double> collapseProgress,
  RenderConfig renderConfig,
) {
  final Set<String> ancestors = <String>{};
  String? current = nodeId;
  while (true) {
    final String? parentId = parentById[current];
    if (parentId == null) break;
    final bool collapsed = collapsedParents.contains(parentId);
    final double progress =
        collapseProgress[parentId] ?? (collapsed ? 1.0 : 0.0);
    final double eased = renderConfig.ease.transform(progress.clamp(0.0, 1.0));
    final bool fullyCollapsed = collapsed && eased >= 1.0;
    final bool hiddenDuringTransition =
        !collapsed && progress > 0.0 && eased > renderConfig.expandRevealWindow;
    if (fullyCollapsed || hiddenDuringTransition) {
      ancestors.add(parentId);
    }
    current = parentId;
  }
  return ancestors;
}
