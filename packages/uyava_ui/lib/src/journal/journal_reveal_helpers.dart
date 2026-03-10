import 'dart:collection';

import 'package:uyava_core/uyava_core.dart';

import '../config.dart';
import '../focus_controller.dart';
import '../highlight.dart';
import 'journal_focus.dart';
import 'journal_link.dart';
import 'journal_reveal.dart';

/// Snapshot of highlight + reveal instructions for journal interactions.
class JournalRevealRequest {
  const JournalRevealRequest({
    required this.highlight,
    required this.revealPlan,
    this.focusResult,
  });

  /// Highlight to apply on the graph canvas.
  final GraphHighlight highlight;

  /// Instructions describing what must change so the highlight becomes visible.
  final JournalRevealPlan revealPlan;

  /// Desired viewport focus result, if one could be computed.
  final GraphJournalFocusResult? focusResult;

  bool get isFullyVisible => revealPlan.isFullyVisible;
}

/// Builds a highlight representing the current focus state.
GraphHighlight buildFocusHighlight({
  required GraphFocusState focusState,
  required GraphController graphController,
}) {
  if (focusState.isEmpty) return const GraphHighlight();
  final Set<String> nodeIds = LinkedHashSet<String>.from(focusState.nodeIds);
  final Set<GraphHighlightEdge> edges = <GraphHighlightEdge>{};
  if (focusState.edgeIds.isNotEmpty) {
    final Map<String, UyavaEdge> edgeById = {
      for (final UyavaEdge edge in graphController.edges) edge.id: edge,
    };
    for (final String edgeId in focusState.edgeIds) {
      final UyavaEdge? edge = edgeById[edgeId];
      if (edge == null) continue;
      edges.add(
        GraphHighlightEdge(sourceId: edge.source, targetId: edge.target),
      );
      nodeIds
        ..add(edge.source)
        ..add(edge.target);
    }
  }
  return GraphHighlight(nodeIds: nodeIds, edges: edges);
}

/// Resolves a journal link into a reveal request shared across hosts.
JournalRevealRequest? resolveJournalLinkReveal({
  required GraphJournalLinkTarget link,
  required GraphController graphController,
  required RenderConfig renderConfig,
  required Set<String> manualCollapsedParents,
  required Map<String, double> collapseProgress,
  required Set<String> autoCollapseOverrides,
}) {
  final GraphJournalFocusResult? result = resolveJournalLinkTarget(
    link: link,
    graphController: graphController,
    renderConfig: renderConfig,
  );
  if (result == null) {
    return null;
  }
  final JournalRevealPlan revealPlan = evaluateJournalReveal(
    controller: graphController,
    highlight: result.highlight,
    renderConfig: renderConfig,
    manualCollapsedParents: manualCollapsedParents,
    collapseProgress: collapseProgress,
    autoCollapseOverrides: autoCollapseOverrides,
  );
  return JournalRevealRequest(
    highlight: result.highlight,
    focusResult: result,
    revealPlan: revealPlan,
  );
}

/// Builds a reveal request covering the current focus selection.
JournalRevealRequest? buildFocusRevealRequest({
  required GraphFocusState focusState,
  required GraphController graphController,
  required RenderConfig renderConfig,
  required Set<String> manualCollapsedParents,
  required Map<String, double> collapseProgress,
  required Set<String> autoCollapseOverrides,
}) {
  final GraphHighlight highlight = buildFocusHighlight(
    focusState: focusState,
    graphController: graphController,
  );
  if (highlight.isEmpty) return null;
  final GraphJournalFocusResult? viewportTarget = focusResultForHighlight(
    graphController: graphController,
    renderConfig: renderConfig,
    highlight: highlight,
  );
  final JournalRevealPlan revealPlan = evaluateJournalReveal(
    controller: graphController,
    highlight: highlight,
    renderConfig: renderConfig,
    manualCollapsedParents: manualCollapsedParents,
    collapseProgress: collapseProgress,
    autoCollapseOverrides: autoCollapseOverrides,
  );
  return JournalRevealRequest(
    highlight: highlight,
    focusResult: viewportTarget,
    revealPlan: revealPlan,
  );
}
