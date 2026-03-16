part of '../../graph_view_page.dart';

extension _GraphViewViewportLogic on _DevToolsGraphViewCoordinator {
  Widget buildGraphViewportContent(
    BuildContext context,
    UyavaPanelContext panelContext,
  ) {
    final List<UyavaNode> filteredNodes =
        _graphHost.graphController.filteredNodes;
    final List<UyavaEdge> filteredEdges =
        _graphHost.graphController.filteredEdges;
    final Set<String> autoCollapsedParents =
        _graphHost.graphController.autoCollapsedParents;
    final Map<String, String?> parentById = {
      for (final UyavaNode node in filteredNodes) node.id: node.parentId,
    };
    final Map<String, List<UyavaNode>> childrenByParent =
        <String, List<UyavaNode>>{};
    for (final UyavaNode node in filteredNodes) {
      final String? parentId = node.parentId;
      if (parentId != null) {
        (childrenByParent[parentId] ??= <UyavaNode>[]).add(node);
      }
    }
    final Set<String> parentIds = childrenByParent.keys.toSet();
    final Set<String> effectiveCollapsedParents =
        <String>{...autoCollapsedParents}
          ..removeAll(_autoCollapseOverrides)
          ..addAll(_collapsedParents);
    final Map<String, double> effectiveCollapseProgress =
        Map<String, double>.from(_collapseProgress);
    for (final String parentId in autoCollapsedParents) {
      if (_autoCollapseOverrides.contains(parentId)) {
        effectiveCollapseProgress.remove(parentId);
      } else {
        effectiveCollapseProgress[parentId] = 1.0;
      }
    }
    bool isHidden(String id) {
      String? current = id;
      while (true) {
        final String? parentId = parentById[current];
        if (parentId == null) return false;
        final double progress = effectiveCollapseProgress[parentId] ?? 0.0;
        final double eased = _ease(progress);
        if (effectiveCollapsedParents.contains(parentId) && eased >= 1.0) {
          return true;
        }
        if (!effectiveCollapsedParents.contains(parentId) && progress > 0.0) {
          final double expandRevealWindow = _renderConfig.expandRevealWindow;
          if (eased > expandRevealWindow) {
            return true; // still expanding, keep children hidden
          }
        }
        current = parentId;
      }
    }

    final edgePolicy = EdgeAggregationPolicy(
      collapsedParents: effectiveCollapsedParents,
      collapseProgress: effectiveCollapseProgress,
      parentById: parentById,
      ease: _renderConfig.ease,
      edgeRemapThreshold: _renderConfig.edgeRemapThreshold,
    );
    final cloudPolicy = CloudVisibilityPolicy(
      collapsedParents: effectiveCollapsedParents,
      collapseProgress: effectiveCollapseProgress,
      ease: _renderConfig.ease,
      fadeWindow: _renderConfig.cloudFadeWindow,
    );
    final List<UyavaNode> visibleNodes = filteredNodes
        .where((node) => !isHidden(node.id))
        .toList();
    final List<DisplayNode> displayNodes = visibleNodes.map((node) {
      final Vector2 pos =
          _graphHost.graphController.positions[node.id] ?? const Vector2(0, 0);
      final Offset position = toOffset(pos);
      return DisplayNode(node: node, position: position);
    }).toList();
    final Map<String, int> tagCounts = _catalogTagCounts(visibleNodes);
    final bool hasTagLegend = tagCounts.isNotEmpty;
    final GraphFilterGrouping? groupingState =
        _graphHost.graphController.filters.grouping;
    int? selectedGroupingLevel;
    if (groupingState != null &&
        groupingState.mode == UyavaFilterGroupingMode.level &&
        groupingState.levelDepth != null) {
      selectedGroupingLevel = groupingState.levelDepth;
    }
    final List<int> groupingLevels = computeGroupingLevels(
      _graphHost.graphController.nodes,
    );
    if (selectedGroupingLevel != null &&
        !groupingLevels.contains(selectedGroupingLevel)) {
      groupingLevels.add(selectedGroupingLevel);
      groupingLevels.sort();
    }
    final Widget groupingControls = GraphGroupingControls(
      availableLevels: groupingLevels,
      selectedLevel: selectedGroupingLevel,
      onClearGrouping: () => _applyGroupingLevel(null),
      onLevelSelected: _applyGroupingLevel,
    );
    final theme = Theme.of(context);
    final List<Widget> panelOverlays = [];
    if (hasTagLegend || groupingLevels.isNotEmpty) {
      final Color overlayColor = theme.colorScheme.surface.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.72 : 0.82,
      );
      if (hasTagLegend) {
        final Widget tagPanel = Material(
          elevation: 3,
          color: overlayColor,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220, maxHeight: 260),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: SingleChildScrollView(
                primary: false,
                physics: const ClampingScrollPhysics(),
                child: TagLegend(
                  tagCounts: tagCounts,
                  title: 'Tag highlights',
                  expanded: _tagLegendExpanded,
                  onExpandedChanged: _handleTagLegendExpandedChanged,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        );
        panelOverlays.add(Positioned(top: 12, left: 16, child: tagPanel));
      }
      if (groupingLevels.isNotEmpty) {
        final Widget groupingPanel = Material(
          elevation: 3,
          color: overlayColor,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: groupingControls,
          ),
        );
        panelOverlays.add(Positioned(top: 12, right: 16, child: groupingPanel));
      }
    }
    final List<UyavaEdge> remappedEdges = edgePolicy.remapAndAggregateEdges(
      filteredEdges,
    );
    final List<UyavaEvent> filteredEventsForRender = _graphHost.state.edgeEvents
        .where((event) => _acceptsSeverity(event.severity))
        .toList(growable: false);
    final List<UyavaNodeEvent> filteredNodeEventsForRender = _graphHost
        .state
        .nodeEvents
        .where((event) => _acceptsSeverity(event.severity))
        .toList(growable: false);
    final Map<String, int> visibleQueueCounts = <String, int>{};
    final Map<String, UyavaSeverity?> visibleQueueSeverities =
        <String, UyavaSeverity?>{};
    final now = DateTime.now();
    final window = _renderConfig.eventDuration;
    _graphHost.state.arrivalsByVisibleDirection.removeWhere(
      (k, v) => v.isEmpty,
    );
    for (final entry in _graphHost.state.arrivalsByVisibleDirection.entries) {
      entry.value.removeWhere((a) => now.difference(a.timestamp) > window);
      final List<GraphEdgeArrival> acceptedArrivals = entry.value
          .where((a) => _acceptsSeverity(a.severity))
          .toList(growable: false);
      final int total = acceptedArrivals.length;
      if (total >= _renderConfig.queueLabelMinCountToShow) {
        visibleQueueCounts[entry.key] = total;
        _graphHost.state.edgeLabelLastCount[entry.key] = total;
        UyavaSeverity? maxSev;
        int maxRank = -1;
        for (final a in acceptedArrivals) {
          final r = _severityRank(a.severity);
          if (r > maxRank) {
            maxRank = r;
            maxSev = a.severity;
          }
        }
        visibleQueueSeverities[entry.key] = maxSev;
      }
    }
    final Map<String, double> labelAlphas = <String, double>{};
    final Set<String> allKeys = {
      ...visibleQueueCounts.keys,
      ..._graphHost.state.edgeLabelStates.keys,
    };
    for (final key in allKeys) {
      final shouldBeVisible = visibleQueueCounts.containsKey(key);
      final state = _graphHost.state.edgeLabelStates.putIfAbsent(
        key,
        () => GraphLabelState(visible: shouldBeVisible, changedAt: now),
      );
      if (state.visible != shouldBeVisible) {
        state.visible = shouldBeVisible;
        state.changedAt = now;
      }
      final elapsed = now.difference(state.changedAt);
      if (state.visible) {
        final t =
            (elapsed.inMilliseconds /
                    _renderConfig.queueLabelFadeIn.inMilliseconds)
                .clamp(0.0, 1.0);
        labelAlphas[key] = t;
      } else {
        final t =
            (elapsed.inMilliseconds /
                    _renderConfig.queueLabelFadeOut.inMilliseconds)
                .clamp(0.0, 1.0);
        final alpha = 1.0 - t;
        if (alpha > 0) {
          final last = _graphHost.state.edgeLabelLastCount[key];
          if (last != null) {
            visibleQueueCounts.putIfAbsent(key, () => last);
          }
          labelAlphas[key] = alpha;
        }
      }
    }
    final Map<String, int> nodeBadgeCounts = <String, int>{};
    final Map<String, UyavaSeverity?> nodeBadgeSeverities =
        <String, UyavaSeverity?>{};
    for (final nev in filteredNodeEventsForRender) {
      if (now.difference(nev.timestamp) > window) continue;
      final vid = edgePolicy.mapToVisibleAncestor(nev.nodeId);
      final newCount = (nodeBadgeCounts[vid] ?? 0) + 1;
      nodeBadgeCounts[vid] = newCount;
      final existing = nodeBadgeSeverities[vid];
      if (_severityRank(nev.severity) > _severityRank(existing)) {
        nodeBadgeSeverities[vid] = nev.severity;
      }
    }
    // Node badge alphas with fade in/out
    final Map<String, double> nodeBadgeAlphas = <String, double>{};
    final Set<String> nodeKeys = {
      ...nodeBadgeCounts.keys,
      ..._graphHost.state.nodeBadgeStates.keys,
    };
    for (final k in nodeKeys) {
      final should =
          nodeBadgeCounts.containsKey(k) &&
          (nodeBadgeCounts[k] ?? 0) >= _renderConfig.queueLabelMinCountToShow;
      final st = _graphHost.state.nodeBadgeStates.putIfAbsent(
        k,
        () => GraphLabelState(visible: should, changedAt: now),
      );
      if (st.visible != should) {
        st.visible = should;
        st.changedAt = now;
      }
      final elapsed = now.difference(st.changedAt);
      if (st.visible) {
        final t =
            (elapsed.inMilliseconds /
                    _renderConfig.queueLabelFadeIn.inMilliseconds)
                .clamp(0.0, 1.0);
        nodeBadgeAlphas[k] = t;
      } else {
        final t =
            (elapsed.inMilliseconds /
                    _renderConfig.queueLabelFadeOut.inMilliseconds)
                .clamp(0.0, 1.0);
        final a = 1.0 - t;
        if (a > 0) {
          final last = _graphHost.state.nodeBadgeLastCount[k];
          if (last != null) nodeBadgeCounts.putIfAbsent(k, () => last);
          nodeBadgeAlphas[k] = a;
        }
      }
      if (nodeBadgeCounts.containsKey(k)) {
        _graphHost.state.nodeBadgeLastCount[k] = nodeBadgeCounts[k]!;
      }
    }
    final scheme = theme.colorScheme;
    final fg = scheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final Size viewportSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              _graphHost.layoutSizing.recordViewportSize(viewportSize);
              final RenderBox? viewportBox = _currentViewportBox();
              final Size viewportRenderSize = viewportBox?.size ?? viewportSize;
              _ensureViewportInitialized(viewportSize, displayNodes, parentIds);
              _maybeRunAutoCompact(viewportSize, displayNodes, parentIds);
              final GraphHoverDetails? hoverHighlight =
                  _hoverController.highlight;
              final GraphHoverDetails? hoverTooltipDetails =
                  _hoverController.tooltip;
              final String? hoveredNodeId =
                  hoverHighlight?.target.kind == GraphHoverTargetKind.node
                  ? hoverHighlight!.target.node!.id
                  : null;
              final String? hoveredEdgeId =
                  hoverHighlight?.target.kind == GraphHoverTargetKind.edge
                  ? hoverHighlight!.target.edge!.id
                  : null;
              Offset? hoverAnchor;
              if (hoverTooltipDetails != null) {
                Offset? anchorScene;
                switch (hoverTooltipDetails.target.kind) {
                  case GraphHoverTargetKind.node:
                    final String nodeId = hoverTooltipDetails.target.node!.id;
                    final DisplayNode? currentNode =
                        _findDisplayNodeById(displayNodes, nodeId) ??
                        hoverTooltipDetails.target.node;
                    anchorScene = currentNode?.position;
                    break;
                  case GraphHoverTargetKind.edge:
                    final UyavaEdge edge = hoverTooltipDetails.target.edge!;
                    final DisplayNode? currentSource =
                        _findDisplayNodeById(displayNodes, edge.source) ??
                        hoverTooltipDetails.target.sourceNode;
                    final DisplayNode? currentTarget =
                        _findDisplayNodeById(displayNodes, edge.target) ??
                        hoverTooltipDetails.target.targetNode;
                    if (currentSource != null && currentTarget != null) {
                      anchorScene = Offset.lerp(
                        currentSource.position,
                        currentTarget.position,
                        0.5,
                      );
                    }
                    break;
                }
                if (anchorScene != null) {
                  hoverAnchor = _sceneToViewport(anchorScene);
                }
              }
              final interactionLayer = GraphInteractionLayer(
                displayNodes: displayNodes,
                childrenByParent: childrenByParent,
                renderConfig: _renderConfig,
              );
              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) => _handlePointerDown(
                  event,
                  displayNodes,
                  childrenByParent,
                  remappedEdges,
                ),
                onPointerCancel: _handlePointerCancel,
                onPointerHover: (event) => _handleGlobalHover(
                  event,
                  displayNodes,
                  childrenByParent,
                  remappedEdges,
                ),
                onPointerUp: (event) =>
                    _handlePointerUp(event, interactionLayer),
                child: Stack(
                  fit: StackFit.expand,
                  children: () {
                    final widgets = <Widget>[
                      InteractiveViewer(
                        key: _viewportKey,
                        transformationController: _transformationController,
                        minScale: _renderConfig.minViewportScale,
                        maxScale: _renderConfig.maxViewportScale,
                        scaleFactor: 1000.0,
                        trackpadScrollCausesScale: true,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        child: MouseRegion(
                          onExit: (_) => _clearGraphHover(),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              if (details.kind == PointerDeviceKind.mouse) {
                                return;
                              }
                              if (_isPanModeEnabled) return;
                              final hitParentId = interactionLayer
                                  .hitTestParentId(details.localPosition);
                              if (hitParentId == null) return;
                              _toggleParentCollapse(hitParentId);
                            },
                            onLongPressStart: (details) async {
                              final GraphHoverTarget? target =
                                  _resolveContextMenuTarget(
                                    globalPosition: details.globalPosition,
                                    displayNodes: displayNodes,
                                    childrenByParent: childrenByParent,
                                    edges: remappedEdges,
                                  );
                              if (target == null) return;
                              await _showGraphContextMenu(
                                globalPosition: details.globalPosition,
                                target: target,
                              );
                            },
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: GraphPainter(
                                displayNodes: displayNodes,
                                edges: remappedEdges,
                                events: filteredEventsForRender,
                                nodeEvents: filteredNodeEventsForRender,
                                collapsedParents: effectiveCollapsedParents,
                                collapseProgress: effectiveCollapseProgress,
                                directChildCounts: {
                                  for (final entry in childrenByParent.entries)
                                    entry.key: entry.value.length,
                                },
                                isParentId: (id) =>
                                    childrenByParent.containsKey(id),
                                parentById: parentById,
                                edgePolicy: edgePolicy,
                                cloudPolicy: cloudPolicy,
                                renderConfig: _renderConfig,
                                edgeGlobalOpacity: _edgeAlpha,
                                cloudGlobalOpacity: _edgeAlpha,
                                eventQueueLabels: visibleQueueCounts,
                                eventQueueLabelAlphas: labelAlphas,
                                eventQueueLabelSeverities:
                                    visibleQueueSeverities,
                                nodeEventBadgeLabels: nodeBadgeCounts,
                                nodeEventBadgeAlphas: nodeBadgeAlphas,
                                nodeEventBadgeSeverities: nodeBadgeSeverities,
                                uiForegroundColor: fg,
                                hoveredNodeId: hoveredNodeId,
                                hoveredEdgeId: hoveredEdgeId,
                                highlightedNodeIds: _journalHighlightedNodes,
                                highlightedEdges: _journalHighlightedEdges,
                                focusedNodeIds:
                                    _graphHost.focusController.state.nodeIds,
                                focusedEdgeIds:
                                    _graphHost.focusController.state.edgeIds,
                                focusColor: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: DevToolsGraphToolbar(
                          viewportController: _viewportController,
                          renderConfig: _renderConfig,
                          viewportSize: viewportSize,
                          displayNodes: displayNodes,
                          parentIds: parentIds,
                          onManualViewportChange: () {
                            _shouldAutoFitViewport = false;
                          },
                          onFitVisibleNodes: () {
                            _fitVisibleNodes(
                              displayNodes,
                              viewportSize,
                              parentIds,
                            );
                          },
                          isPanModeEnabled: _isPanModeEnabled,
                          onPanModeChanged: _handlePanModeChanged,
                          onReloadLayout:
                              _graphHost.state.lastGraphPayload == null
                              ? null
                              : () => _reloadGraphLayout(viewportSize),
                        ),
                      ),
                    ];
                    if (panelOverlays.isNotEmpty) {
                      widgets.insertAll(1, panelOverlays);
                    }
                    if (hoverTooltipDetails != null) {
                      widgets.add(
                        HoverOverlay(
                          details: hoverTooltipDetails,
                          viewportSize: viewportRenderSize,
                          anchorViewportPosition: hoverAnchor,
                        ),
                      );
                    }
                    return widgets;
                  }(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
