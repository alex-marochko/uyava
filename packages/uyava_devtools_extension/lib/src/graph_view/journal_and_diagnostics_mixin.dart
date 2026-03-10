part of '../../graph_view_page.dart';

mixin JournalAndDiagnosticsMixin on ViewportStateMixin {
  StreamSubscription<List<GraphDiagnosticRecord>>? _diagnosticSubscription;
  List<GraphDiagnosticRecord> _diagnosticRecords = const [];
  Set<String> _journalHighlightedNodes = <String>{};
  Set<GraphHighlightEdge> _journalHighlightedEdges = <GraphHighlightEdge>{};
  Timer? _journalHighlightTimer;
  int _lastDiagnosticsTrimmed = 0;
  bool _loggingTrimDiagnostic = false;

  void disposeJournalAndDiagnostics() {
    _diagnosticSubscription?.cancel();
    _journalHighlightTimer?.cancel();
  }

  int get _diagnosticAttentionCount {
    int count = 0;
    for (final GraphDiagnosticRecord record in _diagnosticRecords) {
      if (record.level == UyavaDiagnosticLevel.warning ||
          record.level == UyavaDiagnosticLevel.error) {
        count++;
      }
    }
    return count;
  }

  void _handleJournalLinkTap(GraphJournalLinkTarget link) {
    unawaited(_handleJournalLinkTapAsync(link));
  }

  Future<void> _handleJournalLinkTapAsync(
    GraphJournalLinkTarget link, {
    bool allowPrompt = true,
  }) async {
    if (!_graphControllerReady) return;
    final JournalRevealRequest? revealRequest = resolveJournalLinkReveal(
      link: link,
      graphController: _graphHost.graphController,
      renderConfig: _renderConfig,
      manualCollapsedParents: _collapsedParents,
      collapseProgress: _collapseProgress,
      autoCollapseOverrides: _autoCollapseOverrides,
    );
    if (revealRequest == null) {
      developer.log(
        'Journal link targeted element that is no longer available.',
        name: 'Uyava DevTools',
      );
      return;
    }

    final JournalRevealPlan revealPlan = revealRequest.revealPlan;

    if (!revealPlan.isFullyVisible) {
      bool proceed = !allowPrompt;
      if (allowPrompt) {
        proceed = await _confirmJournalReveal(revealPlan);
      }
      if (!proceed) {
        return;
      }
      await _applyJournalRevealPlan(revealPlan);
      if (!mounted) return;
    }

    _applyJournalHighlight(revealRequest.highlight);
    final GraphJournalFocusResult? focusResult = revealRequest.focusResult;
    if (focusResult != null) {
      _scheduleJournalViewportFocus(focusResult);
    }
  }

  void _applyJournalHighlight(GraphHighlight highlight) {
    _journalHighlightTimer?.cancel();
    if (highlight.isEmpty) {
      if (_journalHighlightedNodes.isEmpty &&
          _journalHighlightedEdges.isEmpty) {
        return;
      }
      setState(() {
        _journalHighlightedNodes = <String>{};
        _journalHighlightedEdges = <GraphHighlightEdge>{};
      });
      return;
    }
    setState(() {
      _journalHighlightedNodes = Set<String>.from(highlight.nodeIds);
      _journalHighlightedEdges = Set<GraphHighlightEdge>.from(highlight.edges);
    });
    _journalHighlightTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _journalHighlightedNodes = <String>{};
        _journalHighlightedEdges = <GraphHighlightEdge>{};
      });
    });
  }

  Future<bool> _confirmJournalReveal(JournalRevealPlan plan) async {
    if (!mounted) return false;
    final List<Widget> details = <Widget>[];
    if (plan.hiddenByFilters) {
      details.add(
        const Text(
          'Active filters hide the selected item. Revealing will clear all '
          'filters.',
        ),
      );
    }
    if (plan.hiddenByGrouping) {
      details.add(
        const Text(
          'Collapsed parent groups hide the selected item. Revealing will '
          'expand those groups.',
        ),
      );
    }
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reveal hidden item?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reveal'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _applyJournalRevealPlan(JournalRevealPlan plan) async {
    if (plan.hiddenByFilters) {
      final GraphFilterUpdateResult result = _graphHost.graphController
          .updateFilters(GraphFilterState.empty);
      _persistFilterPanelState(state: result.state);
      setState(() {
        _pendingAutoCompact = true;
      });
    }
    if (plan.parentsToExpand.isEmpty) return;
    for (final String parentId in plan.parentsToExpand) {
      _ensureParentExpanded(parentId);
    }
  }

  Future<void> _handleRevealFocusRequest() async {
    final JournalRevealRequest? revealRequest = buildFocusRevealRequest(
      focusState: _graphHost.focusController.state,
      graphController: _graphHost.graphController,
      renderConfig: _renderConfig,
      manualCollapsedParents: _collapsedParents,
      collapseProgress: _collapseProgress,
      autoCollapseOverrides: _autoCollapseOverrides,
    );
    if (revealRequest == null) return;
    final JournalRevealPlan plan = revealRequest.revealPlan;
    if (!plan.isFullyVisible) {
      final bool proceed = await _confirmJournalReveal(plan);
      if (!proceed) return;
      await _applyJournalRevealPlan(plan);
      if (!mounted) return;
    }
    _applyJournalHighlight(revealRequest.highlight);
    final GraphJournalFocusResult? viewportTarget = revealRequest.focusResult;
    if (viewportTarget != null) {
      _scheduleJournalViewportFocus(viewportTarget);
    }
  }

  Future<void> _handleOpenDiagnosticDocs(GraphDiagnosticRecord record) async {
    if (!mounted) return;
    await showDiagnosticDocsDialog(context: context, record: record);
  }

  void _ensureParentExpanded(String parentId) {
    if (!_isParentCurrentlyCollapsed(parentId)) return;
    _toggleParentCollapse(parentId);
  }

  bool _isParentCurrentlyCollapsed(String parentId) {
    final bool autoCollapsed = _graphHost.graphController.autoCollapsedParents
        .contains(parentId);
    if (autoCollapsed && !_autoCollapseOverrides.contains(parentId)) {
      return true;
    }
    if (_collapsedParents.contains(parentId)) {
      return true;
    }
    return false;
  }

  void _scheduleJournalViewportFocus(GraphJournalFocusResult result) {
    Future<void> focusViewport(Size viewportSize) async {
      const duration = Duration(milliseconds: 260);
      const curve = Curves.easeOutCubic;
      final GraphHighlight highlight = result.highlight;
      final bool singleNodeFocus =
          highlight.edges.isEmpty && highlight.nodeIds.length == 1;
      final Rect? bounds = result.focusBounds;
      final Offset? point = result.focusPoint;
      GraphViewportState? targetState;

      if (bounds != null && !bounds.isEmpty) {
        final double currentScale = _viewportController.state.scale;
        if (singleNodeFocus) {
          targetState = _viewportController.previewCenterOnPoint(
            bounds.center,
            viewportSize,
            scale: currentScale,
          );
        } else {
          final Size sceneViewportSize = Size(
            viewportSize.width / currentScale,
            viewportSize.height / currentScale,
          );
          const double epsilon = 0.01;
          final bool fitsAtCurrentScale =
              bounds.width <= sceneViewportSize.width + epsilon &&
              bounds.height <= sceneViewportSize.height + epsilon;
          if (fitsAtCurrentScale) {
            targetState = _viewportController.previewCenterOnPoint(
              bounds.center,
              viewportSize,
              scale: currentScale,
            );
          } else {
            targetState = _viewportController.previewFitToBounds(
              bounds,
              viewportSize,
            );
          }
        }
      } else if (point != null) {
        targetState = _viewportController.previewCenterOnPoint(
          point,
          viewportSize,
          scale: _viewportController.state.scale,
        );
      }
      if (targetState == null) return;
      await _animateViewportToState(
        targetState,
        duration: duration,
        curve: curve,
      );
    }

    final RenderBox? box = _currentViewportBox();
    if (box != null) {
      unawaited(focusViewport(box.size));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final RenderBox? retry = _currentViewportBox();
        if (retry == null) return;
        unawaited(focusViewport(retry.size));
      });
    }
  }

  void _handleAppDiagnostic(
    Map<String, dynamic> payload, {
    String? timestampIso,
  }) {
    if (!payload.containsKey('code')) {
      developer.log('[Uyava DevTools] Received diagnostic without code');
      return;
    }

    final Map<String, dynamic> normalized;
    try {
      normalized = _normalizeDiagnosticPayload(payload);
    } catch (error, stackTrace) {
      developer.log(
        '[Uyava DevTools] Failed to cast diagnostic payload to Map<String, dynamic>',
        name: 'Uyava DevTools',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    final UyavaGraphDiagnosticPayload diagnostic;
    try {
      diagnostic = UyavaGraphDiagnosticPayload.fromJson(normalized);
    } catch (error, stackTrace) {
      developer.log(
        '[Uyava DevTools] Failed to decode diagnostic payload',
        name: 'Uyava DevTools',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    final DateTime? timestamp =
        _parseDiagnosticTimestamp(timestampIso) ?? diagnostic.timestamp;

    final bool hasKnownCode =
        diagnostic.codeEnum != null ||
        UyavaGraphIntegrityCode.fromWireString(diagnostic.code) != null;
    if (!hasKnownCode) {
      final Object? enumName = payload['codeEnum'];
      developer.log(
        '[Uyava DevTools] Unknown diagnostic code received, falling back to raw string: '
        '${enumName ?? '-'} -> ${diagnostic.code}',
        name: 'Uyava DevTools',
        level: 800,
      );
    }

    _graphHost.graphController.addAppDiagnosticPayload(
      diagnostic,
      timestamp: timestamp,
    );

    final int logLevel = diagnostic.level == UyavaDiagnosticLevel.error
        ? 1000
        : 900;
    final String canonicalCode =
        diagnostic.codeEnum?.toWireString() ?? diagnostic.code;
    final String subject = diagnostic.subjects.isEmpty
        ? ''
        : diagnostic.subjects.join(',');
    developer.log(
      '[Uyava DevTools] ${diagnostic.level.name.toUpperCase()} '
      '$canonicalCode $subject ${diagnostic.context ?? const {}}',
      name: 'Uyava DevTools',
      level: logLevel,
    );
  }

  static DateTime? _parseDiagnosticTimestamp(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(isoString).toUtc();
    } catch (_) {
      developer.log(
        '[Uyava DevTools] Failed to parse diagnostic timestamp',
        name: 'Uyava DevTools',
        level: 800,
      );
      return null;
    }
  }

  static Map<String, dynamic> _normalizeDiagnosticPayload(
    Map<String, dynamic> payload,
  ) {
    final Map<String, dynamic> normalized = <String, dynamic>{};
    for (final MapEntry<String, dynamic> entry in payload.entries) {
      if (entry.key == 'sourceId' || entry.key == 'sourceType') {
        continue;
      }
      normalized[entry.key] = _normalizeDiagnosticValue(entry.value);
    }
    return normalized;
  }

  static Object? _normalizeDiagnosticValue(Object? value) {
    if (value is Map) {
      final map = value.cast<Object?, Object?>();
      final normalized = <String, dynamic>{};
      for (final entry in map.entries) {
        normalized[entry.key.toString()] = _normalizeDiagnosticValue(
          entry.value,
        );
      }
      return normalized;
    }
    if (value is Iterable) {
      return value.map(_normalizeDiagnosticValue).toList(growable: false);
    }
    return value;
  }
}
