import 'dart:math' as math;

import 'package:uyava_core/uyava_core.dart';

/// Computes the available grouping depth levels for the provided [nodes].
///
/// The result is a sorted list of depth levels starting at `0`. When the graph
/// has no nodes, the list defaults to `[0]` so callers can continue to offer
/// the baseline grouping option.
List<int> computeGroupingLevels(Iterable<UyavaNode> nodes) {
  if (nodes.isEmpty) {
    return <int>[0];
  }

  final Map<String, UyavaNode> byId = {
    for (final UyavaNode node in nodes) node.id: node,
  };
  final Map<String, List<UyavaNode>> childrenByParent =
      <String, List<UyavaNode>>{};
  final List<UyavaNode> roots = <UyavaNode>[];

  for (final UyavaNode node in nodes) {
    final String? parentId = node.parentId;
    if (parentId == null || !byId.containsKey(parentId)) {
      roots.add(node);
    } else {
      (childrenByParent[parentId] ??= <UyavaNode>[]).add(node);
    }
  }

  int maxDepth = 0;
  final Set<String> visiting = <String>{};

  void traverse(UyavaNode node, int depth) {
    if (!visiting.add(node.id)) {
      // Cycle detected; bail out to avoid infinite recursion.
      visiting.remove(node.id);
      return;
    }
    maxDepth = math.max(maxDepth, depth);
    final List<UyavaNode>? children = childrenByParent[node.id];
    if (children != null) {
      for (final UyavaNode child in children) {
        traverse(child, depth + 1);
      }
    }
    visiting.remove(node.id);
  }

  if (roots.isEmpty) {
    // If every node references a parent, pick an arbitrary root to ensure we
    // still measure depth for the connected component.
    traverse(nodes.first, 0);
  } else {
    for (final UyavaNode root in roots) {
      traverse(root, 0);
    }
  }

  return [for (int level = 0; level <= maxDepth; level++) level];
}
