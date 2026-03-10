import 'dart:collection';

import 'package:uyava_protocol/uyava_protocol.dart';

import 'graph_event_chains.dart';
import 'graph_filter_result.dart';
import 'graph_filter_state.dart';
import 'graph_metrics.dart';
import 'uyava_edge.dart';
import 'uyava_node.dart';

/// Applies filter state to graph data and produces a filtered view.
class GraphFilterEngine {
  static GraphFilterResult apply({
    required GraphFilterState state,
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
    required List<GraphMetricSnapshot> metrics,
    required List<GraphEventChainSnapshot> eventChains,
  }) {
    if (nodes.isEmpty) {
      return GraphFilterResult(
        state: state,
        visibleNodes: const <UyavaNode>[],
        visibleNodeIds: const <String>{},
        hiddenNodeIds: const <String>{},
        hiddenByDepthNodeIds: const <String>{},
        autoCollapsedParents: const <String>{},
        visibleEdges: const <UyavaEdge>[],
        visibleEdgeIds: const <String>{},
        visibleMetrics: _filterMetrics(state, metrics),
        visibleEventChains: _filterEventChains(state, eventChains),
      );
    }

    final Map<String, UyavaNode> nodeById = {
      for (final node in nodes) node.id: node,
    };
    final Map<String, List<UyavaNode>> childrenByParent =
        <String, List<UyavaNode>>{};
    for (final node in nodes) {
      final String? parentId = node.parentId;
      if (parentId == null) continue;
      childrenByParent.putIfAbsent(parentId, () => <UyavaNode>[]).add(node);
    }

    final Set<String> scope = _resolveScope(state.parent, nodeById);
    if (scope.isEmpty) {
      return GraphFilterResult(
        state: state,
        visibleNodes: const <UyavaNode>[],
        visibleNodeIds: const <String>{},
        hiddenNodeIds: const <String>{},
        hiddenByDepthNodeIds: const <String>{},
        autoCollapsedParents: const <String>{},
        visibleEdges: const <UyavaEdge>[],
        visibleEdgeIds: const <String>{},
        visibleMetrics: _filterMetrics(state, metrics),
        visibleEventChains: _filterEventChains(state, eventChains),
      );
    }

    final Map<String, int> absoluteDepth = <String, int>{};
    final Set<String> visiting = <String>{};
    int depthFor(String id) {
      return absoluteDepth.putIfAbsent(id, () {
        if (visiting.contains(id)) {
          return 0; // Break potential cycles.
        }
        visiting.add(id);
        final UyavaNode? node = nodeById[id];
        final String? parentId = node?.parentId;
        if (parentId == null || !nodeById.containsKey(parentId)) {
          visiting.remove(id);
          return 0;
        }
        final int parentDepth = depthFor(parentId);
        visiting.remove(id);
        return parentDepth + 1;
      });
    }

    for (final id in scope) {
      depthFor(id);
    }

    final Map<String, int> relativeDepth = _relativeDepthMap(
      state.parent?.rootId,
      childrenByParent,
    );

    final Set<String> baseMatches = _collectNodeMatches(state, scope, nodeById);

    final Set<String> candidateNodes = Set<String>.from(baseMatches);
    void addAncestors(String id) {
      String? current = nodeById[id]?.parentId;
      while (current != null) {
        if (!scope.contains(current)) break;
        if (!candidateNodes.add(current)) break;
        current = nodeById[current]?.parentId;
      }
    }

    for (final id in baseMatches) {
      addAncestors(id);
    }

    final String? rootId = state.parent?.rootId;
    if (rootId != null && scope.contains(rootId)) {
      candidateNodes.add(rootId);
    }

    final int? absoluteDepthLimit = _absoluteDepthLimit(state);
    final int? relativeDepthLimit = _relativeDepthLimit(state);

    final Set<String> visibleNodeIds = <String>{...candidateNodes};
    final Set<String> hiddenNodeIds = <String>{};
    final Set<String> hiddenByDepthNodeIds = <String>{};
    final Set<String> autoCollapsedParents = <String>{};

    final bool enforceDepthLimits =
        absoluteDepthLimit != null || relativeDepthLimit != null;
    final bool collapseOnly =
        state.grouping?.mode == UyavaFilterGroupingMode.level &&
        state.grouping?.levelDepth != null &&
        state.parent?.depth == null;
    if (enforceDepthLimits) {
      for (final String id in candidateNodes) {
        final int depthAbs = absoluteDepth[id] ?? 0;
        final bool withinAbsolute =
            absoluteDepthLimit == null || depthAbs <= absoluteDepthLimit;

        bool withinRelative = true;
        if (relativeDepthLimit != null) {
          final int? rel = relativeDepth[id];
          withinRelative = rel != null && rel <= relativeDepthLimit;
        }

        if (withinAbsolute && withinRelative) continue;

        hiddenNodeIds.add(id);
        hiddenByDepthNodeIds.add(id);

        final String? ancestor = _nearestAncestorWithinLimits(
          id: id,
          nodeById: nodeById,
          scope: scope,
          candidateNodes: candidateNodes,
          absoluteDepthLimit: absoluteDepthLimit,
          relativeDepthLimit: relativeDepthLimit,
          absoluteDepth: absoluteDepth,
          relativeDepth: relativeDepth,
        );
        if (ancestor != null) {
          autoCollapsedParents.add(ancestor);
        }

        if (!collapseOnly) {
          visibleNodeIds.remove(id);
        }
      }
    }

    final List<GraphMetricSnapshot> filteredMetrics = _filterMetrics(
      state,
      metrics,
    );
    final List<GraphEventChainSnapshot> filteredChains = _filterEventChains(
      state,
      eventChains,
    );

    final List<UyavaNode> visibleNodes = [
      for (final node in nodes)
        if (visibleNodeIds.contains(node.id)) node,
    ];

    final List<UyavaEdge> visibleEdges = [
      for (final edge in edges)
        if (visibleNodeIds.contains(edge.source) &&
            visibleNodeIds.contains(edge.target))
          edge,
    ];
    final Set<String> visibleEdgeIds = {
      for (final edge in visibleEdges) edge.id,
    };

    return GraphFilterResult(
      state: state,
      visibleNodes: visibleNodes,
      visibleNodeIds: visibleNodeIds,
      hiddenNodeIds: hiddenNodeIds,
      hiddenByDepthNodeIds: hiddenByDepthNodeIds,
      autoCollapsedParents: autoCollapsedParents,
      visibleEdges: visibleEdges,
      visibleEdgeIds: visibleEdgeIds,
      visibleMetrics: filteredMetrics,
      visibleEventChains: filteredChains,
    );
  }

  static Set<String> _resolveScope(
    GraphFilterParent? parent,
    Map<String, UyavaNode> nodeById,
  ) {
    if (parent?.rootId == null) {
      return nodeById.keys.toSet();
    }
    final String rootId = parent!.rootId!;
    if (!nodeById.containsKey(rootId)) {
      return const <String>{};
    }
    final Set<String> scope = <String>{};
    final Queue<String> queue = Queue<String>()..add(rootId);
    while (queue.isNotEmpty) {
      final String current = queue.removeFirst();
      if (!scope.add(current)) continue;
      final Iterable<String> children = nodeById.values
          .where((node) => node.parentId == current)
          .map((node) => node.id);
      queue.addAll(children);
    }
    return scope;
  }

  static Map<String, int> _relativeDepthMap(
    String? rootId,
    Map<String, List<UyavaNode>> childrenByParent,
  ) {
    if (rootId == null) return const <String, int>{};
    final Map<String, int> result = <String, int>{};
    void traverse(String id, int depth) {
      result[id] = depth;
      final List<UyavaNode>? children = childrenByParent[id];
      if (children == null) return;
      for (final child in children) {
        traverse(child.id, depth + 1);
      }
    }

    traverse(rootId, 0);
    return result;
  }

  static Set<String> _collectNodeMatches(
    GraphFilterState state,
    Set<String> scope,
    Map<String, UyavaNode> nodeById,
  ) {
    final GraphFilterSearch? search = state.search;
    final GraphFilterTags? tags = state.tags;
    final GraphFilterNodeSet? nodeSet = state.nodes;
    final Set<String> matches = <String>{};
    for (final id in scope) {
      final UyavaNode? node = nodeById[id];
      if (node == null) continue;
      if (nodeSet != null && !nodeSet.allows(id)) continue;
      if (search != null && !search.matchesNode(node)) continue;
      if (tags != null && !tags.matchesNode(node)) continue;
      matches.add(id);
    }
    return matches;
  }

  static int? _absoluteDepthLimit(GraphFilterState state) {
    int? limit;
    final GraphFilterGrouping? grouping = state.grouping;
    if (grouping != null &&
        grouping.mode == UyavaFilterGroupingMode.level &&
        grouping.levelDepth != null) {
      limit = grouping.levelDepth;
    }
    final GraphFilterParent? parent = state.parent;
    if (parent != null && parent.rootId == null && parent.depth != null) {
      limit = _minNullable(limit, parent.depth);
    }
    return limit;
  }

  static int? _relativeDepthLimit(GraphFilterState state) {
    final GraphFilterParent? parent = state.parent;
    if (parent == null || parent.rootId == null) return null;
    return parent.depth;
  }

  static String? _nearestAncestorWithinLimits({
    required String id,
    required Map<String, UyavaNode> nodeById,
    required Set<String> scope,
    required Set<String> candidateNodes,
    required int? absoluteDepthLimit,
    required int? relativeDepthLimit,
    required Map<String, int> absoluteDepth,
    required Map<String, int> relativeDepth,
  }) {
    String? current = nodeById[id]?.parentId;
    while (current != null) {
      if (!scope.contains(current)) return null;
      final int depthAbs = absoluteDepth[current] ?? 0;
      final bool withinAbs =
          absoluteDepthLimit == null || depthAbs <= absoluteDepthLimit;
      bool withinRel = true;
      if (relativeDepthLimit != null) {
        final int? rel = relativeDepth[current];
        withinRel = rel != null && rel <= relativeDepthLimit;
      }
      if (withinAbs && withinRel && candidateNodes.contains(current)) {
        return current;
      }
      current = nodeById[current]?.parentId;
    }
    return null;
  }

  static List<GraphMetricSnapshot> _filterMetrics(
    GraphFilterState state,
    List<GraphMetricSnapshot> metrics,
  ) {
    final GraphFilterSearch? search = state.search;
    final GraphFilterTags? tags = state.tags;
    return [
      for (final metric in metrics)
        if ((search == null || search.matchesMetric(metric)) &&
            (tags == null || tags.matchesMetric(metric)))
          metric,
    ];
  }

  static List<GraphEventChainSnapshot> _filterEventChains(
    GraphFilterState state,
    List<GraphEventChainSnapshot> chains,
  ) {
    final GraphFilterSearch? search = state.search;
    final GraphFilterTags? tags = state.tags;
    return [
      for (final chain in chains)
        if ((search == null || search.matchesChain(chain)) &&
            (tags == null || tags.matchesChain(chain)))
          chain,
    ];
  }

  static int? _minNullable(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a < b ? a : b;
  }
}
