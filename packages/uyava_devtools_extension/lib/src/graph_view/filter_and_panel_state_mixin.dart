part of '../../graph_view_page.dart';

// ignore_for_file: library_private_types_in_public_api

mixin FilterAndPanelStateMixin on _DevToolsGraphViewCoordinatorCore {
  GraphFilterState? _pendingFiltersFromStorage;
  bool _graphControllerReady = false;
  bool _filterAllPanels = true;
  bool _autoCompactFilters = true;
  bool _pendingAutoCompact = false;
  bool _suppressNextAutoCompact = false;
  bool _filtersVisible = true;
  bool _tagLegendExpanded = true;
  GraphFilterState _lastFilterState = GraphFilterState.empty;
  bool _journalFocusFilterPaused = false;
  bool _journalRespectsGraphFilter = true;
  bool _journalEventsRaw = false;
  bool _journalDiagnosticsRaw = false;
  late final UyavaPanelShellController _panelShellController;
  late UyavaPanelShellSnapshot _panelShellSnapshot;
  late final UyavaPanelShellViewAdapter _panelShellAdapter;
  late final UyavaPanelPresetContent _panelPresetContent;
  late final List<UyavaPanelDefinition> _panelDefinitions;
  late final List<UyavaPanelMenuToggle> _panelMenuToggles;
  UyavaPanelLayoutPreset _panelLayoutPreset =
      UyavaPanelLayoutPreset.graphWithDetails;
  bool _dashboardCompactMode = false;
  Set<String> _pinnedMetricIds = <String>{};
  Set<String> _pinnedChainIds = <String>{};
  GraphFilterState? _restoredFiltersFromStorage;
  String? _chainsPanelSelectedId;
  String? _chainsPanelSelectedAttemptKey;
  StreamSubscription? _filtersSubscription;
  late UyavaPanelMenuController _panelMenuController;

  void disposeFilterAndPanelState() {
    _filtersSubscription?.cancel();
    _panelShellController.detachAdapter(_panelShellAdapter);
    _panelShellController.dispose();
  }

  @visibleForTesting
  bool get isDashboardPanelVisible => _isPanelVisible(_dashboardPanelId);

  @visibleForTesting
  bool get isChainsPanelVisible => _isPanelVisible(_chainsPanelId);

  @visibleForTesting
  UyavaPanelLayoutPreset get panelLayoutPreset => _panelLayoutPreset;

  @visibleForTesting
  String get panelLayoutConfigurationId => panelPresetId(_panelLayoutPreset);

  @visibleForTesting
  UyavaPanelLayoutStorage get panelLayoutStorage =>
      _graphPersistence.panelLayoutStorage;

  @visibleForTesting
  void setFiltersScopeForTesting(bool applyAllPanels) {
    if (_filterAllPanels == applyAllPanels) return;
    setState(() {
      _filterAllPanels = applyAllPanels;
    });
    _persistFilterPanelState();
  }

  @visibleForTesting
  void setAutoCompactFiltersForTesting(bool enabled) {
    if (_autoCompactFilters == enabled) return;
    setState(() {
      _autoCompactFilters = enabled;
      if (!_autoCompactFilters) {
        _pendingAutoCompact = false;
      }
    });
    _persistFilterPanelState();
  }

  UyavaPanelShellSpec _specForPanelPreset(UyavaPanelLayoutPreset preset) {
    return buildPanelPresetSpec(preset: preset, content: _panelPresetContent);
  }

  void _applyPanelPreset(
    UyavaPanelLayoutPreset preset, {
    bool fromStorage = false,
  }) {
    final changed = _panelLayoutPreset != preset;
    _panelLayoutPreset = preset;
    _panelShellController.setConfigurationId(panelPresetId(preset));
    _panelShellController.updateSpec(_specForPanelPreset(preset));
    if ((changed || fromStorage) && mounted) {
      setState(() {});
    }
  }

  void _handlePanelShellSnapshot(UyavaPanelShellSnapshot snapshot) {
    if (!mounted) {
      _panelShellSnapshot = snapshot;
      return;
    }
    setState(() {
      _panelShellSnapshot = snapshot;
    });
  }

  Future<void> _restorePersistedPanelLayout() async {
    _restoredFiltersFromStorage = null;
    final persisted = await _graphPersistence.restorePanelLayout();
    if (!mounted) return;
    if (persisted != null) {
      GraphFilterState? storedFilters;
      bool? storedFilterAllPanels;
      bool? storedAutoCompactFilters;
      bool? storedFiltersVisible;
      bool? storedTagLegendExpanded;
      bool? storedDashboardCompactMode;
      bool? storedJournalEventsRaw;
      bool? storedJournalDiagnosticsRaw;
      String? storedChainsPanelId;
      String? storedChainsAttemptKey;
      Set<String>? storedPinnedMetrics;
      Set<String>? storedPinnedChains;
      for (final UyavaPanelLayoutEntry entry in persisted.entries) {
        if (entry.id == _filtersPanelId) {
          final Map<String, Object?>? extra = entry.extraState;
          if (extra == null) {
            continue;
          }
          final Object? rawFilters = extra['filters'];
          storedFilters = _graphHost.decodeFilterState(rawFilters);
          final Object? rawFilterAll = extra['filterAllPanels'];
          if (rawFilterAll is bool) {
            storedFilterAllPanels = rawFilterAll;
          }
          final Object? rawFiltersVisible = extra['filtersVisible'];
          if (rawFiltersVisible is bool) {
            storedFiltersVisible = rawFiltersVisible;
          }
          final Object? rawAutoCompact = extra['autoCompactFilters'];
          if (rawAutoCompact is bool) {
            storedAutoCompactFilters = rawAutoCompact;
          }
        } else if (entry.id == _graphPanelId) {
          final Map<String, Object?>? extra = entry.extraState;
          if (extra == null) {
            continue;
          }
          final Object? rawExpanded = extra['tagLegendExpanded'];
          if (rawExpanded is bool) {
            storedTagLegendExpanded = rawExpanded;
          }
          final Object? rawCompact = extra['dashboardCompactMode'];
          if (rawCompact is bool) {
            storedDashboardCompactMode = rawCompact;
          }
          final Object? rawPinned = extra['pinnedMetrics'];
          if (rawPinned is List<Object?>) {
            final Set<String> pins = <String>{};
            for (final Object? value in rawPinned) {
              if (value is String && value.isNotEmpty) {
                pins.add(value);
              }
            }
            storedPinnedMetrics = pins;
          }
        } else if (entry.id == _journalPanelId) {
          final Map<String, Object?>? extra = entry.extraState;
          if (extra == null) {
            continue;
          }
          final Object? rawEventsRaw = extra['eventsRaw'];
          if (rawEventsRaw is bool) {
            storedJournalEventsRaw = rawEventsRaw;
          }
          final Object? rawDiagnosticsRaw = extra['diagnosticsRaw'];
          if (rawDiagnosticsRaw is bool) {
            storedJournalDiagnosticsRaw = rawDiagnosticsRaw;
          }
        } else if (entry.id == _chainsPanelId) {
          final Map<String, Object?>? extra = entry.extraState;
          if (extra == null) {
            continue;
          }
          final Object? rawChainId = extra['selectedChainId'];
          if (rawChainId is String && rawChainId.isNotEmpty) {
            storedChainsPanelId = rawChainId;
          }
          final Object? rawAttempt = extra['selectedAttemptKey'];
          if (rawAttempt is String && rawAttempt.isNotEmpty) {
            storedChainsAttemptKey = rawAttempt;
          }
          final Object? rawPinnedChains = extra['pinnedChains'];
          if (rawPinnedChains is List<Object?>) {
            final Set<String> pins = <String>{};
            for (final Object? value in rawPinnedChains) {
              if (value is String && value.isNotEmpty) {
                pins.add(value);
              }
            }
            storedPinnedChains = pins;
          }
        }
      }
      if (storedFilterAllPanels != null) {
        _filterAllPanels = storedFilterAllPanels;
      }
      if (storedAutoCompactFilters != null) {
        _autoCompactFilters = storedAutoCompactFilters;
      }
      if (storedFiltersVisible != null) {
        _filtersVisible = storedFiltersVisible;
      }
      if (storedTagLegendExpanded != null) {
        _tagLegendExpanded = storedTagLegendExpanded;
      }
      if (storedDashboardCompactMode != null) {
        _dashboardCompactMode = storedDashboardCompactMode;
      }
      if (storedJournalEventsRaw != null) {
        _journalEventsRaw = storedJournalEventsRaw;
      }
      if (storedJournalDiagnosticsRaw != null) {
        _journalDiagnosticsRaw = storedJournalDiagnosticsRaw;
      }
      if (storedPinnedMetrics != null) {
        _pinnedMetricIds = storedPinnedMetrics;
      }
      if (storedPinnedChains != null) {
        _pinnedChainIds = storedPinnedChains;
      }
      _chainsPanelSelectedId = storedChainsPanelId;
      _chainsPanelSelectedAttemptKey = storedChainsAttemptKey;
      if (storedFilters != null) {
        _suppressNextAutoCompact = true;
        _restoredFiltersFromStorage = storedFilters;
        _pendingFiltersFromStorage = storedFilters;
        _applyPendingFilters();
      }
      final preset = panelPresetForId(persisted.configurationId);
      _applyPanelPreset(preset, fromStorage: true);
      _panelShellController.restoreState(persisted);
      if (persisted.configurationId == null) {
        _panelShellController.setConfigurationId(panelPresetId(preset));
      }
    } else {
      _chainsPanelSelectedId = null;
      _chainsPanelSelectedAttemptKey = null;
      _panelShellController.setConfigurationId(
        panelPresetId(_panelLayoutPreset),
      );
    }
  }

  void _handlePanelLayoutChanged(UyavaPanelLayoutState state) {
    _graphPersistence.persistPanelLayout(state);
  }

  void _persistFilterPanelState({GraphFilterState? state}) {
    final GraphFilterState snapshot =
        state ?? _graphHost.graphController.filters;
    final Map<String, Object?>? encoded = _graphHost.encodeFilterState(
      snapshot,
    );
    final Map<String, Object?> extraState = <String, Object?>{
      if (encoded != null) 'filters': encoded,
      'filterAllPanels': _filterAllPanels,
      'autoCompactFilters': _autoCompactFilters,
      'filtersVisible': _filtersVisible,
    };
    _panelShellController.setExtraState(_filtersPanelId, extraState);
  }

  void _setFiltersVisible(bool next) {
    if (_filtersVisible == next) return;
    setState(() {
      _filtersVisible = next;
    });
    _persistFilterPanelState();
  }

  void _persistGraphPanelState() {
    final Map<String, Object?> extraState = <String, Object?>{
      'tagLegendExpanded': _tagLegendExpanded,
      'dashboardCompactMode': _dashboardCompactMode,
      'pinnedMetrics': _pinnedMetricIds.toList(),
    };
    _panelShellController.setExtraState(_graphPanelId, extraState);
  }

  void _persistJournalPanelState() {
    final Map<String, Object?> extraState = <String, Object?>{
      'eventsRaw': _journalEventsRaw,
      'diagnosticsRaw': _journalDiagnosticsRaw,
    };
    _panelShellController.setExtraState(_journalPanelId, extraState);
  }

  void _persistChainsPanelState({String? chainId, String? attemptKey}) {
    final Map<String, Object?> extraState = <String, Object?>{
      if (chainId != null && chainId.isNotEmpty) 'selectedChainId': chainId,
      if (attemptKey != null && attemptKey.isNotEmpty)
        'selectedAttemptKey': attemptKey,
      if (_pinnedChainIds.isNotEmpty) 'pinnedChains': _pinnedChainIds.toList(),
    };
    if (extraState.isEmpty) {
      _panelShellController.setExtraState(_chainsPanelId, null);
    } else {
      _panelShellController.setExtraState(_chainsPanelId, extraState);
    }
  }

  void _handleTagLegendExpandedChanged(bool next) {
    if (_tagLegendExpanded == next) return;
    setState(() {
      _tagLegendExpanded = next;
    });
    _persistGraphPanelState();
  }

  void _applyGroupingLevel(int? level) {
    final GraphFilterState current = _graphHost.graphController.filters;
    final GraphFilterGrouping? currentGrouping = current.grouping;
    final bool reapplySameLevel =
        level != null &&
        currentGrouping?.mode == UyavaFilterGroupingMode.level &&
        currentGrouping?.levelDepth == level;
    if (reapplySameLevel) {
      final GraphFilterState cleared = GraphFilterState(
        search: current.search,
        tags: current.tags,
        nodes: current.nodes,
        parent: current.parent,
        grouping: null,
      );
      _graphHost.graphController.updateFilters(cleared);
    }
    GraphFilterGrouping? grouping;
    if (level != null) {
      grouping = GraphFilterGrouping(
        mode: UyavaFilterGroupingMode.level,
        levelDepth: level,
      );
    }
    final GraphFilterState next = GraphFilterState(
      search: current.search,
      tags: current.tags,
      nodes: current.nodes,
      parent: current.parent,
      grouping: grouping,
    );
    if (!reapplySameLevel && next == current) return;
    final GraphFilterUpdateResult result = _graphHost.graphController
        .updateFilters(next);
    _persistFilterPanelState(state: result.state);
  }

  void _applyPendingFilters() {
    if (!_graphControllerReady) return;
    final GraphFilterState? pending = _pendingFiltersFromStorage;
    if (pending == null) return;
    _pendingFiltersFromStorage = null;
    _suppressNextAutoCompact = true;
    _graphHost.graphController.updateFilters(pending);
  }

  bool _isPanelVisible(UyavaPanelId id) {
    for (final entry in _panelShellSnapshot.state.entries) {
      if (entry.id == id) {
        final visibility =
            entry.visibility ??
            _panelShellController.registryFor(id)?.defaultVisibility ??
            UyavaPanelVisibility.visible;
        return visibility == UyavaPanelVisibility.visible;
      }
    }
    final defaultVisibility =
        _panelShellController.registryFor(id)?.defaultVisibility ??
        UyavaPanelVisibility.visible;
    return defaultVisibility == UyavaPanelVisibility.visible;
  }

  void _togglePanelVisibility(UyavaPanelId id) {
    final nextVisibility = _isPanelVisible(id)
        ? UyavaPanelVisibility.hidden
        : UyavaPanelVisibility.visible;
    _panelShellController.setVisibility(id, nextVisibility);
    setState(() {
      // Rebuild AppBar actions to reflect new toggle states.
    });
  }

  Map<String, Object?> _filtersSummary() {
    final GraphFilterState filters = _graphHost.graphController.filters;
    final GraphFilterNodeSet? nodes = filters.nodes;
    return <String, Object?>{
      'hasSearch': filters.search != null,
      'tags': filters.tags?.values.length ?? 0,
      'nodesInclude': nodes?.include.length ?? 0,
      'nodesExclude': nodes?.exclude.length ?? 0,
      'severity': filters.severity?.level.name,
      'grouping': filters.grouping?.mode.name,
      'respectsGraphFilter': _journalRespectsGraphFilter,
    };
  }

  Map<String, Object?> _panelSummary() {
    return <String, Object?>{
      'layoutId': _panelShellController.state.configurationId,
      'journalTab': _graphHost.journalDisplayController.activeTab.name,
      'filtersVisible': _filtersVisible,
      'dashboardVisible': _isPanelVisible(_dashboardPanelId),
      'chainsVisible': _isPanelVisible(_chainsPanelId),
      'journalVisible': _isPanelVisible(_journalPanelId),
    };
  }

  List<UyavaPanelMenuToggle> _buildPanelMenuToggles() {
    return _panelDefinitions
        .where((definition) => definition.id != _graphPanelId)
        .map(
          (definition) => _visibilityToggle(
            id: definition.id,
            label: '${definition.title} panel',
          ),
        )
        .toList();
  }

  UyavaPanelMenuToggle _visibilityToggle({
    required UyavaPanelId id,
    required String label,
  }) {
    return UyavaPanelMenuToggle(
      id: id,
      label: label,
      isChecked: () => _isPanelVisible(id),
      onToggle: () => _togglePanelVisibility(id),
    );
  }
}
