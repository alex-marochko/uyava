import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import '../config.dart';
import '../display_node.dart';
import '../theme.dart';

class GraphBadgeLayer {
  GraphBadgeLayer({
    required this.renderConfig,
    required this.isParentId,
    required this.uiForegroundColor,
  });

  final RenderConfig renderConfig;
  final bool Function(String id) isParentId;
  final Color uiForegroundColor;

  void paintEventQueueBadges({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required Map<String, int> eventQueueLabels,
    required Map<String, double> eventQueueLabelAlphas,
    required Map<String, UyavaSeverity?> eventQueueLabelSeverities,
  }) {
    if (eventQueueLabels.isEmpty) return;
    final int minToShow = renderConfig.queueLabelMinCountToShow;
    final TextStyle textStyle = TextStyle(
      color: uiForegroundColor,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    for (final MapEntry<String, int> entry in eventQueueLabels.entries) {
      final int count = entry.value;
      if (count < minToShow) continue;
      final int sep = entry.key.indexOf('->');
      if (sep <= 0) continue;
      final String srcId = entry.key.substring(0, sep);
      final String dstId = entry.key.substring(sep + 2);
      final DisplayNode? source = displayNodes.firstWhereOrNull(
        (DisplayNode n) => n.id == srcId,
      );
      final DisplayNode? target = displayNodes.firstWhereOrNull(
        (DisplayNode n) => n.id == dstId,
      );
      if (source == null || target == null) continue;

      final Offset dir = (target.position - source.position);
      final double dist = dir.distance;
      if (dist == 0) continue;
      final Offset unit = dir / dist;
      final bool isParent = isParentId(source.id);
      final double baseRadius = isParent
          ? renderConfig.parentNodeRadius
          : renderConfig.childNodeRadius;
      final double requiredSpace =
          baseRadius +
          renderConfig.edgeArrowLength +
          renderConfig.queueLabelOffset +
          renderConfig.queueLabelRadius +
          2.0;
      if (dist <= requiredSpace) continue;

      final Offset baseCenter = source.position + unit * baseRadius;
      final Offset tip = baseCenter + unit * renderConfig.edgeArrowLength;
      final Offset center = tip + unit * renderConfig.queueLabelOffset;

      final double alpha = (eventQueueLabelAlphas[entry.key] ?? 1.0).clamp(
        0.0,
        1.0,
      );
      Color base = Colors.white;
      if (renderConfig.badgeTintBySeverity) {
        final UyavaSeverity? sev = eventQueueLabelSeverities[entry.key];
        if (sev != null) base = colorForSeverity(sev);
      }
      final Color color = base.withValues(alpha: alpha);
      canvas.drawCircle(
        center,
        renderConfig.queueLabelRadius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      final String capped = count > renderConfig.queueLabelMaxCount
          ? '${renderConfig.queueLabelMaxCount}+'
          : '$count';
      final Color baseTextColor =
          (renderConfig.badgeTintBySeverity && base != Colors.white)
          ? Colors.white
          : Colors.black;
      final Color fadedTextColor = baseTextColor.withValues(alpha: alpha);
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: capped,
          style: textStyle.copyWith(color: fadedTextColor),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
      );
    }
  }

  void paintNodeEventBadges({
    required Canvas canvas,
    required List<DisplayNode> displayNodes,
    required Map<String, int> nodeEventBadgeLabels,
    required Map<String, double> nodeEventBadgeAlphas,
    required Map<String, UyavaSeverity?> nodeEventBadgeSeverities,
  }) {
    if (!renderConfig.nodeEventBadgeEnabled) return;
    if (nodeEventBadgeLabels.isEmpty) return;
    const double badgePadding = 4.0;
    const double borderRadius = 8.0;
    final TextStyle textStyle = TextStyle(
      color: uiForegroundColor,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    for (final MapEntry<String, int> entry in nodeEventBadgeLabels.entries) {
      final String nodeId = entry.key;
      final int count = entry.value;
      if (count < renderConfig.queueLabelMinCountToShow) continue;
      final DisplayNode? dNode = displayNodes.firstWhereOrNull(
        (DisplayNode n) => n.id == nodeId,
      );
      if (dNode == null) continue;
      final bool isParent = isParentId(dNode.id);
      final double baseRadius = isParent
          ? renderConfig.parentNodeRadius
          : renderConfig.childNodeRadius;

      final double alpha = (nodeEventBadgeAlphas[nodeId] ?? 1.0).clamp(
        0.0,
        1.0,
      );
      Color bg = Colors.white;
      if (renderConfig.badgeTintBySeverity) {
        final UyavaSeverity? sev = nodeEventBadgeSeverities[nodeId];
        if (sev != null) bg = colorForSeverity(sev);
      }
      final Color bgColor = bg.withValues(alpha: alpha);
      final Color baseTextColor =
          (renderConfig.badgeTintBySeverity && bg != Colors.white)
          ? Colors.white
          : Colors.black;
      final Color textColor = baseTextColor.withValues(alpha: alpha);

      final String text = count > renderConfig.queueLabelMaxCount
          ? '${renderConfig.queueLabelMaxCount}+'
          : '$count';
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(color: textColor),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final Size size = Size(
        tp.width + badgePadding * 2,
        tp.height + badgePadding * 2,
      );

      final Offset pos = dNode.position;
      final bool leftSide = renderConfig.nodeEventBadgeLeftSide;
      final double dx = leftSide
          ? pos.dx - baseRadius - size.width * 0.4
          : pos.dx + baseRadius - size.width * 0.6;
      final double dy = pos.dy - baseRadius;
      final Rect rect = Rect.fromLTWH(dx, dy, size.width, size.height);
      final RRect rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(borderRadius),
      );

      final Paint paint = Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, paint);
      tp.paint(
        canvas,
        Offset(
          dx + (size.width - tp.width) / 2,
          dy + (size.height - tp.height) / 2,
        ),
      );
    }
  }
}
