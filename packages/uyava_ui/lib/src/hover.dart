import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import 'config.dart';
import 'graph_painter.dart';

/// Represents the type of element currently hovered within the graph.
enum GraphHoverTargetKind { node, edge }

/// Describes the hovered element (node or edge) along with convenient access
/// to the underlying data needed for tooltips or highlight overlays.
class GraphHoverTarget {
  GraphHoverTarget.node(this.node)
    : kind = GraphHoverTargetKind.node,
      edge = null,
      sourceNode = null,
      targetNode = null;

  GraphHoverTarget.edge({
    required this.edge,
    required DisplayNode source,
    required DisplayNode target,
  }) : kind = GraphHoverTargetKind.edge,
       node = null,
       sourceNode = source,
       targetNode = target;

  final GraphHoverTargetKind kind;
  final DisplayNode? node;
  final UyavaEdge? edge;
  final DisplayNode? sourceNode;
  final DisplayNode? targetNode;

  String get id => kind == GraphHoverTargetKind.node ? node!.id : edge!.id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GraphHoverTarget) return false;
    return kind == other.kind && id == other.id;
  }

  @override
  int get hashCode => Object.hash(kind, id);
}

/// Combined hover details including the resolved element and cursor position
/// in both viewport and scene coordinates.
class GraphHoverDetails {
  const GraphHoverDetails({
    required this.target,
    required this.viewportPosition,
    required this.scenePosition,
  });

  final GraphHoverTarget target;
  final Offset viewportPosition;
  final Offset scenePosition;
}

typedef GraphHoverTooltipBuilder =
    Widget Function(BuildContext context, GraphHoverDetails details);

/// Attempts to resolve a hover target at the given scene-space position.
///
/// Nodes are preferred over edges when the pointer is within both hit regions.
GraphHoverTarget? resolveGraphHoverTarget({
  required Offset scenePosition,
  required List<DisplayNode> displayNodes,
  required Map<String, List<UyavaNode>> childrenByParent,
  required List<UyavaEdge> edges,
  required RenderConfig renderConfig,
  double nodeRadiusPadding = 4.0,
  double edgeHitRadius = 12.0,
}) {
  DisplayNode? bestNode;
  double bestNodeDist2 = double.infinity;
  for (final node in displayNodes) {
    final bool isParent = childrenByParent.containsKey(node.id);
    final double radius =
        (isParent
            ? renderConfig.parentNodeRadius
            : renderConfig.childNodeRadius) +
        nodeRadiusPadding;
    final double dx = node.position.dx - scenePosition.dx;
    final double dy = node.position.dy - scenePosition.dy;
    final double dist2 = dx * dx + dy * dy;
    if (dist2 <= radius * radius && dist2 < bestNodeDist2) {
      bestNode = node;
      bestNodeDist2 = dist2;
    }
  }
  if (bestNode != null) {
    return GraphHoverTarget.node(bestNode);
  }

  if (edges.isEmpty) return null;
  final Map<String, DisplayNode> nodesById = {
    for (final node in displayNodes) node.id: node,
  };

  GraphHoverTarget? bestEdge;
  double bestEdgeDistance = edgeHitRadius;
  for (final edge in edges) {
    final DisplayNode? source = nodesById[edge.source];
    final DisplayNode? target = nodesById[edge.target];
    if (source == null || target == null) continue;
    final double distance = _distanceToSegment(
      scenePosition,
      source.position,
      target.position,
    );
    if (distance <= bestEdgeDistance) {
      bestEdgeDistance = distance;
      bestEdge = GraphHoverTarget.edge(
        edge: edge,
        source: source,
        target: target,
      );
    }
  }
  return bestEdge;
}

double _distanceToSegment(Offset point, Offset a, Offset b) {
  final double dx = b.dx - a.dx;
  final double dy = b.dy - a.dy;
  final double lengthSq = dx * dx + dy * dy;
  if (lengthSq == 0) {
    return (point - a).distance;
  }
  final double tRaw =
      ((point.dx - a.dx) * dx + (point.dy - a.dy) * dy) / lengthSq;
  if (tRaw < 0.0 || tRaw > 1.0) {
    final double distA = (point - a).distance;
    final double distB = (point - b).distance;
    return math.min(distA, distB);
  }
  final Offset projection = Offset(a.dx + dx * tRaw, a.dy + dy * tRaw);
  return (point - projection).distance;
}

/// Overlay widget rendering a tooltip near the current pointer position.
class GraphHoverOverlay extends StatelessWidget {
  const GraphHoverOverlay({
    super.key,
    required this.details,
    required this.viewportSize,
    this.builder,
    this.maxWidth = 280,
    this.viewportPadding = const EdgeInsets.all(12),
    this.pointerOffset = const Offset(16, 16),
    this.anchorOffset = const Offset(18, -18),
    this.anchorViewportPosition,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.elevation = 8,
  });

  final GraphHoverDetails? details;
  final Size viewportSize;
  final GraphHoverTooltipBuilder? builder;
  final double maxWidth;
  final EdgeInsets viewportPadding;
  final Offset pointerOffset;
  final Offset anchorOffset;
  final Offset? anchorViewportPosition;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final GraphHoverDetails? hoverDetails = details;
    if (hoverDetails == null) {
      return const SizedBox.shrink();
    }
    final Widget content =
        builder?.call(context, hoverDetails) ??
        _DefaultHoverTooltip(details: hoverDetails);
    final bool hasAnchor = anchorViewportPosition != null;
    final Offset base = hasAnchor
        ? anchorViewportPosition!
        : hoverDetails.viewportPosition;
    final Offset offset = hasAnchor ? anchorOffset : pointerOffset;
    return Positioned.fill(
      child: IgnorePointer(
        child: _GraphHoverTooltipPositioner(
          base: base,
          offset: offset,
          viewportPadding: viewportPadding,
          maxWidth: maxWidth,
          viewportSize: viewportSize,
          child: _TooltipChrome(
            padding: padding,
            borderRadius: borderRadius,
            elevation: elevation,
            backgroundColor: backgroundColor,
            child: content,
          ),
        ),
      ),
    );
  }
}

class _GraphHoverTooltipPositioner extends StatelessWidget {
  const _GraphHoverTooltipPositioner({
    required this.base,
    required this.offset,
    required this.viewportPadding,
    required this.maxWidth,
    required this.viewportSize,
    required this.child,
  });

  final Offset base;
  final Offset offset;
  final EdgeInsets viewportPadding;
  final double maxWidth;
  final Size viewportSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: _GraphHoverTooltipLayoutDelegate(
        base: base,
        offset: offset,
        viewportPadding: viewportPadding,
        viewportSize: viewportSize,
        maxWidth: maxWidth,
      ),
      child: child,
    );
  }
}

class _TooltipChrome extends StatelessWidget {
  const _TooltipChrome({
    required this.child,
    required this.padding,
    required this.borderRadius,
    required this.elevation,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final double elevation;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color bg = backgroundColor ?? colors.surface.withValues(alpha: 0.96);
    final Color outline = colors.outlineVariant.withValues(alpha: 0.45);

    final double blur = elevation.clamp(0, 32);
    final double spread = blur > 0 ? blur * 0.08 : 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
        border: Border.all(color: outline, width: 0.8),
        boxShadow: blur > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: blur,
                  spreadRadius: spread,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _GraphHoverTooltipLayoutDelegate extends SingleChildLayoutDelegate {
  const _GraphHoverTooltipLayoutDelegate({
    required this.base,
    required this.offset,
    required this.viewportPadding,
    required this.viewportSize,
    required this.maxWidth,
  });

  final Offset base;
  final Offset offset;
  final EdgeInsets viewportPadding;
  final Size viewportSize;
  final double maxWidth;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final double widthLimit = math.max(
      120,
      math.min(maxWidth, viewportSize.width),
    );
    return BoxConstraints.loose(Size(widthLimit, viewportSize.height));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double dx = base.dx + offset.dx;
    double dy = base.dy + offset.dy;

    if (dx + childSize.width + viewportPadding.right > size.width) {
      dx = base.dx - offset.dx - childSize.width;
    }
    if (dy + childSize.height + viewportPadding.bottom > size.height) {
      dy = base.dy - offset.dy - childSize.height;
    }

    dx = dx.clamp(
      viewportPadding.left,
      math.max(
        viewportPadding.left,
        size.width - childSize.width - viewportPadding.right,
      ),
    );
    dy = dy.clamp(
      viewportPadding.top,
      math.max(
        viewportPadding.top,
        size.height - childSize.height - viewportPadding.bottom,
      ),
    );

    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_GraphHoverTooltipLayoutDelegate oldDelegate) {
    return base != oldDelegate.base ||
        offset != oldDelegate.offset ||
        viewportPadding != oldDelegate.viewportPadding;
  }
}

class _DefaultHoverTooltip extends StatelessWidget {
  const _DefaultHoverTooltip({required this.details});

  final GraphHoverDetails details;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _buildContent(textTheme);
  }

  Widget _buildContent(TextTheme textTheme) {
    switch (details.target.kind) {
      case GraphHoverTargetKind.node:
        final DisplayNode node = details.target.node!;
        final String title = node.label.isNotEmpty ? node.label : node.id;
        final String subtitle = node.label.isNotEmpty ? node.id : node.type;
        final List<Widget> lines = [
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                ),
              ),
            ),
        ];
        final NodeLifecycle lifecycle = node.lifecycle;
        lines.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Lifecycle · ${lifecycle.name}',
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
        final String parentDisplay =
            node.parentId != null && node.parentId!.trim().isNotEmpty
            ? node.parentId!
            : '-';
        lines.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Parent · $parentDisplay',
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
        if (node.node.payload.tagsNormalized.isNotEmpty) {
          final String tags = node.node.payload.tagsNormalized.join(', ');
          lines.add(
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Tags · $tags',
                style: textTheme.bodySmall?.copyWith(
                  color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: lines,
        );

      case GraphHoverTargetKind.edge:
        final DisplayNode source = details.target.sourceNode!;
        final DisplayNode target = details.target.targetNode!;
        final UyavaEdge edge = details.target.edge!;
        final String labelFrom = source.label.isNotEmpty
            ? source.label
            : source.id;
        final String labelTo = target.label.isNotEmpty
            ? target.label
            : target.id;
        final List<Widget> lines = [
          Text(
            '$labelFrom → $labelTo',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              edge.id,
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withValues(alpha: 0.75),
              ),
            ),
          ),
        ];
        if (edge.isBidirectional) {
          lines.add(
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Bidirectional',
                style: textTheme.bodySmall?.copyWith(
                  color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        }
        if (edge.isRemapped) {
          lines.add(
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Remapped via collapsed parent',
                style: textTheme.bodySmall?.copyWith(
                  color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: lines,
        );
    }
  }
}
