import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'config.dart';

/// Result of sizing the virtual layout canvas for the force simulation.
class LayoutSizingResult {
  const LayoutSizingResult({
    required this.viewportSize,
    required this.layoutSize,
  });

  /// Sanitized viewport size (ensures positive, finite dimensions).
  final Size viewportSize;

  /// Size passed to the layout engine. Always >= [viewportSize] on each axis.
  final Size layoutSize;
}

/// Computes a virtual canvas for the graph layout so dense graphs get enough
/// breathing room even when the visible panel is tiny.
///
/// The layout area preserves the viewport aspect ratio but expands to at least
/// `nodeCount * areaPerNodeHint`, where `areaPerNodeHint` depends on the
/// configured node radius. Hosts should share a single instance to keep sizing
/// consistent across platforms.
class LayoutViewportSizer {
  LayoutViewportSizer({
    required this.renderConfig,
    double nodeSpacingMultiplier = 10.0,
    Size fallbackViewportSize = const Size(1024, 768),
    double maxVirtualExtent = 16000.0,
  }) : _nodeSpacingMultiplier = nodeSpacingMultiplier,
       _fallbackViewportSize = fallbackViewportSize,
       _maxVirtualExtent = maxVirtualExtent;

  final RenderConfig renderConfig;
  final double _nodeSpacingMultiplier;
  final Size _fallbackViewportSize;
  final double _maxVirtualExtent;

  /// Resolves the virtual layout size for the provided viewport and node count.
  LayoutSizingResult resolve({
    required Size viewportSize,
    required int nodeCount,
  }) {
    final Size sanitizedViewport = _sanitizeViewportSize(viewportSize);
    final double aspect = sanitizedViewport.width / sanitizedViewport.height;
    final double viewportArea =
        sanitizedViewport.width * sanitizedViewport.height;

    final double areaPerNode = _areaPerNodeHint();
    final double desiredArea = nodeCount <= 0
        ? viewportArea
        : nodeCount * areaPerNode;
    double targetArea = math.max(viewportArea, desiredArea);
    final double maxArea = _maxVirtualExtent * _maxVirtualExtent;
    if (targetArea > maxArea) {
      targetArea = maxArea;
    }

    double layoutWidth = math.sqrt(targetArea * aspect);
    double layoutHeight = layoutWidth / aspect;
    if (!layoutWidth.isFinite || layoutWidth <= 0) {
      layoutWidth = sanitizedViewport.width;
    }
    if (!layoutHeight.isFinite || layoutHeight <= 0) {
      layoutHeight = sanitizedViewport.height;
    }

    layoutWidth = layoutWidth.clamp(sanitizedViewport.width, _maxVirtualExtent);
    layoutHeight = layoutHeight.clamp(
      sanitizedViewport.height,
      _maxVirtualExtent,
    );

    final Size layoutSize = Size(layoutWidth, layoutHeight);
    return LayoutSizingResult(
      viewportSize: sanitizedViewport,
      layoutSize: layoutSize,
    );
  }

  double _areaPerNodeHint() {
    final double baseRadius = math.max(renderConfig.childNodeRadius, 8.0);
    final double spacing = baseRadius * _nodeSpacingMultiplier;
    return spacing * spacing;
  }

  Size _sanitizeViewportSize(Size candidate) {
    final double width = candidate.width.isFinite && candidate.width > 0
        ? candidate.width
        : _fallbackViewportSize.width;
    final double height = candidate.height.isFinite && candidate.height > 0
        ? candidate.height
        : _fallbackViewportSize.height;
    return Size(width, height);
  }
}

/// Convenience wrapper that tracks the last known viewport size while reusing a
/// [LayoutViewportSizer] instance. Hosts can share this helper to keep sizing
/// logic identical across platforms.
class LayoutSizingController {
  LayoutSizingController({required RenderConfig renderConfig})
    : _sizer = LayoutViewportSizer(renderConfig: renderConfig);

  final LayoutViewportSizer _sizer;
  Size? _lastViewportSize;

  /// Records a viewport measurement captured during layout.
  void recordViewportSize(Size viewportSize) {
    if (_isUsable(viewportSize)) {
      _lastViewportSize = viewportSize;
    }
  }

  /// Resolves the layout sizing result for the given graph payload.
  LayoutSizingResult resolveForPayload({
    Map<String, dynamic>? payload,
    required Size viewportHint,
    required int fallbackNodeCount,
  }) {
    final Size viewport = _effectiveViewportSize(viewportHint);
    final int nodeCount = _extractNodeCount(payload) ?? fallbackNodeCount;
    return _sizer.resolve(viewportSize: viewport, nodeCount: nodeCount);
  }

  Size _effectiveViewportSize(Size hint) {
    final Size? recorded = _lastViewportSize;
    if (recorded != null && _isUsable(recorded)) {
      return recorded;
    }
    if (_isUsable(hint)) {
      return hint;
    }
    return _sizer.resolve(viewportSize: hint, nodeCount: 0).viewportSize;
  }

  int? _extractNodeCount(Map<String, dynamic>? payload) {
    final Object? nodes = payload?['nodes'];
    if (nodes is List) return nodes.length;
    return null;
  }

  bool _isUsable(Size size) =>
      size.width.isFinite &&
      size.width > 0 &&
      size.height.isFinite &&
      size.height > 0;
}
