part of '../../graph_view_page.dart';

mixin ViewportStateMixin on FilterAndPanelStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _viewportKey = GlobalKey(debugLabel: 'graphViewport');
  final Set<int> _primaryPointerCandidates = <int>{};
  late GraphViewportController _viewportController;
  GraphViewportState? _storedViewportState;
  bool _storedViewportApplied = false;
  bool _shouldAutoFitViewport = true;
  bool _isPanModeEnabled = false;
  int _viewportStorageLoadToken = 0;
  late final DevToolsGraphHoverController _hoverController =
      DevToolsGraphHoverController(
        transformationController: _transformationController,
        renderConfig: _renderConfig,
        onChanged: () {
          if (!mounted) return;
          setState(() {});
        },
      );

  void disposeViewportState() {
    _viewportController.dispose();
    _transformationController.dispose();
    _hoverController.dispose();
  }

  @visibleForTesting
  bool get isPanModeEnabled => _isPanModeEnabled;

  @visibleForTesting
  TransformationController get transformationController =>
      _transformationController;

  @visibleForTesting
  Future<void> setViewportStorageForTesting(
    ViewportPersistenceAdapter storage,
  ) async {
    _graphPersistence.updateViewportStorage(storage);
    await _restorePersistedViewport();
    if (mounted) {
      setState(() {});
    }
  }

  void _handleViewportChanged(GraphViewportState state) {
    _graphPersistence.scheduleViewportSave(state);
  }

  Future<void> _restorePersistedViewport() async {
    final int requestToken = ++_viewportStorageLoadToken;
    final GraphViewportState? state = await _graphPersistence
        .restoreViewportState();
    if (!mounted || requestToken != _viewportStorageLoadToken) {
      return;
    }
    if (state != null) {
      _storedViewportState = state;
      _storedViewportApplied = false;
      _shouldAutoFitViewport = false;
    } else {
      _shouldAutoFitViewport = true;
    }
  }

  void _ensureViewportInitialized(
    Size viewportSize,
    List<DisplayNode> displayNodes,
    Set<String> parentIds,
  ) {
    if (!_isUsableViewportSize(viewportSize)) {
      return;
    }
    if (!_storedViewportApplied && _storedViewportState != null) {
      _storedViewportApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isUsableViewportSize(viewportSize)) return;
        _viewportController.applyState(_storedViewportState!);
      });
      return;
    }
    if (_shouldAutoFitViewport && displayNodes.isNotEmpty) {
      _shouldAutoFitViewport = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isUsableViewportSize(viewportSize)) return;
        _viewportController.fitToNodes(
          displayNodes,
          viewportSize,
          parentIds: parentIds,
        );
      });
    }
  }

  bool _isUsableViewportSize(Size size) =>
      size.width.isFinite &&
      size.width > 0 &&
      size.height.isFinite &&
      size.height > 0;
  void _fitVisibleNodes(
    List<DisplayNode> displayNodes,
    Size viewportSize,
    Set<String> parentIds,
  ) {
    if (displayNodes.isEmpty || !_isUsableViewportSize(viewportSize)) return;
    _shouldAutoFitViewport = false;
    _viewportController.fitToNodes(
      displayNodes,
      viewportSize,
      parentIds: parentIds,
    );
  }

  void _maybeRunAutoCompact(
    Size viewportSize,
    List<DisplayNode> displayNodes,
    Set<String> parentIds,
  ) {
    if (!_pendingAutoCompact || !_autoCompactFilters) return;
    if (displayNodes.isEmpty || !_isUsableViewportSize(viewportSize)) {
      _pendingAutoCompact = false;
      return;
    }
    final List<DisplayNode> snapshotNodes = List<DisplayNode>.from(
      displayNodes,
    );
    final Set<String> snapshotParents = Set<String>.from(parentIds);
    final Size snapshotViewport = viewportSize;
    _pendingAutoCompact = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_autoCompactFilters) return;
      if (snapshotNodes.isEmpty || !_isUsableViewportSize(snapshotViewport)) {
        return;
      }
      final bool applied = _viewportController.fitToNodes(
        snapshotNodes,
        snapshotViewport,
        parentIds: snapshotParents,
      );
      if (!applied) return;
      _runAutoCompactStabilization();
    });
  }

  void _runAutoCompactStabilization() {
    const int steps = 24;
    for (var i = 0; i < steps; i++) {
      _graphHost.graphController.step();
    }
    _edgeAlpha = _edgeVisibilityPolicy.update(
      _graphHost.graphController.positions,
      1 / 60,
    );
    if (!_devtoolsGraphViewAnimationsDisabledForTesting) {
      _controller?.forward(from: 0);
    }
    setState(() {});
  }

  void _reloadGraphLayout(Size viewportSize) {
    final Map<String, dynamic>? payload = _graphHost.state.lastGraphPayload;
    if (payload == null || !_isUsableViewportSize(viewportSize)) {
      return;
    }
    final Size2D layoutSize = _graphHost.layoutSizeForPayload(
      payload,
      viewportSize,
    );
    setState(() {
      _graphHost.graphController.replaceGraph(payload, layoutSize);
      _edgeVisibilityPolicy.reset();
      _edgeAlpha = _edgeVisibilityPolicy.update(
        _graphHost.graphController.positions,
        0,
      );
      _initializeAnimationController();
      _shouldAutoFitViewport = true;
    });
  }

  void _handlePanModeChanged(bool next) {
    if (_isPanModeEnabled == next) return;
    setState(() {
      _isPanModeEnabled = next;
    });
  }

  void _handlePointerDown(
    PointerDownEvent event,
    List<DisplayNode> displayNodes,
    Map<String, List<UyavaNode>> childrenByParent,
    List<UyavaEdge> edges,
  ) {
    if (event.kind == PointerDeviceKind.mouse) {
      const int secondaryMask = kSecondaryButton;
      if ((event.buttons & secondaryMask) != 0) {
        final GraphHoverTarget? target = _resolveContextMenuTarget(
          globalPosition: event.position,
          displayNodes: displayNodes,
          childrenByParent: childrenByParent,
          edges: edges,
        );
        if (target != null) {
          unawaited(
            _showGraphContextMenu(
              globalPosition: event.position,
              target: target,
            ),
          );
          return;
        }
      }
      const int primaryMask = kPrimaryButton;
      final bool isPrimaryButton =
          (event.buttons & primaryMask) != 0 || event.buttons == 0;
      if (isPrimaryButton) {
        _primaryPointerCandidates.add(event.pointer);
      }
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _primaryPointerCandidates.remove(event.pointer);
  }

  void _handlePointerUp(
    PointerUpEvent event,
    GraphInteractionLayer interactionLayer,
  ) {
    if (!_primaryPointerCandidates.remove(event.pointer)) return;
    if (_isPanModeEnabled) return;
    final BuildContext? viewportContext = _viewportKey.currentContext;
    if (viewportContext == null) return;
    final RenderBox? box = viewportContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset local = box.globalToLocal(event.position);
    final Size size = box.size;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > size.width ||
        local.dy > size.height) {
      return;
    }
    final Offset scene = _transformationController.toScene(local);
    final String? hitParentId = interactionLayer.hitTestParentId(scene);
    if (hitParentId == null) return;
    _toggleParentCollapse(hitParentId);
  }

  void _toggleParentCollapse(String parentId) {
    setState(() {
      final bool autoCollapsed = _graphHost.graphController.autoCollapsedParents
          .contains(parentId);
      if (autoCollapsed) {
        if (_autoCollapseOverrides.remove(parentId)) {
          _collapsedParents.add(parentId);
          _collapseProgress[parentId] = 1.0;
        } else {
          _autoCollapseOverrides.add(parentId);
          _collapsedParents.remove(parentId);
          _collapseProgress.remove(parentId);
        }
        return;
      }
      if (_collapsedParents.remove(parentId)) {
        _collapseProgress.remove(parentId);
      } else {
        _collapsedParents.add(parentId);
        _collapseProgress[parentId] = 1.0;
      }
    });
  }

  GraphHoverTarget? _resolveContextMenuTarget({
    required Offset globalPosition,
    required List<DisplayNode> displayNodes,
    required Map<String, List<UyavaNode>> childrenByParent,
    required List<UyavaEdge> edges,
  }) {
    final RenderBox? box = _currentViewportBox();
    if (box == null) return null;
    final Offset local = box.globalToLocal(globalPosition);
    final Size size = box.size;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > size.width ||
        local.dy > size.height) {
      return null;
    }
    final Offset scene = _transformationController.toScene(local);
    return resolveGraphHoverTarget(
      scenePosition: scene,
      displayNodes: displayNodes,
      childrenByParent: childrenByParent,
      edges: edges,
      renderConfig: _renderConfig,
    );
  }

  Future<void> _showGraphContextMenu({
    required Offset globalPosition,
    required GraphHoverTarget target,
  }) async {
    final bool isNode = target.kind == GraphHoverTargetKind.node;
    final String targetId = target.id;
    final bool isFocused = isNode
        ? _graphHost.focusController.containsNode(targetId)
        : _graphHost.focusController.containsEdge(targetId);
    final List<PopupMenuEntry<_GraphContextMenuAction>> items = [
      PopupMenuItem<_GraphContextMenuAction>(
        value: isFocused
            ? _GraphContextMenuAction.removeFocus
            : _GraphContextMenuAction.addFocus,
        child: Text(isFocused ? 'Remove from focus' : 'Add to focus'),
      ),
    ];

    final _GraphContextMenuAction? selection =
        await showMenu<_GraphContextMenuAction>(
          context: context,
          position: RelativeRect.fromLTRB(
            globalPosition.dx,
            globalPosition.dy,
            globalPosition.dx,
            globalPosition.dy,
          ),
          items: items,
        );
    if (selection == null) return;
    switch (selection) {
      case _GraphContextMenuAction.addFocus:
        if (isNode) {
          _graphHost.focusController.addNode(targetId);
        } else {
          _graphHost.focusController.addEdge(targetId);
        }
        break;
      case _GraphContextMenuAction.removeFocus:
        if (isNode) {
          _graphHost.focusController.removeNode(targetId);
        } else {
          _graphHost.focusController.removeEdge(targetId);
        }
        break;
    }
  }

  Offset _sceneToViewport(Offset scene) {
    return MatrixUtils.transformPoint(_transformationController.value, scene);
  }

  DisplayNode? _findDisplayNodeById(List<DisplayNode> nodes, String id) {
    for (final DisplayNode node in nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  void _clearGraphHover() {
    _hoverController.clear();
  }

  void _handleGlobalHover(
    PointerEvent event,
    List<DisplayNode> displayNodes,
    Map<String, List<UyavaNode>> childrenByParent,
    List<UyavaEdge> edges,
  ) {
    final RenderBox? box = _currentViewportBox();
    if (box == null) return;
    final Offset local = box.globalToLocal(event.position);
    _hoverController.updateFromViewportLocal(
      localPosition: local,
      viewportSize: box.size,
      displayNodes: displayNodes,
      childrenByParent: childrenByParent,
      edges: edges,
    );
  }

  RenderBox? _currentViewportBox() {
    final BuildContext? viewportContext = _viewportKey.currentContext;
    if (viewportContext is! Element || !viewportContext.mounted) {
      return null;
    }
    final RenderObject? renderObject = viewportContext.renderObject;
    return renderObject is RenderBox ? renderObject : null;
  }

  Future<void> _animateViewportToState(
    GraphViewportState state, {
    required Duration duration,
    required Curve curve,
  }) async {
    final Matrix4 begin = Matrix4.copy(_transformationController.value);
    final Matrix4 end = _matrixForViewportState(state);
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: duration,
    );
    final CurvedAnimation animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    final Matrix4Tween tween = Matrix4Tween(begin: begin, end: end);
    animation.addListener(() {
      final Matrix4 value = tween.evaluate(animation);
      _transformationController.value = value;
    });
    await controller.forward();
    controller.dispose();
    _viewportController.applyState(state);
  }

  Matrix4 _matrixForViewportState(GraphViewportState state) {
    final Matrix4 matrix = Matrix4.identity();
    matrix
      ..setEntry(0, 0, state.scale)
      ..setEntry(1, 1, state.scale)
      ..setEntry(2, 2, 1.0)
      ..setEntry(3, 3, 1.0)
      ..setTranslationRaw(state.translation.dx, state.translation.dy, 0.0);
    return matrix;
  }
}
