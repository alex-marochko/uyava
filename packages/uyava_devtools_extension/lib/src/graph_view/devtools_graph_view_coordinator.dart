part of '../../graph_view_page.dart';

class _DevToolsGraphViewCoordinator extends State<GraphViewPage>
    with
        TickerProviderStateMixin,
        _DevToolsGraphViewCoordinatorCore,
        FilterAndPanelStateMixin,
        ViewportStateMixin,
        JournalAndDiagnosticsMixin {
  static const int _diagnosticsSoftLimit =
      GraphViewCoordinator.diagnosticsSoftLimit;

  Map<String, Object?> _sanitizeContext(Map<String, Object?> raw) {
    final Map<String, Object?> result = <String, Object?>{};
    raw.forEach((key, value) {
      final Object? sanitized = _sanitizeValue(value);
      if (sanitized != null) {
        result[key] = sanitized;
      }
    });
    return result;
  }

  Object? _sanitizeValue(Object? value, {int depth = 0}) {
    if (value == null) return null;
    if (value is num || value is bool) return value;
    if (value is String) {
      const int maxLen = 500;
      return value.length > maxLen ? value.substring(0, maxLen) : value;
    }
    if (value is Map) {
      final Map<String, Object?> map = <String, Object?>{};
      value.forEach((key, val) {
        final Object? sanitized = _sanitizeValue(val, depth: depth + 1);
        if (sanitized != null) {
          map[key.toString()] = sanitized;
        }
      });
      return map;
    }
    if (value is Iterable) {
      final List<Object?> list = <Object?>[];
      int count = 0;
      for (final Object? item in value) {
        if (count >= 20) {
          list.add('…');
          break;
        }
        final Object? sanitized = _sanitizeValue(item, depth: depth + 1);
        if (sanitized != null) {
          list.add(sanitized);
        }
        count++;
      }
      return list;
    }
    return value.toString();
  }

  void _logExtensionDiagnostic({
    required String code,
    UyavaDiagnosticLevel level = UyavaDiagnosticLevel.info,
    Iterable<String>? subjects,
    Map<String, Object?>? context,
  }) {
    _graphHost.graphController.addAppDiagnostic(
      code: code,
      level: level,
      subjects: subjects ?? <String>['session:$_sessionId'],
      context: context == null ? null : _sanitizeContext(context),
    );
  }

  Map<String, Object?> _devtoolsInfo() {
    final Uri uri = Uri.base;
    final Map<String, String> params = uri.queryParameters;
    final String? origin = (uri.scheme == 'http' || uri.scheme == 'https')
        ? uri.origin
        : null;
    final Map<String, Object?> info =
        <String, Object?>{
          'origin': origin,
          'path': uri.path,
          'ide': params['ide'],
          'embedMode': params['embedMode'],
          'page': params['page'],
          'devtoolsVersion': params['devtoolsVersion'] ?? _devtoolsVersion,
        }..removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty),
        );
    return info;
  }

  void _logSessionMetadata() {
    _logExtensionDiagnostic(
      code: 'ext.session_info',
      context: <String, Object?>{
        'sessionId': _sessionId,
        'mode': kReleaseMode
            ? 'release'
            : kDebugMode
            ? 'debug'
            : 'profile',
        'platform': 'web',
        'versions': <String, Object?>{
          'extension': _extensionVersion,
          'core': _coreVersion,
          'protocol': _protocolVersion,
        },
        'devtools': _devtoolsInfo(),
      },
    );
  }

  void _logGraphLoaded(Map<String, dynamic> payload) {
    int payloadBytes = 0;
    try {
      payloadBytes = utf8.encode(jsonEncode(payload)).length;
    } catch (_) {}
    _logExtensionDiagnostic(
      code: 'ext.graph_loaded',
      context: <String, Object?>{
        'graphStats': <String, Object?>{
          'nodes': _graphHost.graphController.nodes.length,
          'edges': _graphHost.graphController.edges.length,
          'payloadBytes': payloadBytes,
        },
        'filters': _filtersSummary(),
        'panels': _panelSummary(),
      },
    );
  }

  void _logVmConnectionState({required bool connected}) {
    final bool initial = _lastVmConnected == null;
    if (initial && !connected) {
      _lastVmConnected = connected;
      return;
    }
    if (_lastVmConnected == connected) {
      return;
    }
    _lastVmConnected = connected;
    String? host;
    final String? uriString = serviceManager.serviceUri;
    if (uriString != null) {
      final Uri? uri = Uri.tryParse(uriString);
      host = uri?.host;
    }
    _logExtensionDiagnostic(
      code: connected ? 'ext.vm_connect' : 'ext.vm_disconnect',
      level: connected
          ? UyavaDiagnosticLevel.info
          : UyavaDiagnosticLevel.warning,
      context: <String, Object?>{'vmHost': host, 'connected': connected},
    );
  }

  @override
  void initState() {
    super.initState();
    _graphPersistence = DevToolsGraphPersistence(
      viewportStorage:
          widget.viewportStorage ?? createViewportPersistenceAdapter(),
      panelLayoutStorage:
          widget.panelLayoutStorage ??
          DevToolsPanelLayoutStorage(
            storageKey: _panelStorageKey,
            legacyStorageKeys: const [_legacyPanelStorageKey],
            maxAge: const Duration(days: 14),
          ),
      logSink: (message, error, stackTrace) {
        developer.log(
          '[Uyava DevTools] $message',
          name: 'Uyava DevTools',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _vmEventBridge = DevToolsVmEventBridge(
      onExtensionEvent: _handleExtensionEvent,
      onFetchInitialGraph: _fetchInitialGraph,
    );
    _panelDefinitions = [
      UyavaPanelDefinition(
        id: _graphPanelId,
        title: 'Graph',
        builder: (context, panelContext) =>
            _buildGraphPanel(context, panelContext),
        minimumSize: const Size(640, 420),
      ),
      UyavaPanelDefinition(
        id: _dashboardPanelId,
        title: 'Dashboard',
        builder: _buildDashboardPanel,
        defaultVisibility: UyavaPanelVisibility.visible,
        minimumSize: const Size(320, 200),
      ),
      UyavaPanelDefinition(
        id: _chainsPanelId,
        title: 'Chains',
        builder: (context, panelContext) =>
            _buildChainsPanel(context, panelContext),
        defaultVisibility: UyavaPanelVisibility.visible,
        minimumSize: const Size(320, 200),
      ),
      UyavaPanelDefinition(
        id: _journalPanelId,
        title: 'Journal',
        builder: _buildJournalPanel,
        defaultVisibility: UyavaPanelVisibility.visible,
        minimumSize: const Size(360, 200),
      ),
    ];
    _panelPresetContent = _buildPanelPresetContent();
    _panelShellController = UyavaPanelShellController(
      registry: [
        for (final definition in _panelDefinitions)
          definition.toRegistryEntry(),
      ],
      spec: _specForPanelPreset(_panelLayoutPreset),
      layoutSchemaId: _panelLayoutSchemaId,
      filtersSchemaId: _panelFiltersSchemaId,
    );
    _panelShellController.setConfigurationId(panelPresetId(_panelLayoutPreset));
    _panelShellSnapshot = _panelShellController.snapshot;
    _panelMenuToggles = _buildPanelMenuToggles();
    _panelMenuController = UyavaPanelMenuController(
      isStackedLayout: () =>
          _panelLayoutPreset == UyavaPanelLayoutPreset.stacked,
      onSelectStacked: () => _applyPanelPreset(UyavaPanelLayoutPreset.stacked),
      onSelectGraphWithDetails: () =>
          _applyPanelPreset(UyavaPanelLayoutPreset.graphWithDetails),
      filtersVisible: () => _filtersVisible,
      onFiltersVisibilityChanged: _setFiltersVisible,
      panelToggles: _panelMenuToggles,
    );
    _panelShellAdapter = DevToolsPanelShellAdapter(
      onSnapshot: _handlePanelShellSnapshot,
      onPersistedState: _handlePanelLayoutChanged,
    );
    _panelShellController.attachAdapter(
      _panelShellAdapter,
      replaySnapshot: false,
    );
    _restorePersistedPanelLayout();
    _graphHost.focusController.addListener(_handleFocusChanged);
    _filtersSubscription = _graphHost.graphController.filtersStream.listen((
      GraphFilterResult result,
    ) {
      _persistFilterPanelState(state: result.state);
      if (!mounted) return;
      final GraphFilterState previousState = _lastFilterState;
      _lastFilterState = result.state;
      final bool filtersChanged = result.state != previousState;
      final bool shouldAutoCompact =
          _autoCompactFilters &&
          filtersChanged &&
          !_suppressNextAutoCompact &&
          result.visibleNodes.isNotEmpty;
      _suppressNextAutoCompact = false;
      final GraphFilterGrouping? grouping = result.state.grouping;
      final bool groupingChanged = grouping != _lastGrouping;
      _lastGrouping = grouping;
      setState(() {
        if (groupingChanged) {
          _autoCollapseOverrides.clear();
          _collapsedParents.clear();
          _collapseProgress.clear();
        }
        _autoCollapseOverrides.removeWhere(
          (id) => !result.autoCollapsedParents.contains(id),
        );
        if (shouldAutoCompact) {
          _pendingAutoCompact = true;
        }
      });
    });
    _graphControllerReady = true;
    _logSessionMetadata();
    _applyPendingFilters();
    _viewportController = _graphHost.createViewportController(
      transformationController: _transformationController,
      onStateChanged: _handleViewportChanged,
    );
    _restorePersistedViewport();
    installBrowserContextMenuSuppressor();
    _vmConnectionListener ??= () {
      final bool connected = serviceManager.connectedState.value.connected;
      _logVmConnectionState(connected: connected);
    };
    serviceManager.connectedState.addListener(_vmConnectionListener!);
    _logVmConnectionState(
      connected: serviceManager.connectedState.value.connected,
    );
    _diagnosticSubscription = _graphHost.graphController.diagnosticsStream
        .listen((records) {
          if (!mounted) return;
          setState(() {
            _diagnosticRecords = records;
          });
          final int trimmed =
              _graphHost.graphController.diagnostics.totalTrimmed;
          if (!_loggingTrimDiagnostic && trimmed > _lastDiagnosticsTrimmed) {
            final int delta = trimmed - _lastDiagnosticsTrimmed;
            _loggingTrimDiagnostic = true;
            _logExtensionDiagnostic(
              code: 'ext.diagnostics_trimmed',
              level: UyavaDiagnosticLevel.warning,
              context: <String, Object?>{
                'trimmed': delta,
                'limit': _diagnosticsSoftLimit,
              },
            );
            _loggingTrimDiagnostic = false;
          }
          _lastDiagnosticsTrimmed = trimmed;
          if (records.isNotEmpty) {
            developer.log(
              '[Uyava DevTools] Graph diagnostics count ${records.length}',
              name: 'Uyava DevTools',
              level: 900,
            );
          }
        });
    _edgeVisibilityPolicy = EdgeVisibilityPolicy(_renderConfig);
  }

  UyavaPanelPresetContent _buildPanelPresetContent() {
    return UyavaPanelPresetContent(
      graphPanelId: _graphPanelId,
      detailPanelIds: <UyavaPanelId>[_dashboardPanelId, _chainsPanelId],
      footerPanelIds: <UyavaPanelId>[_journalPanelId],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vmBridgeInitialized) return;
    _vmBridgeInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vmEventBridge.ensureSubscribed();
    });
  }

  void _handleExtensionEvent(Event event) {
    if (event.extensionKind != 'ext.uyava.event') return;
    if (event.extensionData == null) {
      developer.log('[Uyava DevTools] Missing extension data in event');
      return;
    }

    try {
      final eventData = event.extensionData!.data;
      final eventType = eventData['type'] as String?;
      final payload = eventData['payload'];

      switch (eventType) {
        case UyavaEventTypes.replaceGraph:
          // GraphController needs the size of the viewport for initial layout
          final size =
              (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;
          _handleReplaceGraph(payload, size);
          break;
        case UyavaEventTypes.loadGraph:
          // Incremental graph load: merge provided nodes/edges into current graph.
          _handleIncrementalLoad(payload);
          break;
        case UyavaEventTypes.graphDiagnostics:
          if (payload is! Map) {
            developer.log('[Uyava DevTools] Invalid diagnostics payload');
            return;
          }
          final timestampIso = eventData['timestamp'] as String?;
          _handleAppDiagnostic(
            Map<String, dynamic>.from(payload.cast<String, Object?>()),
            timestampIso: timestampIso,
          );
          break;
        case UyavaEventTypes.clearDiagnostics:
          _graphHost.graphController.clearDiagnostics();
          break;
        // New canonical name for edge animations.
        case UyavaEventTypes.edgeEvent:
          _handleAnimation(payload);
          break;
        // Legacy alias kept for backward compatibility.
        case UyavaEventTypes.animation:
          _handleAnimation(payload);
          break;
        case UyavaEventTypes.nodeEvent:
          _handleNodeEvent(payload);
          break;
        case UyavaEventTypes.nodeLifecycle:
          setState(() {
            final NodeLifecycle? applied = applyNodeLifecycle(
              _graphHost.graphController,
              payload,
            );
            if (applied != null) {
              final String? nodeId = payload['nodeId'] as String?;
              if (nodeId != null) {
                _graphHost.state.nodeLifecycleOverrides[nodeId] = applied;
                _graphHost.writeLifecycleOverrideToPayload(nodeId, applied);
              }
            }
          });
          break;
        case UyavaEventTypes.defineMetric:
          if (payload is! Map) {
            developer.log('[Uyava DevTools] Invalid metric definition payload');
            return;
          }
          _registerMetricDefinition(
            Map<String, dynamic>.from(payload.cast<String, dynamic>()),
          );
          break;
        case UyavaEventTypes.defineEventChain:
          if (payload is! Map) {
            developer.log(
              '[Uyava DevTools] Invalid event chain definition payload',
            );
            return;
          }
          _registerEventChainDefinition(
            Map<String, dynamic>.from(payload.cast<String, dynamic>()),
          );
          break;
        case UyavaEventTypes.addNode:
          _handleAddNode(payload);
          break;
        case UyavaEventTypes.addEdge:
          _handleAddEdge(payload);
          break;
        case UyavaEventTypes.removeNode:
          _handleRemoveNode(payload);
          break;
        case UyavaEventTypes.removeEdge:
          _handleRemoveEdge(payload);
          break;
        case UyavaEventTypes.patchNode:
          _handlePatchNode(payload);
          break;
        case UyavaEventTypes.patchEdge:
          _handlePatchEdge(payload);
          break;
        default:
          developer.log('[Uyava DevTools] Unknown event type: $eventType');
      }
    } catch (e, st) {
      developer.log(
        '[Uyava DevTools] Error parsing event: $e',
        stackTrace: st,
        level: 2000,
      );
    }
  }

  void _handleReplaceGraph(Map<String, dynamic> payload, Size size) {
    final bool shouldAutoFit = _storedViewportState == null;
    if (payload['metrics'] is List) {
      _graphHost.state.metricDefinitionsById.clear();
    }
    _applyMetricDefinitionsFromPayload(payload['metrics']);
    _applyEventChainDefinitionsFromPayload(payload['eventChains']);
    final Map<String, dynamic> cachedPayload = _graphHost.cloneGraphPayload(
      payload,
    );
    _graphHost.applyLifecycleOverridesToPayload(cachedPayload);
    final Size2D layoutSize = _graphHost.layoutSizeForPayload(
      cachedPayload,
      size,
    );
    setState(() {
      _graphHost.cacheGraphPayload(cachedPayload);
      _graphHost.graphController.replaceGraph(cachedPayload, layoutSize);
      // Reset edge stabilization when graph changes
      _edgeVisibilityPolicy.reset();
      _edgeAlpha = _edgeVisibilityPolicy.update(
        _graphHost.graphController.positions,
        0,
      );
      _initializeAnimationController();
      if (shouldAutoFit) {
        _shouldAutoFitViewport = true;
      }
    });
    _logGraphLoaded(cachedPayload);
  }

  // --- Incremental graph updates ---
  void _handleIncrementalLoad(Map<String, dynamic> payload) {
    // Accepts a payload with optional 'nodes' and 'edges' lists to merge.
    _applyMetricDefinitionsFromPayload(payload['metrics']);
    _applyEventChainDefinitionsFromPayload(payload['eventChains']);
    final List<Map<String, dynamic>> newNodes = (payload['nodes'] is List)
        ? List<Map<String, dynamic>>.from(payload['nodes'] as List)
        : const <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> newEdges = (payload['edges'] is List)
        ? List<Map<String, dynamic>>.from(payload['edges'] as List)
        : const <Map<String, dynamic>>[];
    _mergeAndReplace(addNodes: newNodes, addEdges: newEdges);
  }

  void _handleAddNode(Map<String, dynamic> nodeMap) {
    _mergeAndReplace(addNodes: <Map<String, dynamic>>[nodeMap]);
  }

  void _handleAddEdge(Map<String, dynamic> edgeMap) {
    _mergeAndReplace(addEdges: <Map<String, dynamic>>[edgeMap]);
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleRemoveNode(Map<String, dynamic> payload) {
    final String? id = payload['id'] as String?;
    if (id == null || id.isEmpty) return;
    final List<String> cascade = (payload['cascadeEdgeIds'] is List)
        ? (payload['cascadeEdgeIds'] as List).whereType<String>().toList(
            growable: false,
          )
        : const <String>[];
    _graphHost.state.nodeEvents.removeWhere((event) => event.nodeId == id);
    _mergeAndReplace(removeNodeIds: <String>[id], removeEdgeIds: cascade);
  }

  void _handleRemoveEdge(Map<String, dynamic> payload) {
    final String? id = payload['id'] as String?;
    if (id == null || id.isEmpty) return;
    _mergeAndReplace(removeEdgeIds: <String>[id]);
  }

  void _handlePatchNode(Map<String, dynamic> payload) {
    final Object? nodeRaw = payload['node'];
    if (nodeRaw is! Map) return;
    final Map<String, dynamic> nodeMap = Map<String, dynamic>.from(
      nodeRaw.cast<String, dynamic>(),
    );
    _mergeAndReplace(patchNodes: <Map<String, dynamic>>[nodeMap]);
  }

  void _handlePatchEdge(Map<String, dynamic> payload) {
    final Object? edgeRaw = payload['edge'];
    if (edgeRaw is! Map) return;
    final Map<String, dynamic> edgeMap = Map<String, dynamic>.from(
      edgeRaw.cast<String, dynamic>(),
    );
    _mergeAndReplace(patchEdges: <Map<String, dynamic>>[edgeMap]);
  }

  void _registerMetricDefinition(Map<String, dynamic> definition) {
    try {
      final String? id = definition['id'] as String?;
      if (id != null) {
        _graphHost.state.metricDefinitionsById[id] = Map<String, dynamic>.from(
          definition,
        );
      }
      _graphHost.graphController.registerMetricDefinition(definition);
    } catch (error, stackTrace) {
      developer.log(
        '[Uyava DevTools] Failed to register metric definition: $error',
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  void _registerEventChainDefinition(Map<String, dynamic> definition) {
    try {
      _graphHost.graphController.registerEventChainDefinition(definition);
    } catch (error, stackTrace) {
      developer.log(
        '[Uyava DevTools] Failed to register event chain definition: $error',
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  void _applyMetricDefinitionsFromPayload(Object? metrics) {
    if (metrics is! List) return;
    for (final Object? entry in metrics) {
      if (entry is Map) {
        _registerMetricDefinition(
          Map<String, dynamic>.from(entry.cast<String, dynamic>()),
        );
      }
    }
  }

  void _applyEventChainDefinitionsFromPayload(Object? chains) {
    if (chains is! List) return;
    for (final Object? entry in chains) {
      if (entry is Map) {
        _registerEventChainDefinition(
          Map<String, dynamic>.from(entry.cast<String, dynamic>()),
        );
      }
    }
  }

  void _recordMetricSampleFromNodeEvent(Map<String, dynamic> payload) {
    final Object? inner = payload['payload'];
    if (inner is! Map) return;
    final Object? metricRaw = inner['metric'];
    if (metricRaw is! Map) return;
    final Map<String, dynamic> metric = Map<String, dynamic>.from(
      metricRaw.cast<String, dynamic>(),
    );
    final UyavaSeverity? severity = _parseSeverity(payload['severity']);
    DateTime? fallbackTimestamp;
    final Object? eventTimestamp = payload['timestamp'];
    if (eventTimestamp is String && eventTimestamp.isNotEmpty) {
      try {
        fallbackTimestamp = DateTime.parse(eventTimestamp).toUtc();
      } catch (_) {
        fallbackTimestamp = null;
      }
    }
    try {
      _graphHost.graphController.recordMetricSample(
        metric,
        fallbackTimestamp: fallbackTimestamp,
        severity: severity,
      );
    } catch (error, stackTrace) {
      developer.log(
        '[Uyava DevTools] Failed to record metric sample: $error',
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  void _recordEventChainProgressFromNodeEvent(Map<String, dynamic> payload) {
    try {
      recordEventChainProgressFromNodeEvent(
        _graphHost.graphController,
        payload,
      );
    } catch (error, stackTrace) {
      developer.log(
        '[Uyava DevTools] Failed to record event chain progress: $error',
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  void _mergeAndReplace({
    List<Map<String, dynamic>> addNodes = const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> addEdges = const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> patchNodes = const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> patchEdges = const <Map<String, dynamic>>[],
    List<String> removeNodeIds = const <String>[],
    List<String> removeEdgeIds = const <String>[],
  }) {
    final Map<String, Map<String, dynamic>> nodeById =
        <String, Map<String, dynamic>>{
          for (final node in _graphHost.graphController.nodes)
            node.id: Map<String, dynamic>.from(node.data),
        };
    final Map<String, Map<String, dynamic>> edgeById =
        <String, Map<String, dynamic>>{
          for (final edge in _graphHost.graphController.edges)
            edge.id: Map<String, dynamic>.from(edge.data),
        };

    final Set<String> removedNodes = removeNodeIds.toSet();
    for (final id in removedNodes) {
      nodeById.remove(id);
    }

    // Always remove edges explicitly requested or cascading from missing nodes.
    final Set<String> explicitRemovedEdges = removeEdgeIds.toSet();
    for (final id in explicitRemovedEdges) {
      edgeById.remove(id);
    }

    // Apply additions before patches so patches win last-writer.
    for (final candidate in addNodes) {
      final String? id = candidate['id'] as String?;
      if (id == null) continue;
      nodeById[id] = Map<String, dynamic>.from(candidate);
    }
    for (final candidate in addEdges) {
      final String? id = candidate['id'] as String?;
      if (id == null) continue;
      edgeById[id] = Map<String, dynamic>.from(candidate);
    }

    for (final patch in patchNodes) {
      final String? id = patch['id'] as String?;
      if (id == null) continue;
      nodeById[id] = Map<String, dynamic>.from(patch);
    }
    for (final patch in patchEdges) {
      final String? id = patch['id'] as String?;
      if (id == null) continue;
      edgeById[id] = Map<String, dynamic>.from(patch);
    }

    final Set<String> validNodeIds = nodeById.keys.toSet();
    edgeById.removeWhere((id, edge) {
      if (explicitRemovedEdges.contains(id)) return true;
      final String? source = edge['source'] as String?;
      final String? target = edge['target'] as String?;
      final bool dangling =
          source == null ||
          target == null ||
          !validNodeIds.contains(source) ||
          !validNodeIds.contains(target);
      if (dangling) {
        explicitRemovedEdges.add(id);
      }
      return dangling;
    });

    if (removedNodes.isNotEmpty) {
      edgeById.removeWhere((id, edge) {
        final String? source = edge['source'] as String?;
        final String? target = edge['target'] as String?;
        return removedNodes.contains(source) || removedNodes.contains(target);
      });
    }

    final List<Map<String, dynamic>> combinedNodes =
        nodeById.values
            .map((node) => Map<String, dynamic>.from(node))
            .toList(growable: false)
          ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    final List<Map<String, dynamic>> combinedEdges =
        edgeById.values
            .map((edge) => Map<String, dynamic>.from(edge))
            .toList(growable: false)
          ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    // Apply updated graph via replaceGraph with seeded positions so we
    // preserve existing layout and only nudge the new/affected nodes.
    final size = (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;
    final nextPayload = <String, dynamic>{
      'nodes': combinedNodes,
      'edges': combinedEdges,
    };
    final prevPositions = Map<String, Vector2>.from(
      _graphHost.graphController.positions,
    );
    final Size2D layoutSize = _graphHost.layoutSizeForPayload(
      nextPayload,
      size,
    );
    _graphHost.applyLifecycleOverridesToPayload(nextPayload);
    setState(() {
      _graphHost.cacheGraphPayload(nextPayload);
      _graphHost.graphController.replaceGraph(
        nextPayload,
        layoutSize,
        initialPositions: prevPositions,
      );
      // Do NOT reset edge stabilization on incremental updates; update alpha in-place.
      _edgeAlpha = _edgeVisibilityPolicy.update(
        _graphHost.graphController.positions,
        0,
      );
      // Ensure animation controller is active; if null, initialize.
      _initializeAnimationController();
    });
  }

  void _handleAnimation(Map<String, dynamic> payload) {
    final ev = parseAnimationEvent(payload, _graphHost.graphController);
    if (ev == null) return;
    _graphHost.journalAdapter.recordEdgeEvent(ev);
    final Map<String, String?> parentById = {
      for (final n in _graphHost.graphController.nodes) n.id: n.parentId,
    };
    final edgePolicyNow = EdgeAggregationPolicy(
      collapsedParents: _collapsedParents,
      collapseProgress: _collapseProgress,
      parentById: parentById,
      ease: _renderConfig.ease,
      edgeRemapThreshold: _renderConfig.edgeRemapThreshold,
    );
    final bool started = _graphHost.recordEdgeAnimation(
      event: ev,
      aggregationPolicy: edgePolicyNow,
    );
    setState(() {});
    if (started && !(_controller?.isAnimating ?? false)) {
      _controller?.forward(from: 0);
    }
  }

  void _handleNodeEvent(Map<String, dynamic> payload) {
    final ev = parseNodeEvent(payload);
    _recordMetricSampleFromNodeEvent(payload);
    _recordEventChainProgressFromNodeEvent(payload);
    if (ev != null) {
      _graphHost.journalAdapter.recordNodeEvent(ev);
      _graphHost.recordNodeEvent(ev);
      setState(() {});
      if (!(_controller?.isAnimating ?? false)) {
        _controller?.forward(from: 0);
      }
    }
  }

  Future<void> _fetchInitialGraph() async {
    try {
      // Capture size before awaiting to avoid using BuildContext across async gap.
      final size =
          (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.uyava.getInitialGraph',
      );
      final Map<String, dynamic> graphData =
          response.json as Map<String, dynamic>;
      if (!mounted) return;
      _handleReplaceGraph(graphData, size);
    } catch (e, st) {
      developer.log(
        '[Uyava DevTools] Failed to fetch initial graph: $e',
        stackTrace: st,
        level: 2000,
      );
    }
  }

  bool _acceptsSeverity(UyavaSeverity? severity) =>
      _graphHost.acceptsSeverity(severity);

  Map<String, int> _catalogTagCounts(Iterable<UyavaNode> nodes) {
    final Map<String, int> counts = <String, int>{};
    for (final node in nodes) {
      final Object? raw = node.data['tagsCatalog'];
      if (raw is! Iterable) continue;
      for (final Object? entry in raw) {
        if (entry is! String || entry.isEmpty) continue;
        counts[entry] = (counts[entry] ?? 0) + 1;
      }
    }
    return counts;
  }

  @visibleForTesting
  List<String> get visibleNodeIds => _graphHost.graphController.filteredNodes
      .map((n) => n.id)
      .toList(growable: false);

  @visibleForTesting
  List<String> get visibleEdgeIds => _graphHost.graphController.filteredEdges
      .map((e) => e.id)
      .toList(growable: false);

  @visibleForTesting
  void handleExtensionEventForTesting(Event event) {
    _handleExtensionEvent(event);
  }

  @visibleForTesting
  GraphController get graphController => _graphHost.graphController;

  @visibleForTesting
  GraphJournalController get journalControllerForTesting =>
      _graphHost.journalAdapter.controller;

  @visibleForTesting
  GraphDiagnosticsBuffer get diagnosticsForTesting =>
      _graphHost.graphController.diagnostics;

  @visibleForTesting
  Set<String> get collapsedParentIds =>
      Set<String>.unmodifiable(_collapsedParents);

  @visibleForTesting
  void handleParentTapForTesting(String parentId) {
    if (_isPanModeEnabled) return;
    _toggleParentCollapse(parentId);
  }

  @visibleForTesting
  void replaceGraphForTesting(Map<String, dynamic> payload) {
    final Size size =
        (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;
    _handleReplaceGraph(payload, size);
  }

  @visibleForTesting
  void addNodeForTesting(Map<String, dynamic> node) {
    _handleAddNode(node);
  }

  @visibleForTesting
  void addEdgeForTesting(Map<String, dynamic> edge) {
    _handleAddEdge(edge);
  }

  @visibleForTesting
  void removeNodeForTesting(
    String nodeId, {
    List<String> cascadeEdgeIds = const <String>[],
  }) {
    _handleRemoveNode(<String, Object?>{
      'id': nodeId,
      if (cascadeEdgeIds.isNotEmpty) 'cascadeEdgeIds': cascadeEdgeIds,
    });
  }

  @visibleForTesting
  void removeEdgeForTesting(String edgeId) {
    _handleRemoveEdge(<String, Object?>{'id': edgeId});
  }

  @visibleForTesting
  void patchNodeForTesting(Map<String, dynamic> node) {
    _handlePatchNode(<String, Object?>{'node': node});
  }

  @visibleForTesting
  void patchEdgeForTesting(Map<String, dynamic> edge) {
    _handlePatchEdge(<String, Object?>{'edge': edge});
  }

  @visibleForTesting
  GraphFocusController get focusControllerForTesting =>
      _graphHost.focusController;

  @override
  void dispose() {
    _graphHost.focusController.removeListener(_handleFocusChanged);
    _graphHost.dispose();
    disposeBrowserContextMenuSuppressor();
    _controller?.dispose();
    disposeViewportState();
    _vmEventBridge.dispose();
    disposeFilterAndPanelState();
    disposeJournalAndDiagnostics();
    if (_vmConnectionListener != null) {
      serviceManager.connectedState.removeListener(_vmConnectionListener!);
      _vmConnectionListener = null;
    }
    _graphPersistence.dispose();
    super.dispose();
  }

  Widget _buildGraphPanel(
    BuildContext context,
    UyavaPanelContext panelContext,
  ) {
    return GraphViewportPane(
      builder: (ctx, _) => buildGraphViewportContent(ctx, panelContext),
      panelContext: panelContext,
    );
  }

  Widget _buildDashboardPanel(
    BuildContext context,
    UyavaPanelContext panelContext,
  ) {
    return UyavaMetricsDashboard(
      controller: _graphHost.graphController,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      applyFilters: _filterAllPanels,
      compactMode: _dashboardCompactMode,
      onCompactModeChanged: (bool next) {
        if (_dashboardCompactMode == next) return;
        setState(() {
          _dashboardCompactMode = next;
        });
        _persistGraphPanelState();
      },
      pinnedMetrics: _pinnedMetricIds,
      onPinnedMetricsChanged: (Set<String> pins) {
        if (setEquals(pins, _pinnedMetricIds)) return;
        setState(() {
          _pinnedMetricIds = Set<String>.from(pins);
        });
        _persistGraphPanelState();
      },
    );
  }

  Widget _buildChainsPanel(
    BuildContext context,
    UyavaPanelContext panelContext,
  ) {
    final UyavaPanelLayoutEntry? entry = _panelShellController.entryFor(
      _chainsPanelId,
    );
    final Map<String, Object?>? extra = entry?.extraState;
    final String? storedChainId = extra != null
        ? extra['selectedChainId'] as String?
        : null;
    final String? storedAttemptKey = extra != null
        ? extra['selectedAttemptKey'] as String?
        : null;
    _chainsPanelSelectedId ??= storedChainId;
    _chainsPanelSelectedAttemptKey ??= storedAttemptKey;
    final String? initialChainId = _chainsPanelSelectedId ?? storedChainId;
    final String? initialAttemptKey =
        _chainsPanelSelectedAttemptKey ?? storedAttemptKey;

    return UyavaEventChainsPanel(
      controller: _graphHost.graphController,
      applyFilters: _filterAllPanels,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      initialChainId: initialChainId,
      initialAttemptKey: initialAttemptKey,
      onSelectionChanged: (String? chainId) {
        if (_chainsPanelSelectedId == chainId) return;
        setState(() {
          _chainsPanelSelectedId = chainId;
          if (chainId == null) {
            _chainsPanelSelectedAttemptKey = null;
          }
        });
        _persistChainsPanelState(
          chainId: chainId,
          attemptKey: _chainsPanelSelectedAttemptKey,
        );
      },
      onAttemptChanged: (String? attemptKey) {
        if (_chainsPanelSelectedAttemptKey == attemptKey) return;
        setState(() {
          _chainsPanelSelectedAttemptKey = attemptKey;
        });
        _persistChainsPanelState(
          chainId: _chainsPanelSelectedId,
          attemptKey: attemptKey,
        );
      },
      pinnedChains: _pinnedChainIds,
      onPinnedChainsChanged: (Set<String> pins) {
        if (setEquals(pins, _pinnedChainIds)) return;
        setState(() {
          _pinnedChainIds = Set<String>.from(pins);
        });
        _persistChainsPanelState(
          chainId: _chainsPanelSelectedId,
          attemptKey: _chainsPanelSelectedAttemptKey,
        );
      },
    );
  }

  Widget _buildJournalPanel(
    BuildContext context,
    UyavaPanelContext panelContext,
  ) {
    return UyavaGraphJournalPanel(
      controller: _graphHost.journalAdapter.controller,
      graphController: _graphHost.graphController,
      focusState: _graphHost.focusController.state,
      hostAdapter: _graphHost.journalAdapter,
      displayController: _graphHost.journalDisplayController,
      onLinkTap: _handleJournalLinkTap,
      onClearFocus: _graphHost.focusController.clear,
      onRemoveNodeFromFocus: _graphHost.focusController.removeNode,
      onRemoveEdgeFromFocus: _graphHost.focusController.removeEdge,
      onRevealFocus: _handleRevealFocusRequest,
      initialFocusFilterPaused: _journalFocusFilterPaused,
      onFocusFilterPausedChanged: (bool paused) {
        if (_journalFocusFilterPaused == paused) return;
        setState(() {
          _journalFocusFilterPaused = paused;
        });
        _persistJournalPanelState();
      },
      initialFocusRespectsGraphFilter: _journalRespectsGraphFilter,
      onFocusGraphFilterChanged: (bool respects) {
        if (_journalRespectsGraphFilter == respects) return;
        setState(() {
          _journalRespectsGraphFilter = respects;
        });
        _persistJournalPanelState();
      },
      onOpenDiagnosticDocs: _handleOpenDiagnosticDocs,
      initialEventsRaw: _journalEventsRaw,
      initialDiagnosticsRaw: _journalDiagnosticsRaw,
      onEventsRawChanged: (bool next) {
        if (_journalEventsRaw == next) return;
        setState(() {
          _journalEventsRaw = next;
        });
        _persistJournalPanelState();
      },
      onDiagnosticsRawChanged: (bool next) {
        if (_journalDiagnosticsRaw == next) return;
        setState(() {
          _journalDiagnosticsRaw = next;
        });
        _persistJournalPanelState();
      },
    );
  }

  Widget _buildFiltersPanel(BuildContext context) {
    return UyavaFiltersPanel(
      controller: _graphHost.graphController,
      initialFilters: _restoredFiltersFromStorage,
      filterAllPanels: _filterAllPanels,
      onFilterAllPanelsChanged: (bool next) {
        if (_filterAllPanels == next) return;
        setState(() {
          _filterAllPanels = next;
        });
        _persistFilterPanelState();
      },
      autoCompactEnabled: _autoCompactFilters,
      onAutoCompactChanged: (bool next) {
        if (_autoCompactFilters == next) return;
        setState(() {
          _autoCompactFilters = next;
          if (!_autoCompactFilters) {
            _pendingAutoCompact = false;
          }
        });
        _persistFilterPanelState();
      },
      onReset: () {
        setState(() {
          _collapsedParents.clear();
          _collapseProgress.clear();
          _autoCollapseOverrides.clear();
        });
      },
    );
  }

  void _showDiagnosticsPanel() {
    final bool wasVisible = _isPanelVisible(_journalPanelId);
    _panelShellController.setVisibility(
      _journalPanelId,
      UyavaPanelVisibility.visible,
    );
    if (!wasVisible && mounted) {
      setState(() {});
    }
    _graphHost.journalDisplayController.setActiveTab(
      GraphJournalTab.diagnostics,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget menuButton = _panelMenuController.buildMenu();

    final Widget panelShell = DevToolsSplitPanelShell(
      controller: _panelShellController,
      definitions: _panelDefinitions,
    );
    final List<Widget> topBarActions = <Widget>[
      if (_diagnosticAttentionCount > 0)
        DiagnosticsBanner(
          count: _diagnosticAttentionCount,
          onTap: _showDiagnosticsPanel,
        ),
      ..._additionalTopBarActions(),
      menuButton,
    ];

    return GraphViewScaffold(
      filtersVisible: _filtersVisible,
      filtersPanelBuilder: _buildFiltersPanel,
      topBarActions: topBarActions,
      panelShell: panelShell,
    );
  }

  List<Widget> _additionalTopBarActions() => const <Widget>[];
}
