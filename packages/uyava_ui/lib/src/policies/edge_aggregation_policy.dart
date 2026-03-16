import 'package:flutter/animation.dart';
import 'package:uyava_core/uyava_core.dart';

/// Encapsulates how edges are remapped across collapsed ancestors and how
/// their visibility fades during transitions.
class EdgeAggregationPolicy {
  final Set<String> collapsedParents;
  final Map<String, double> collapseProgress; // 0..1 raw
  final Map<String, String?> parentById; // nodeId -> parentId
  final Curve ease;

  /// Edges continue to route via parents while eased progress >= threshold.
  final double edgeRemapThreshold;

  EdgeAggregationPolicy({
    required this.collapsedParents,
    required this.collapseProgress,
    required this.parentById,
    this.ease = Curves.easeInOut,
    this.edgeRemapThreshold = 0.5,
  });

  /// Walks ancestors and maps to the nearest ancestor considered collapsed.
  String mapToVisibleAncestor(String id) {
    String mapped = id;
    String? current = id;
    while (true) {
      final p = parentById[current];
      if (p == null) break;
      final prog = collapseProgress[p] ?? 0.0;
      final consideredCollapsed =
          collapsedParents.contains(p) ||
          ease.transform(prog.clamp(0.0, 1.0)) >= edgeRemapThreshold;
      if (consideredCollapsed) {
        mapped = p; // nearest collapsed ancestor so far
      }
      current = p; // continue walking even if parent isn't collapsed
    }
    return mapped;
  }

  /// Aggregates edges by their currently visible endpoints, annotating
  /// whether the result was remapped and preferring direct (non-remapped)
  /// edges when both exist for the same pair.
  List<UyavaEdge> remapAndAggregateEdges(Iterable<UyavaEdge> edges) {
    final Map<String, Map<String, dynamic>> pairToEdgeData = {};
    final Map<String, bool> pairIsRemapped = {};
    final Map<String, bool> pairHasForward = {}; // src->dst seen
    final Map<String, bool> pairHasReverse = {}; // dst->src seen

    for (final e in edges) {
      final src = mapToVisibleAncestor(e.source);
      final dst = mapToVisibleAncestor(e.target);
      if (src == dst) continue; // hide intra-group edges when collapsed

      final keyList = [src, dst]..sort();
      final pairKey = keyList.join('—');

      // Track direction presence relative to sorted pair (a->b or b->a)
      final isForward = src.compareTo(dst) <= 0;
      if (isForward) {
        pairHasForward[pairKey] = true;
      } else {
        pairHasReverse[pairKey] = true;
      }

      final isRemapped = (src != e.source || dst != e.target);
      final newData = Map<String, dynamic>.from(e.data)
        ..['source'] = src
        ..['target'] = dst
        ..['remapped'] = isRemapped;

      if (!pairToEdgeData.containsKey(pairKey)) {
        pairToEdgeData[pairKey] = newData;
        pairIsRemapped[pairKey] = isRemapped;
      } else {
        final existingIsRemapped = pairIsRemapped[pairKey] ?? false;
        // Prefer non-remapped (direct) edge if available.
        if (existingIsRemapped && !isRemapped) {
          pairToEdgeData[pairKey] = newData;
          pairIsRemapped[pairKey] = false;
        }
      }
    }

    // Annotate bidirectionality on aggregated edges
    for (final entry in pairToEdgeData.entries) {
      final key = entry.key;
      final data = entry.value;
      final bi = (pairHasForward[key] == true) && (pairHasReverse[key] == true);
      data['bidirectional'] = bi;
    }

    return [for (final data in pairToEdgeData.values) UyavaEdge(data: data)];
  }

  /// Computes the effective eased progress for the nearest transitioning
  /// ancestor. If [includeSelf] is false, skips the node itself.
  double effectiveProgressForNode(String id, {bool includeSelf = true}) {
    String? ancestor = includeSelf ? id : parentById[id];
    while (ancestor != null) {
      final p = collapseProgress[ancestor] ?? 0.0;
      if (p > 0.0) {
        return ease.transform(p.clamp(0.0, 1.0));
      }
      ancestor = parentById[ancestor];
    }
    return 0.0;
  }

  /// Fade factor for an edge based on remapping and endpoint progress.
  /// - Non-remapped edges fade out as t grows (collapse).
  /// - Remapped edges fade in as t grows.
  double edgeFade({
    required bool remapped,
    required String sourceId,
    required String targetId,
  }) {
    final tA = effectiveProgressForNode(sourceId, includeSelf: remapped);
    final tB = effectiveProgressForNode(targetId, includeSelf: remapped);
    final tEdge = tA > tB ? tA : tB;
    return (remapped ? tEdge : (1.0 - tEdge)).clamp(0.0, 1.0);
  }

  /// Returns true if an event between [from] and [to] occurs within the same
  /// collapsed (or effectively-collapsed) group, meaning child edges would be
  /// hidden and a pulse should be shown on the parent instead.
  ///
  /// This checks that both endpoints map to the same visible ancestor and that
  /// the ancestor is considered collapsed (either explicitly or by eased
  /// progress over the remap threshold). It also guards against treating a
  /// direct self-edge on a child as intra-group by requiring that at least one
  /// endpoint mapped to a different ancestor.
  bool isIntraCollapsedGroupEvent(String from, String to) {
    // Ignore explicit self-loops at the source; treat them as non-edge events.
    if (from == to) return false;
    final visFrom = mapToVisibleAncestor(from);
    final visTo = mapToVisibleAncestor(to);
    if (visFrom != visTo) return false;

    final prog = collapseProgress[visFrom] ?? 0.0;
    final consideredCollapsed =
        collapsedParents.contains(visFrom) ||
        ease.transform(prog.clamp(0.0, 1.0)) >= edgeRemapThreshold;

    final mappedAny = (visFrom != from) || (visTo != to);
    return consideredCollapsed && mappedAny;
  }
}
