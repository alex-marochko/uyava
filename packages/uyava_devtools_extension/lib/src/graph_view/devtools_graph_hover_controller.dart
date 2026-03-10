part of '../../graph_view_page.dart';

class DevToolsGraphHoverController {
  DevToolsGraphHoverController({
    required TransformationController transformationController,
    required RenderConfig renderConfig,
    required VoidCallback onChanged,
    this.tooltipDelay = const Duration(milliseconds: 300),
    this.viewportSlack = 12.0,
    this.positionEpsilon = 0.75,
  }) : _transformationController = transformationController,
       _renderConfig = renderConfig,
       _onChanged = onChanged;

  final TransformationController _transformationController;
  final RenderConfig _renderConfig;
  final VoidCallback _onChanged;
  final Duration tooltipDelay;
  final double viewportSlack;
  final double positionEpsilon;

  Timer? _tooltipTimer;
  GraphHoverTarget? _pendingTooltipTarget;
  GraphHoverDetails? _highlight;
  GraphHoverDetails? _tooltip;

  GraphHoverDetails? get highlight => _highlight;
  GraphHoverDetails? get tooltip => _tooltip;

  void updateFromViewportLocal({
    required Offset localPosition,
    required Size viewportSize,
    required List<DisplayNode> displayNodes,
    required Map<String, List<UyavaNode>> childrenByParent,
    required List<UyavaEdge> edges,
  }) {
    if (_isOutsideViewport(localPosition, viewportSize)) {
      if (_clearInternal()) {
        _notifyChanged();
      }
      return;
    }

    final Offset clamped = Offset(
      localPosition.dx.clamp(0.0, viewportSize.width),
      localPosition.dy.clamp(0.0, viewportSize.height),
    );
    final Offset scene = _transformationController.toScene(clamped);
    final GraphHoverTarget? target = resolveGraphHoverTarget(
      scenePosition: scene,
      displayNodes: displayNodes,
      childrenByParent: childrenByParent,
      edges: edges,
      renderConfig: _renderConfig,
    );
    if (target == null) {
      if (_clearInternal()) {
        _notifyChanged();
      }
      return;
    }

    final GraphHoverDetails next = GraphHoverDetails(
      target: target,
      viewportPosition: clamped,
      scenePosition: scene,
    );
    final GraphHoverDetails? currentHighlight = _highlight;
    if (currentHighlight != null &&
        currentHighlight.target == next.target &&
        (currentHighlight.viewportPosition - next.viewportPosition).distance <=
            positionEpsilon) {
      return;
    }

    final GraphHoverDetails? currentTooltip = _tooltip;
    final bool tooltipVisibleForTarget =
        currentTooltip != null && currentTooltip.target == next.target;
    _highlight = next;
    if (tooltipVisibleForTarget) {
      _tooltip = next;
    } else {
      _tooltip = null;
    }
    _notifyChanged();

    if (tooltipVisibleForTarget) {
      _tooltipTimer?.cancel();
      _pendingTooltipTarget = null;
    } else {
      _scheduleHoverTooltip(next);
    }
  }

  bool clear() {
    final bool cleared = _clearInternal();
    if (cleared) {
      _notifyChanged();
    }
    return cleared;
  }

  void dispose() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _pendingTooltipTarget = null;
  }

  bool _isOutsideViewport(Offset local, Size viewportSize) {
    final double slack = viewportSlack;
    return local.dx < -slack ||
        local.dy < -slack ||
        local.dx > viewportSize.width + slack ||
        local.dy > viewportSize.height + slack;
  }

  bool _clearInternal() {
    if (_highlight == null && _tooltip == null) {
      return false;
    }
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _pendingTooltipTarget = null;
    _highlight = null;
    _tooltip = null;
    return true;
  }

  void _scheduleHoverTooltip(GraphHoverDetails details) {
    _tooltipTimer?.cancel();
    _pendingTooltipTarget = details.target;
    _tooltipTimer = Timer(tooltipDelay, () {
      final GraphHoverDetails? current = _highlight;
      if (current == null) {
        return;
      }
      if (_pendingTooltipTarget == null ||
          current.target != _pendingTooltipTarget) {
        return;
      }
      _tooltip = current;
      _pendingTooltipTarget = null;
      _notifyChanged();
    });
  }

  void _notifyChanged() {
    _onChanged();
  }
}
