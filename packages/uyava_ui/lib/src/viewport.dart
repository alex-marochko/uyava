import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'config.dart';
import 'graph_painter.dart';

/// Represents the current viewport transformation (scale + translation).
class GraphViewportState {
  final double scale;
  final Offset translation;

  const GraphViewportState({required this.scale, required this.translation});

  factory GraphViewportState.fromMatrix(Matrix4 matrix) {
    final Float64List storage = matrix.storage;
    final double scaleX = storage[0];
    final double scaleY = storage[5];
    final double inferredScale = scaleX.abs() > scaleY.abs()
        ? scaleX.abs()
        : scaleY.abs();
    return GraphViewportState(
      scale: inferredScale,
      translation: Offset(storage[12], storage[13]),
    );
  }

  Matrix4 toMatrix() {
    final Matrix4 matrix = Matrix4.identity();
    matrix
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(2, 2, 1.0)
      ..setEntry(3, 3, 1.0)
      ..setTranslationRaw(translation.dx, translation.dy, 0.0);
    return matrix;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'scale': scale,
    'translateX': translation.dx,
    'translateY': translation.dy,
  };

  static GraphViewportState? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final Object? scaleRaw = json['scale'];
    final Object? txRaw = json['translateX'];
    final Object? tyRaw = json['translateY'];
    if (scaleRaw is! num || txRaw is! num || tyRaw is! num) return null;
    return GraphViewportState(
      scale: scaleRaw.toDouble(),
      translation: Offset(txRaw.toDouble(), tyRaw.toDouble()),
    );
  }

  @override
  int get hashCode => Object.hash(scale, translation.dx, translation.dy);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphViewportState &&
        (scale - other.scale).abs() < 0.0001 &&
        (translation.dx - other.translation.dx).abs() < 0.0001 &&
        (translation.dy - other.translation.dy).abs() < 0.0001;
  }

  @override
  String toString() =>
      'GraphViewportState(scale: $scale, translation: $translation)';
}

/// Controller responsible for applying zoom/pan operations and exposing
/// persisted state snapshots for hosts.
class GraphViewportController {
  GraphViewportController({
    required this.renderConfig,
    required TransformationController transformationController,
    ValueChanged<GraphViewportState>? onStateChanged,
  }) : _controller = transformationController,
       _onStateChanged = onStateChanged {
    _state = GraphViewportState.fromMatrix(_controller.value);
    _controller.addListener(_handleMatrixChanged);
  }

  final RenderConfig renderConfig;
  final TransformationController _controller;
  final ValueChanged<GraphViewportState>? _onStateChanged;
  late GraphViewportState _state;

  GraphViewportState get state => _state;

  void dispose() {
    _controller.removeListener(_handleMatrixChanged);
  }

  /// Returns the current state snapshot (useful for persistence).
  GraphViewportState snapshot() => _state;

  /// Applies a previously persisted state. Returns `true` when the state is
  /// within configured limits and applied successfully.
  bool applyState(GraphViewportState state) {
    final double clampedScale = _clampScale(state.scale);
    final Matrix4 matrix = _matrixFor(
      scale: clampedScale,
      translation: state.translation,
    );
    _setMatrix(matrix);
    return true;
  }

  /// Resets the viewport to the default scale and centers the origin within the
  /// provided viewport size.
  void reset(Size viewportSize) {
    final double scale = _clampScale(renderConfig.defaultViewportScale);
    final Offset center = _viewportCenter(viewportSize);
    final Matrix4 matrix = _matrixFor(scale: scale, translation: center);
    _setMatrix(matrix);
  }

  /// Centers the scene around the given [scenePoint] using the provided
  /// [viewportSize]. Optionally override the current scale.
  void centerOnPoint(Offset scenePoint, Size viewportSize, {double? scale}) {
    final GraphViewportState state = _stateForCenter(
      scenePoint,
      viewportSize,
      scale: scale,
    );
    _setMatrix(_matrixFor(scale: state.scale, translation: state.translation));
  }

  /// Zooms by [factor] around [focalPoint] (in viewport coordinates).
  /// When [focalPoint] is omitted, the viewport center is used.
  void zoomBy(double factor, Size viewportSize, {Offset? focalPoint}) {
    final double currentScale = _state.scale;
    double targetScale = currentScale * factor;
    targetScale = _clampScale(targetScale);
    if ((targetScale - currentScale).abs() < 0.0001) return;

    final Offset focal = focalPoint ?? _viewportCenter(viewportSize);
    final Offset scenePoint = _scenePointForViewport(
      focal,
      currentScale,
      _state.translation,
    );
    final Offset translation =
        focal -
        Offset(scenePoint.dx * targetScale, scenePoint.dy * targetScale);

    _setMatrix(_matrixFor(scale: targetScale, translation: translation));
  }

  /// Fits the provided [bounds] to the viewport, respecting padding and zoom
  /// limits. Returns `true` when bounds are non-empty and applied.
  bool fitToBounds(Rect bounds, Size viewportSize) {
    final GraphViewportState? state = _stateForBounds(bounds, viewportSize);
    if (state == null) return false;
    _setMatrix(_matrixFor(scale: state.scale, translation: state.translation));
    return true;
  }

  GraphViewportState? previewFitToBounds(Rect bounds, Size viewportSize) =>
      _stateForBounds(bounds, viewportSize);

  /// Fits the provided set of [displayNodes] to the viewport. Optional
  /// [parentIds] may be supplied to treat those nodes as parent groups (which
  /// use the parent radius for padding).
  bool fitToNodes(
    Iterable<DisplayNode> displayNodes,
    Size viewportSize, {
    Set<String>? parentIds,
    double? padding,
  }) {
    final Rect? bounds = computeDisplayNodeBounds(
      displayNodes,
      renderConfig,
      parentIds: parentIds,
      padding: padding ?? renderConfig.viewportFitPadding,
    );
    if (bounds == null) return false;
    return fitToBounds(bounds, viewportSize);
  }

  GraphViewportState previewCenterOnPoint(
    Offset scenePoint,
    Size viewportSize, {
    double? scale,
  }) => _stateForCenter(scenePoint, viewportSize, scale: scale);

  void _handleMatrixChanged() {
    final GraphViewportState next = GraphViewportState.fromMatrix(
      _controller.value,
    );
    if (next == _state) return;
    _state = next;
    _onStateChanged?.call(_state);
  }

  void _setMatrix(Matrix4 matrix) {
    _controller.value = matrix;
  }

  double _clampScale(double value) => value
      .clamp(renderConfig.minViewportScale, renderConfig.maxViewportScale)
      .toDouble();

  Matrix4 _matrixFor({required double scale, required Offset translation}) {
    final Matrix4 matrix = Matrix4.identity();
    matrix
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(2, 2, 1.0)
      ..setEntry(3, 3, 1.0)
      ..setTranslationRaw(translation.dx, translation.dy, 0.0);
    return matrix;
  }

  Offset _viewportCenter(Size viewportSize) =>
      Offset(viewportSize.width / 2, viewportSize.height / 2);

  Offset _scenePointForViewport(
    Offset viewportPoint,
    double scale,
    Offset translation,
  ) {
    if (scale == 0) return Offset.zero;
    return Offset(
      (viewportPoint.dx - translation.dx) / scale,
      (viewportPoint.dy - translation.dy) / scale,
    );
  }

  GraphViewportState _stateForCenter(
    Offset scenePoint,
    Size viewportSize, {
    double? scale,
  }) {
    final double targetScale = _clampScale(scale ?? _state.scale);
    final Offset translation =
        _viewportCenter(viewportSize) -
        Offset(scenePoint.dx * targetScale, scenePoint.dy * targetScale);
    return GraphViewportState(scale: targetScale, translation: translation);
  }

  GraphViewportState? _stateForBounds(Rect bounds, Size viewportSize) {
    if (bounds.isEmpty) return null;
    final double width = bounds.width;
    final double height = bounds.height;
    if (width <= 0 || height <= 0) return null;

    final double scaleX = viewportSize.width / width;
    final double scaleY = viewportSize.height / height;
    double targetScale = math.min(scaleX, scaleY);
    if (!targetScale.isFinite || targetScale <= 0) {
      targetScale = renderConfig.defaultViewportScale;
    }
    targetScale = _clampScale(targetScale);

    final Offset translation =
        _viewportCenter(viewportSize) -
        Offset(bounds.center.dx * targetScale, bounds.center.dy * targetScale);

    return GraphViewportState(scale: targetScale, translation: translation);
  }
}

/// Computes a padded bounding box for the provided [displayNodes].
Rect? computeDisplayNodeBounds(
  Iterable<DisplayNode> displayNodes,
  RenderConfig renderConfig, {
  Set<String>? parentIds,
  double? padding,
}) {
  double minX = double.infinity;
  double maxX = -double.infinity;
  double minY = double.infinity;
  double maxY = -double.infinity;
  bool hasNodes = false;

  final Set<String> parents = parentIds ?? const <String>{};
  final double pad = padding ?? renderConfig.viewportFitPadding;

  for (final DisplayNode node in displayNodes) {
    hasNodes = true;
    final bool isParent = parents.contains(node.id);
    final double radius = isParent
        ? renderConfig.parentNodeRadius
        : renderConfig.childNodeRadius;
    final double x = node.position.dx;
    final double y = node.position.dy;
    minX = math.min(minX, x - radius);
    maxX = math.max(maxX, x + radius);
    minY = math.min(minY, y - radius);
    maxY = math.max(maxY, y + radius);
  }

  if (!hasNodes) return null;

  if (!minX.isFinite ||
      !maxX.isFinite ||
      !minY.isFinite ||
      !maxY.isFinite ||
      minX == double.infinity ||
      minY == double.infinity) {
    return null;
  }

  final double minExtent = renderConfig.childNodeRadius * 2;
  final double width = math.max(maxX - minX, minExtent);
  final double height = math.max(maxY - minY, minExtent);
  final Offset center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
  final Rect rect = Rect.fromCenter(
    center: center,
    width: width,
    height: height,
  );
  return rect.inflate(pad);
}
