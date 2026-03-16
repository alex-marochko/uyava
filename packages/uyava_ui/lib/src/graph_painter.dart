import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import 'config.dart';
import 'display_node.dart';
import 'highlight.dart';
import 'layers/badge_layer.dart';
import 'layers/edge_layer.dart';
import 'layers/node_layer.dart';
import 'policies/cloud_visibility_policy.dart';
import 'policies/edge_aggregation_policy.dart';

export 'display_node.dart';

class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.displayNodes,
    required this.edges,
    required this.events,
    required this.nodeEvents,
    required this.collapsedParents,
    required this.collapseProgress,
    required this.directChildCounts,
    required this.isParentId,
    required this.parentById,
    required this.edgePolicy,
    required this.cloudPolicy,
    required this.renderConfig,
    this.edgeGlobalOpacity = 1.0,
    this.cloudGlobalOpacity = 1.0,
    this.eventQueueLabels = const {},
    this.eventQueueLabelAlphas = const {},
    this.eventQueueLabelSeverities = const <String, UyavaSeverity?>{},
    this.nodeEventBadgeLabels = const {},
    this.nodeEventBadgeAlphas = const {},
    this.nodeEventBadgeSeverities = const <String, UyavaSeverity?>{},
    this.uiForegroundColor = Colors.white,
    this.hoveredNodeId,
    this.hoveredEdgeId,
    this.highlightedNodeIds = const <String>{},
    this.highlightedEdges = const <GraphHighlightEdge>{},
    this.focusedNodeIds = const <String>{},
    this.focusedEdgeIds = const <String>{},
    this.focusColor = const Color(0xFF64B5F6),
  }) : _nodeLayer = GraphNodeLayer(
         renderConfig: renderConfig,
         edgePolicy: edgePolicy,
         cloudPolicy: cloudPolicy,
         isParentId: isParentId,
         parentById: parentById,
         uiForegroundColor: uiForegroundColor,
         focusColor: focusColor,
       ),
       _edgeLayer = GraphEdgeLayer(
         renderConfig: renderConfig,
         edgePolicy: edgePolicy,
         isParentId: isParentId,
         uiForegroundColor: uiForegroundColor,
       ),
       _badgeLayer = GraphBadgeLayer(
         renderConfig: renderConfig,
         isParentId: isParentId,
         uiForegroundColor: uiForegroundColor,
       );

  final GraphNodeLayer _nodeLayer;
  final GraphEdgeLayer _edgeLayer;
  final GraphBadgeLayer _badgeLayer;

  final List<DisplayNode> displayNodes;
  final List<UyavaEdge> edges;
  final List<UyavaEvent> events;
  final List<UyavaNodeEvent> nodeEvents;
  final Set<String> collapsedParents;
  final Map<String, double> collapseProgress;
  final Map<String, int> directChildCounts;
  final bool Function(String id) isParentId;
  final Map<String, String?> parentById;
  final EdgeAggregationPolicy edgePolicy;
  final CloudVisibilityPolicy cloudPolicy;
  final RenderConfig renderConfig;
  final double edgeGlobalOpacity;
  final double cloudGlobalOpacity;
  final Map<String, int> eventQueueLabels;
  final Map<String, double> eventQueueLabelAlphas;
  final Map<String, UyavaSeverity?> eventQueueLabelSeverities;
  final Map<String, int> nodeEventBadgeLabels;
  final Map<String, double> nodeEventBadgeAlphas;
  final Map<String, UyavaSeverity?> nodeEventBadgeSeverities;
  final Color uiForegroundColor;
  final String? hoveredNodeId;
  final String? hoveredEdgeId;
  final Set<String> highlightedNodeIds;
  final Set<GraphHighlightEdge> highlightedEdges;
  final Set<String> focusedNodeIds;
  final Set<String> focusedEdgeIds;
  final Color focusColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint nodePaint = Paint()..style = PaintingStyle.fill;
    final Paint edgePaint = Paint()
      ..color = uiForegroundColor
      ..strokeWidth = 1.5;
    final Paint cloudPaint = Paint();

    _nodeLayer.paintClouds(
      canvas: canvas,
      displayNodes: displayNodes,
      collapsedParents: collapsedParents,
      collapseProgress: collapseProgress,
      cloudGlobalOpacity: cloudGlobalOpacity,
      paint: cloudPaint,
    );
    _edgeLayer.paintEdges(
      canvas: canvas,
      displayNodes: displayNodes,
      edges: edges,
      hoveredEdgeId: hoveredEdgeId,
      highlightedEdges: highlightedEdges,
      edgeGlobalOpacity: edgeGlobalOpacity,
      paint: edgePaint,
    );
    _edgeLayer.paintFocusedEdges(
      canvas: canvas,
      displayNodes: displayNodes,
      edges: edges,
      focusedEdgeIds: focusedEdgeIds,
      focusColor: focusColor,
    );
    _edgeLayer.paintEvents(
      canvas: canvas,
      displayNodes: displayNodes,
      events: events,
      collapsedParents: collapsedParents,
      collapseProgress: collapseProgress,
    );
    _nodeLayer.paintNodeEvents(
      canvas: canvas,
      displayNodes: displayNodes,
      nodeEvents: nodeEvents,
    );
    _nodeLayer.paintNodes(
      canvas: canvas,
      displayNodes: displayNodes,
      collapsedParents: collapsedParents,
      collapseProgress: collapseProgress,
      directChildCounts: directChildCounts,
      paint: nodePaint,
    );
    _nodeLayer.paintHoverHighlights(
      canvas: canvas,
      displayNodes: displayNodes,
      highlightedNodeIds: highlightedNodeIds,
      hoveredNodeId: hoveredNodeId,
    );
    _nodeLayer.paintFocusedNodes(
      canvas: canvas,
      displayNodes: displayNodes,
      focusedNodeIds: focusedNodeIds,
    );
    _badgeLayer.paintNodeEventBadges(
      canvas: canvas,
      displayNodes: displayNodes,
      nodeEventBadgeLabels: nodeEventBadgeLabels,
      nodeEventBadgeAlphas: nodeEventBadgeAlphas,
      nodeEventBadgeSeverities: nodeEventBadgeSeverities,
    );
    _badgeLayer.paintEventQueueBadges(
      canvas: canvas,
      displayNodes: displayNodes,
      eventQueueLabels: eventQueueLabels,
      eventQueueLabelAlphas: eventQueueLabelAlphas,
      eventQueueLabelSeverities: eventQueueLabelSeverities,
    );
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}
