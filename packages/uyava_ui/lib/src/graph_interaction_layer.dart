import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import 'config.dart';
import 'display_node.dart';

/// Stateless helper that encapsulates reusable graph hit-test logic for taps or
/// gestures layered above the painter.
class GraphInteractionLayer {
  const GraphInteractionLayer({
    required this.displayNodes,
    required this.childrenByParent,
    required this.renderConfig,
  });

  final List<DisplayNode> displayNodes;
  final Map<String, List<UyavaNode>> childrenByParent;
  final RenderConfig renderConfig;

  /// Hit-tests the scene position against visible nodes and returns the parent
  /// node id if a parent node was hit; otherwise returns null.
  String? hitTestParentId(Offset scenePos) =>
      hitTestParentIdAt(scenePos, displayNodes, childrenByParent, renderConfig);

  /// Hit-tests any visible node (parent or child) and returns the node id if hit.
  String? hitTestNodeId(Offset scenePos) =>
      hitTestNodeIdAt(scenePos, displayNodes, childrenByParent, renderConfig);
}

String? hitTestParentIdAt(
  Offset scenePos,
  List<DisplayNode> displayNodes,
  Map<String, List<UyavaNode>> childrenByParent,
  RenderConfig renderConfig,
) {
  DisplayNode? hit;
  double bestDist2 = double.infinity;
  for (final DisplayNode dn in displayNodes) {
    final double dx = dn.position.dx - scenePos.dx;
    final double dy = dn.position.dy - scenePos.dy;
    final double dist2 = dx * dx + dy * dy;
    final bool isParent = childrenByParent.containsKey(dn.id);
    final double radius = isParent
        ? renderConfig.parentNodeRadius
        : renderConfig.childNodeRadius;
    if (dist2 <= radius * radius && dist2 < bestDist2) {
      bestDist2 = dist2;
      hit = dn;
    }
  }

  if (hit != null && childrenByParent.containsKey(hit.id)) {
    return hit.id;
  }
  return null;
}

String? hitTestNodeIdAt(
  Offset scenePos,
  List<DisplayNode> displayNodes,
  Map<String, List<UyavaNode>> childrenByParent,
  RenderConfig renderConfig,
) {
  DisplayNode? hit;
  double bestDist2 = double.infinity;
  for (final DisplayNode dn in displayNodes) {
    final double dx = dn.position.dx - scenePos.dx;
    final double dy = dn.position.dy - scenePos.dy;
    final double dist2 = dx * dx + dy * dy;
    final bool isParent = childrenByParent.containsKey(dn.id);
    final double radius = isParent
        ? renderConfig.parentNodeRadius
        : renderConfig.childNodeRadius;
    if (dist2 <= radius * radius && dist2 < bestDist2) {
      bestDist2 = dist2;
      hit = dn;
    }
  }
  return hit?.id;
}
