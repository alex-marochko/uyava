import 'dart:math' as math;
import 'dart:ui' as ui show BlurStyle, MaskFilter;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import '../display_node.dart';
import '../highlight.dart';
import '../policies/edge_aggregation_policy.dart';
import '../theme.dart';
import '../config.dart';

class GraphEdgeLayer {
  GraphEdgeLayer({
    required this.renderConfig,
    required this.edgePolicy,
    required this.isParentId,
    required this.uiForegroundColor,
  });

  final RenderConfig renderConfig;
  final EdgeAggregationPolicy edgePolicy;
  final bool Function(String id) isParentId;
  final Color uiForegroundColor;

  void paintEdges({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required List<UyavaEdge> edges,
    required String? hoveredEdgeId,
    required Set<GraphHighlightEdge> highlightedEdges,
    required double edgeGlobalOpacity,
    required Paint paint,
  }) {
    final Set<String> drawnPairs = <String>{};
    final Map<String, _EdgeHighlightData> highlightSegments =
        <String, _EdgeHighlightData>{};
    final Set<String> highlightedKeys = highlightedEdges
        .map((edge) => '${edge.sourceId}->${edge.targetId}')
        .toSet();

    for (final edge in edges) {
      final List<String> pairKeyList = [edge.source, edge.target]..sort();
      final String pairKey = pairKeyList.join('-');
      if (drawnPairs.contains(pairKey)) continue;

      final DisplayNode? sourceNode = displayNodes.firstWhereOrNull(
        (n) => n.id == edge.source,
      );
      final DisplayNode? targetNode = displayNodes.firstWhereOrNull(
        (n) => n.id == edge.target,
      );
      if (sourceNode == null || targetNode == null) continue;

      drawnPairs.add(pairKey);
      final bool remapped = (edge.data['remapped'] == true);
      final bool bidirectional = (edge.data['bidirectional'] == true);
      final double fade = edgePolicy.edgeFade(
        remapped: remapped,
        sourceId: sourceNode.id,
        targetId: targetNode.id,
      );
      final Color edgeColor = paint.color.withValues(
        alpha: renderConfig.edgeStrokeAlpha * fade * edgeGlobalOpacity,
      );
      final Paint linePaint = Paint()
        ..color = edgeColor
        ..strokeWidth = paint.strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawLine(sourceNode.position, targetNode.position, linePaint);
      if (renderConfig.edgeArrowsEnabled) {
        _drawArrowAtSource(canvas, sourceNode, targetNode, edgeColor);
        if (bidirectional) {
          _drawArrowAtSource(canvas, targetNode, sourceNode, edgeColor);
        }
      }

      final bool isHovered = edge.id == hoveredEdgeId;
      final bool isHighlighted =
          highlightedKeys.contains('${sourceNode.id}->${targetNode.id}') ||
          highlightedKeys.contains('${targetNode.id}->${sourceNode.id}');
      if (!isHovered && !isHighlighted) continue;

      final String segmentKey = '${sourceNode.id}->${targetNode.id}';
      final _EdgeHighlightData segment = highlightSegments.putIfAbsent(
        segmentKey,
        () => _EdgeHighlightData(
          source: sourceNode,
          target: targetNode,
          bidirectional: bidirectional,
          remapped: remapped,
        ),
      );
      if (isHovered) segment.hovered = true;
      if (isHighlighted) segment.highlighted = true;
    }

    if (highlightSegments.isEmpty) return;
    final double baseStrokeWidth = paint.strokeWidth * 1.6;
    for (final _EdgeHighlightData segment in highlightSegments.values) {
      final bool highlight = segment.highlighted;
      final bool hovered = segment.hovered;
      final double alphaMultiplier = highlight
          ? math.min(1.0, edgeGlobalOpacity + 0.4)
          : segment.remapped
          ? 0.95
          : math.min(1.0, edgeGlobalOpacity + 0.25);
      final Color color = uiForegroundColor.withValues(alpha: alphaMultiplier);

      if (highlight) {
        final Paint glowPaint = Paint()
          ..color = color.withValues(
            alpha: (alphaMultiplier * 0.55).clamp(0.0, 1.0),
          )
          ..strokeWidth = baseStrokeWidth * 3
          ..style = PaintingStyle.stroke
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
        canvas.drawLine(
          segment.source.position,
          segment.target.position,
          glowPaint,
        );
        if (renderConfig.edgeArrowsEnabled) {
          _drawArrowGlow(canvas, segment.source, segment.target, glowPaint);
          if (segment.bidirectional) {
            _drawArrowGlow(canvas, segment.target, segment.source, glowPaint);
          }
        }
      }

      final double strokeWidth = highlight
          ? baseStrokeWidth * 1.4
          : baseStrokeWidth;
      final Paint overlayPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        segment.source.position,
        segment.target.position,
        overlayPaint,
      );
      if (renderConfig.edgeArrowsEnabled) {
        _drawArrowAtSource(canvas, segment.source, segment.target, color);
        if (segment.bidirectional) {
          _drawArrowAtSource(canvas, segment.target, segment.source, color);
        }
      }

      if (hovered && highlight) {
        final Paint outline = Paint()
          ..color = uiForegroundColor.withValues(alpha: 0.7)
          ..strokeWidth = strokeWidth * 0.6
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          segment.source.position,
          segment.target.position,
          outline,
        );
      }
    }
  }

  void paintFocusedEdges({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required List<UyavaEdge> edges,
    required Set<String> focusedEdgeIds,
    required Color focusColor,
  }) {
    if (focusedEdgeIds.isEmpty) return;
    final Map<String, DisplayNode> nodesById = {
      for (final DisplayNode node in displayNodes) node.id: node,
    };
    final Paint glowPaint = Paint()
      ..color = focusColor.withValues(alpha: 0.4)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.outer, 12);
    final Paint strokePaint = Paint()
      ..color = focusColor.withValues(alpha: 0.9)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    for (final UyavaEdge edge in edges) {
      if (!focusedEdgeIds.contains(edge.id)) continue;
      final DisplayNode? source = nodesById[edge.source];
      final DisplayNode? target = nodesById[edge.target];
      if (source == null || target == null) continue;
      canvas.drawLine(source.position, target.position, glowPaint);
      canvas.drawLine(source.position, target.position, strokePaint);
    }
  }

  void paintEvents({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required List<UyavaEvent> events,
    required Set<String> collapsedParents,
    required Map<String, double> collapseProgress,
  }) {
    final Duration eventDuration = renderConfig.eventDuration;
    final DateTime now = DateTime.now();
    for (final UyavaEvent event in events) {
      final String fromId = edgePolicy.mapToVisibleAncestor(event.from);
      final String toId = edgePolicy.mapToVisibleAncestor(event.to);
      if (fromId == toId) {
        if (isParentId(fromId) &&
            (collapsedParents.contains(fromId) ||
                (collapseProgress[fromId] ?? 0.0) > 0.0)) {
          final DisplayNode? parentNode = displayNodes.firstWhereOrNull(
            (n) => n.id == fromId,
          );
          if (parentNode != null) {
            final double t =
                now.difference(event.timestamp).inMilliseconds /
                eventDuration.inMilliseconds;
            if (t >= 0 && t <= 1.0) {
              final double eased = renderConfig.ease.transform(
                t.clamp(0.0, 1.0),
              );
              final double scale =
                  1.0 + (renderConfig.nodePulseMaxScale - 1.0) * eased;
              double alpha = (1.0 - eased) * renderConfig.nodePulseAlpha;
              if (parentNode.lifecycle == NodeLifecycle.unknown) {
                alpha *= renderConfig.uninitializedAlphaMultiplier;
              } else if (parentNode.lifecycle == NodeLifecycle.disposed) {
                alpha *= renderConfig.disposedAlphaMultiplier;
              }
              final bool emphasize =
                  renderConfig.severityEmphasisEnabled &&
                  severityMeets(
                    event.severity,
                    renderConfig.severityEmphasisMinLevel,
                  );
              final double pulseScale = emphasize
                  ? scale * renderConfig.severityNodePulseScale
                  : scale;
              final Color baseColor = colorForSeverity(event.severity);
              final Paint pulsePaint = Paint()
                ..color = baseColor.withValues(alpha: alpha)
                ..style = PaintingStyle.stroke
                ..strokeWidth = renderConfig.nodePulseStrokeWidth;
              canvas.drawCircle(
                parentNode.position,
                renderConfig.parentNodeRadius * pulseScale,
                pulsePaint,
              );
            }
          }
        }
        continue;
      }

      final DisplayNode? fromNode = displayNodes.firstWhereOrNull(
        (n) => n.id == fromId,
      );
      final DisplayNode? toNode = displayNodes.firstWhereOrNull(
        (n) => n.id == toId,
      );
      if (fromNode == null || toNode == null) continue;

      final Offset from = fromNode.position;
      final Offset to = toNode.position;
      final Offset dir = (to - from);
      final double dist = dir.distance;
      if (dist == 0.0) continue;
      final Offset unit = dir / dist;
      final bool isParent = isParentId(fromNode.id);
      final double baseRadius = isParent
          ? renderConfig.parentNodeRadius
          : renderConfig.childNodeRadius;
      final Offset start = from + unit * baseRadius;
      final Offset end =
          to -
          unit *
              (isParentId(toNode.id)
                  ? renderConfig.parentNodeRadius
                  : renderConfig.childNodeRadius);

      final double progress =
          now.difference(event.timestamp).inMilliseconds /
          eventDuration.inMilliseconds;
      if (progress < 0.0 || progress > 1.0) continue;
      final Offset eventPosition = Offset.lerp(start, end, progress)!;
      final Color color = colorForSeverity(event.severity);
      final Paint localPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final bool emphasize =
          renderConfig.severityEmphasisEnabled &&
          severityMeets(event.severity, renderConfig.severityEmphasisMinLevel);
      final double dotRadius = emphasize
          ? renderConfig.eventDotRadius * renderConfig.severityEdgeDotScale
          : renderConfig.eventDotRadius;
      canvas.drawCircle(eventPosition, dotRadius, localPaint);
    }
  }

  void _drawArrowAtSource(
    Canvas canvas,
    DisplayNode source,
    DisplayNode target,
    Color color,
  ) {
    final Offset dir = (target.position - source.position);
    final double dist = dir.distance;
    if (dist == 0) return;
    final Offset unit = dir / dist;
    final bool isParent = isParentId(source.id);
    final double baseRadius = isParent
        ? renderConfig.parentNodeRadius
        : renderConfig.childNodeRadius;
    final Offset baseCenter = source.position + unit * baseRadius;
    final Offset perp = Offset(-unit.dy, unit.dx);
    final double halfBase = renderConfig.edgeArrowBaseWidth / 2.0;
    final Offset p0 = baseCenter + perp * halfBase;
    final Offset p1 = baseCenter - perp * halfBase;
    final Offset tip = baseCenter + unit * renderConfig.edgeArrowLength;

    final Path path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawArrowGlow(
    Canvas canvas,
    DisplayNode source,
    DisplayNode target,
    Paint paint,
  ) {
    if (paint.maskFilter == null) return;
    final Offset dir = (target.position - source.position);
    final double dist = dir.distance;
    if (dist == 0) return;
    final Offset unit = dir / dist;
    final bool isParent = isParentId(source.id);
    final double baseRadius = isParent
        ? renderConfig.parentNodeRadius
        : renderConfig.childNodeRadius;
    final Offset baseCenter = source.position + unit * baseRadius;
    final Offset glowEnd =
        baseCenter + unit * (renderConfig.edgeArrowLength * 0.75);
    canvas.drawLine(baseCenter, glowEnd, paint);
  }
}

class _EdgeHighlightData {
  _EdgeHighlightData({
    required this.source,
    required this.target,
    required this.bidirectional,
    required this.remapped,
  });

  final DisplayNode source;
  final DisplayNode target;
  final bool bidirectional;
  final bool remapped;
  bool hovered = false;
  bool highlighted = false;
}
