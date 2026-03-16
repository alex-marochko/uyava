import 'dart:math' as math;
import 'dart:ui' as ui show BlendMode, BlurStyle, MaskFilter;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import '../config.dart';
import '../display_node.dart';
import '../geometry.dart';
import '../policies/cloud_visibility_policy.dart';
import '../policies/edge_aggregation_policy.dart';
import '../theme.dart';

class GraphNodeLayer {
  GraphNodeLayer({
    required this.renderConfig,
    required this.edgePolicy,
    required this.cloudPolicy,
    required this.isParentId,
    required this.parentById,
    required this.uiForegroundColor,
    required this.focusColor,
  });

  final RenderConfig renderConfig;
  final EdgeAggregationPolicy edgePolicy;
  final CloudVisibilityPolicy cloudPolicy;
  final bool Function(String id) isParentId;
  final Map<String, String?> parentById;
  final Color uiForegroundColor;
  final Color focusColor;

  void paintClouds({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required Set<String> collapsedParents,
    required Map<String, double> collapseProgress,
    required double cloudGlobalOpacity,
    required Paint paint,
  }) {
    if (displayNodes.isEmpty) return;
    final Map<String?, List<DisplayNode>> groups =
        groupBy<DisplayNode, String?>(
          displayNodes,
          (DisplayNode node) => node.parentId,
        );

    for (final String? parentId in groups.keys) {
      if (parentId == null) continue;
      final double? localOpacity = cloudPolicy.cloudOpacity(parentId);
      double? opacity = localOpacity == null
          ? null
          : (localOpacity * cloudGlobalOpacity);
      if (opacity == null || opacity <= 0.0) continue;

      final DisplayNode? parentNode = displayNodes.firstWhereOrNull(
        (DisplayNode n) => n.id == parentId,
      );
      if (parentNode == null) continue;

      final List<DisplayNode> descendants = displayNodes.where((DisplayNode n) {
        if (n.id == parentId) return false;
        String? anc = n.parentId;
        while (anc != null) {
          if (anc == parentId) return true;
          anc = parentById[anc];
        }
        return false;
      }).toList();
      if (descendants.isEmpty) continue;

      if (parentNode.lifecycle == NodeLifecycle.unknown) {
        opacity *= renderConfig.uninitializedAlphaMultiplier;
      } else if (parentNode.lifecycle == NodeLifecycle.disposed) {
        opacity *= renderConfig.disposedAlphaMultiplier;
      }

      const int samples = 12;
      const double childMargin = 18.0;
      const double parentMargin = 20.0;
      final double childRadius = renderConfig.childNodeRadius;
      final double parentRadius = renderConfig.parentNodeRadius;
      final List<Offset> samplePoints = <Offset>[];

      for (final DisplayNode descendant in descendants) {
        final bool isParentNode = isParentId(descendant.id);
        final double base = isParentNode ? parentRadius : childRadius;
        final double margin = isParentNode ? parentMargin : childMargin;
        final double r = base + margin;
        for (int i = 0; i < samples; i++) {
          final double t = (i / samples) * 2 * math.pi;
          samplePoints.add(
            Offset(
              descendant.position.dx + r * math.cos(t),
              descendant.position.dy + r * math.sin(t),
            ),
          );
        }
      }

      final double r = parentRadius + parentMargin;
      for (int i = 0; i < samples; i++) {
        final double t = (i / samples) * 2 * math.pi;
        samplePoints.add(
          Offset(
            parentNode.position.dx + r * math.cos(t),
            parentNode.position.dy + r * math.sin(t),
          ),
        );
      }

      if (samplePoints.length < 3) continue;
      final List<Offset> hullPoints = convexHull(samplePoints);
      final Path path = createSmoothedPaddedPath(hullPoints, 0.0);

      final Color parentColor = resolveNodeColor(parentNode.node);
      final double alpha = (0.15 * opacity).clamp(0.0, 1.0);
      paint
        ..color = parentColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }
  }

  void paintNodeEvents({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required List<UyavaNodeEvent> nodeEvents,
  }) {
    if (nodeEvents.isEmpty) return;
    final Duration eventDuration = renderConfig.eventDuration;
    final DateTime now = DateTime.now();
    for (final UyavaNodeEvent ev in nodeEvents) {
      final String toId = edgePolicy.mapToVisibleAncestor(ev.nodeId);
      final DisplayNode? node = displayNodes.firstWhereOrNull(
        (DisplayNode n) => n.id == toId,
      );
      if (node == null) continue;
      final bool isParent = isParentId(node.id);
      final double baseRadius = isParent
          ? renderConfig.parentNodeRadius
          : renderConfig.childNodeRadius;
      final double t =
          now.difference(ev.timestamp).inMilliseconds /
          eventDuration.inMilliseconds;
      if (t < 0 || t > 1.0) continue;

      final double eased = renderConfig.ease.transform(t.clamp(0.0, 1.0));
      final double scale = 1.0 + (renderConfig.nodePulseMaxScale - 1.0) * eased;
      final double alpha = (1.0 - eased) * renderConfig.nodePulseAlpha;

      final Color baseColor = colorForSeverity(ev.severity);
      double pulseAlpha = alpha;
      if (node.lifecycle == NodeLifecycle.unknown) {
        pulseAlpha *= renderConfig.uninitializedAlphaMultiplier;
      } else if (node.lifecycle == NodeLifecycle.disposed) {
        pulseAlpha *= renderConfig.disposedAlphaMultiplier;
      }
      final bool emphasize =
          renderConfig.severityEmphasisEnabled &&
          severityMeets(ev.severity, renderConfig.severityEmphasisMinLevel);
      final double emphasizedScale = emphasize
          ? scale * renderConfig.severityNodePulseScale
          : scale;
      final Paint pulsePaint = Paint()
        ..color = baseColor.withValues(alpha: pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = renderConfig.nodePulseStrokeWidth;
      canvas.drawCircle(
        node.position,
        baseRadius * emphasizedScale,
        pulsePaint,
      );

      if (renderConfig.nodeFlashEnabled) {
        final int elapsedMs = now.difference(ev.timestamp).inMilliseconds;
        if (elapsedMs >= 0 &&
            elapsedMs <= renderConfig.nodeFlashDuration.inMilliseconds) {
          final Color nodeFill = resolveNodeColor(node.node);
          final bool useContrastAware =
              renderConfig.nodeFlashContrastAware &&
              _isLowContrast(
                baseColor.withValues(alpha: renderConfig.nodeFlashAlpha),
                nodeFill,
                renderConfig.nodeFlashMinContrast,
              );
          final Color invertedNode = _inverted(
            nodeFill,
            renderConfig.nodeFlashAlpha,
          );
          final Color flashColor = useContrastAware
              ? (renderConfig.nodeFlashInvertColor
                    ? invertedNode
                    : Colors.white.withValues(
                        alpha: renderConfig.nodeFlashAlpha,
                      ))
              : baseColor.withValues(alpha: renderConfig.nodeFlashAlpha);
          final ui.BlendMode flashBlend = useContrastAware
              ? (renderConfig.nodeFlashInvertColor
                    ? (renderConfig.nodeFlashAdditive
                          ? ui.BlendMode.plus
                          : ui.BlendMode.srcOver)
                    : ui.BlendMode.difference)
              : (renderConfig.nodeFlashAdditive
                    ? ui.BlendMode.plus
                    : ui.BlendMode.srcOver);
          final Paint flashPaint = Paint()
            ..color = flashColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = renderConfig.nodePulseStrokeWidth + 1.0
            ..blendMode = flashBlend;
          final double flashScale = scale + renderConfig.nodeFlashScaleBoost;
          canvas.drawCircle(node.position, baseRadius * flashScale, flashPaint);
        }
      }
    }
  }

  void paintNodes({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required Set<String> collapsedParents,
    required Map<String, double> collapseProgress,
    required Map<String, int> directChildCounts,
    required Paint paint,
  }) {
    for (final DisplayNode dNode in displayNodes) {
      final NodeStyle style = getStyleForType(dNode.type);
      final Color nodeFill = resolveNodeColor(dNode.node);
      double t = 0.0;
      String? activeAncestorId;
      String? ancestor = dNode.parentId;
      while (ancestor != null) {
        final double prog = collapseProgress[ancestor] ?? 0.0;
        if (prog > 0.0) {
          t = renderConfig.ease.transform(prog.clamp(0.0, 1.0));
          activeAncestorId = ancestor;
          break;
        }
        ancestor = parentById[ancestor];
      }

      double baseAlpha = 1.0 - renderConfig.nodeFadeFactor * t;
      final NodeLifecycle lifecycle = dNode.lifecycle;
      if (lifecycle == NodeLifecycle.unknown) {
        baseAlpha *= renderConfig.uninitializedAlphaMultiplier;
      } else if (lifecycle == NodeLifecycle.disposed) {
        baseAlpha *= renderConfig.disposedAlphaMultiplier;
      }
      final bool isParent = isParentId(dNode.id);
      final double baseRadius = isParent
          ? renderConfig.parentNodeRadius
          : renderConfig.childNodeRadius;
      final double radius =
          baseRadius * (1.0 - renderConfig.nodeRadiusShrinkFactor * t);

      Offset pos = dNode.position;
      if (t > 0.0 && activeAncestorId != null) {
        final DisplayNode? targetNode = displayNodes.firstWhereOrNull(
          (DisplayNode n) => n.id == activeAncestorId,
        );
        if (targetNode != null) {
          pos = Offset.lerp(dNode.position, targetNode.position, t)!;
        }
      }

      paint.color = nodeFill.withValues(alpha: baseAlpha);
      canvas.drawCircle(pos, radius, paint);
      _drawLifecycleBorder(canvas, pos, radius, lifecycle, baseAlpha, isParent);

      if (isParent && collapsedParents.contains(dNode.id)) {
        final int count = directChildCounts[dNode.id] ?? 0;
        final String badgeText = count.toString();
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: badgeText,
            style: TextStyle(
              color: Colors.black.withValues(alpha: baseAlpha),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        const double badgePadding = 4.0;
        final Size badgeSize = Size(
          textPainter.width + badgePadding * 2,
          textPainter.height + badgePadding * 2,
        );
        final Offset badgeOffset = Offset(
          pos.dx + radius - badgeSize.width * 0.6,
          pos.dy - radius,
        );

        final RRect rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            badgeOffset.dx,
            badgeOffset.dy,
            badgeSize.width,
            badgeSize.height,
          ),
          const Radius.circular(8),
        );
        final Paint badgePaint = Paint()
          ..color = Colors.white.withValues(alpha: baseAlpha)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(rrect, badgePaint);
        textPainter.paint(
          canvas,
          Offset(
            badgeOffset.dx + (badgeSize.width - textPainter.width) / 2,
            badgeOffset.dy + (badgeSize.height - textPainter.height) / 2,
          ),
        );
      }

      final TextPainter iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(style.icon.codePoint),
          style: TextStyle(
            color: uiForegroundColor.withValues(alpha: baseAlpha),
            fontSize: isParent ? 22 : 18,
            fontFamily: style.icon.fontFamily,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset iconPosition = Offset(
        pos.dx - iconPainter.width / 2,
        pos.dy - iconPainter.height / 2,
      );
      iconPainter.paint(canvas, iconPosition);

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: dNode.label,
          style: TextStyle(
            color: uiForegroundColor.withValues(alpha: baseAlpha),
            fontSize: 10,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset labelPosition = Offset(
        pos.dx - labelPainter.width / 2,
        pos.dy + (isParent ? 25 : 20),
      );
      labelPainter.paint(canvas, labelPosition);
    }
  }

  void paintHoverHighlights({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required Set<String> highlightedNodeIds,
    required String? hoveredNodeId,
  }) {
    for (final String nodeId in highlightedNodeIds) {
      final DisplayNode? node = displayNodes.firstWhereOrNull(
        (DisplayNode d) => d.id == nodeId,
      );
      if (node != null) {
        _drawNodeGlow(canvas, node);
      }
    }

    if (hoveredNodeId != null) {
      final DisplayNode? node = displayNodes.firstWhereOrNull(
        (DisplayNode d) => d.id == hoveredNodeId,
      );
      if (node != null) {
        final bool isParent = isParentId(node.id);
        final double radius = isParent
            ? renderConfig.parentNodeRadius
            : renderConfig.childNodeRadius;
        final Paint stroke = Paint()
          ..color = uiForegroundColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(node.position, radius + 4.0, stroke);
      }
    }
  }

  void paintFocusedNodes({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required Set<String> focusedNodeIds,
  }) {
    if (focusedNodeIds.isEmpty) return;
    final Paint glowPaint = Paint()
      ..color = focusColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.outer, 14);
    final Paint ringPaint = Paint()
      ..color = focusColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    for (final DisplayNode node in displayNodes) {
      if (!focusedNodeIds.contains(node.id)) continue;
      final bool isParent = isParentId(node.id);
      final double baseRadius = isParent
          ? renderConfig.parentNodeRadius
          : renderConfig.childNodeRadius;
      final double ringRadius = baseRadius + 4;
      canvas.drawCircle(node.position, ringRadius + 5, glowPaint);
      canvas.drawCircle(node.position, ringRadius, ringPaint);
    }
  }

  void _drawNodeGlow(Canvas canvas, DisplayNode node) {
    final bool isParent = isParentId(node.id);
    final double radius = isParent
        ? renderConfig.parentNodeRadius
        : renderConfig.childNodeRadius;
    final Paint glowPaint = Paint()
      ..color = uiForegroundColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.outer, 12);
    canvas.drawCircle(node.position, radius + 8.0, glowPaint);

    final Paint ringPaint = Paint()
      ..color = uiForegroundColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(node.position, radius + 5.0, ringPaint);
  }

  void _drawLifecycleBorder(
    Canvas canvas,
    Offset center,
    double radius,
    NodeLifecycle lifecycle,
    double alpha,
    bool isParent,
  ) {
    final double strokeWidth = isParent ? 2.0 : 1.5;
    final Color color = uiForegroundColor.withValues(alpha: alpha);
    switch (lifecycle) {
      case NodeLifecycle.initialized:
        final Paint paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(center, radius, paint);
        break;
      case NodeLifecycle.unknown:
        _drawDashedCircle(
          canvas,
          center,
          radius,
          dash: 24.0,
          gap: 3.0,
          color: color,
          strokeWidth: strokeWidth,
        );
        break;
      case NodeLifecycle.disposed:
        _drawDottedCircle(
          canvas,
          center,
          radius,
          dots: 18,
          color: color,
          dotRadius: strokeWidth * 0.75,
        );
        break;
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius, {
    required double dash,
    required double gap,
    required Color color,
    required double strokeWidth,
  }) {
    final double circumference = 2 * math.pi * radius;
    final double dashFrac = dash / circumference;
    final double gapFrac = gap / circumference;
    final double step = (dashFrac + gapFrac) * 2 * math.pi;
    final double sweep = dashFrac * 2 * math.pi;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    for (double a = 0; a < 2 * math.pi; a += step) {
      final double rem = 2 * math.pi - a;
      final double actualSweep = math.min(rem, sweep);
      if (actualSweep <= 0) break;
      canvas.drawArc(rect, a, actualSweep, false, paint);
    }
  }

  void _drawDottedCircle(
    Canvas canvas,
    Offset center,
    double radius, {
    required int dots,
    required Color color,
    required double dotRadius,
  }) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final int count = dots.clamp(8, 48);
    for (int i = 0; i < count; i++) {
      final double a = (i / count) * 2 * math.pi;
      final Offset p = Offset(
        center.dx + radius * math.cos(a),
        center.dy + radius * math.sin(a),
      );
      canvas.drawCircle(p, dotRadius, paint);
    }
  }

  bool _isLowContrast(Color a, Color b, double minRatio) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double l1 = math.max(la, lb);
    final double l2 = math.min(la, lb);
    final double ratio = (l1 + 0.05) / (l2 + 0.05);
    return ratio < minRatio;
  }

  Color _inverted(Color base, double alpha) {
    int ch(double v) => math.max(0, math.min(255, (v * 255.0).round()));
    final int r = 0xFF - ch(base.r);
    final int g = 0xFF - ch(base.g);
    final int b = 0xFF - ch(base.b);
    return Color.fromARGB(0xFF, r, g, b).withValues(alpha: alpha);
  }
}
