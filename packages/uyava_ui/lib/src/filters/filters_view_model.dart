import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'filters_options_controller.dart';
import 'filters_derived_state_builder.dart';
import 'filters_form_state.dart';

/// Immutable snapshot of the filters view model.
class FiltersViewState {
  const FiltersViewState({
    required this.form,
    required this.nodeOptions,
    required this.nodeLookup,
    required this.nodeDescendants,
    required this.tagOptions,
    required this.tagLookup,
    required this.filterAllPanels,
    required this.autoCompactEnabled,
    required this.debounceEnabled,
  });

  final FiltersFormState form;
  final List<NodeFilterOption> nodeOptions;
  final Map<String, NodeFilterOption> nodeLookup;
  final Map<String, List<String>> nodeDescendants;
  final List<TagFilterOption> tagOptions;
  final Map<String, TagFilterOption> tagLookup;
  final bool filterAllPanels;
  final bool autoCompactEnabled;
  final bool debounceEnabled;

  bool get canClearFilters => form.hasActiveFilters;
}

/// Manages filter form state, auto-apply debounce, and derived options.
class FiltersViewModel {
  FiltersViewModel({
    required GraphController controller,
    GraphFilterState? initialFilters,
    bool filterAllPanels = true,
    bool autoCompactEnabled = true,
    Duration autoApplyDebounce = const Duration(milliseconds: 350),
    FiltersDerivedStateBuilder? derivedStateBuilder,
  }) : _controller = controller,
       _filterAllPanels = filterAllPanels,
       _autoCompactEnabled = autoCompactEnabled,
       _autoApplyDebounce = autoApplyDebounce,
       _derivedBuilder = derivedStateBuilder ?? FiltersDerivedStateBuilder() {
    final GraphFilterState seedState = initialFilters ?? controller.filters;
    _form = FiltersFormState.fromGraphFilterState(
      seedState,
      forceDefaults: true,
    );
    _lastFilterState = seedState;
    _lastNodesReference = controller.nodes;
    _lastMetricsReference = controller.metrics;
    _lastEventChainsReference = controller.eventChains;

    _searchController = TextEditingController(text: _form.pattern);
    _searchController.addListener(_handleSearchChanged);

    _derived = _derivedBuilder.build(
      form: _form,
      nodes: _lastNodesReference,
      metrics: _lastMetricsReference,
      eventChains: _lastEventChainsReference,
    );
    _state = FiltersViewState(
      form: _form,
      nodeOptions: _derived.nodeOptions,
      nodeLookup: _derived.nodeLookup,
      nodeDescendants: _derived.nodeDescendants,
      tagOptions: _derived.tagOptions,
      tagLookup: _derived.tagLookup,
      filterAllPanels: _filterAllPanels,
      autoCompactEnabled: _autoCompactEnabled,
      debounceEnabled: _debounceEnabled,
    );

    _stateController.add(_state);
    _subscribeToController(controller);
  }

  final Duration _autoApplyDebounce;
  final FiltersDerivedStateBuilder _derivedBuilder;
  final StreamController<FiltersViewState> _stateController =
      StreamController<FiltersViewState>.broadcast();

  late GraphController _controller;
  late FiltersFormState _form;
  late FiltersDerivedState _derived;
  late FiltersViewState _state;
  late TextEditingController _searchController;

  GraphFilterState _lastFilterState = GraphFilterState.empty;
  List<UyavaNode> _lastNodesReference = const <UyavaNode>[];
  List<GraphMetricSnapshot> _lastMetricsReference =
      const <GraphMetricSnapshot>[];
  List<GraphEventChainSnapshot> _lastEventChainsReference =
      const <GraphEventChainSnapshot>[];

  StreamSubscription<GraphFilterResult>? _filtersSubscription;
  StreamSubscription<List<GraphMetricSnapshot>>? _metricsSubscription;
  StreamSubscription<List<GraphEventChainSnapshot>>? _chainsSubscription;

  Timer? _autoApplyTimer;
  bool _filterAllPanels;
  bool _autoCompactEnabled;
  bool _debounceEnabled = true;
  bool _suppressAutoApply = false;
  bool _updatingSearchText = false;
  bool _isDisposed = false;

  FiltersViewState get state => _state;
  Stream<FiltersViewState> get stream => _stateController.stream;
  TextEditingController get searchController => _searchController;

  void applyInitialFilters(GraphFilterState? seed) {
    if (seed == null || seed == _lastFilterState) return;
    _applyState(seed, forceDefaults: true);
    _rebuildDerivedState(forceEmit: true);
  }

  void dispose() {
    _isDisposed = true;
    _filtersSubscription?.cancel();
    _metricsSubscription?.cancel();
    _chainsSubscription?.cancel();
    _autoApplyTimer?.cancel();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _stateController.close();
  }

  void replaceController(GraphController controller) {
    if (identical(_controller, controller)) return;
    _filtersSubscription?.cancel();
    _metricsSubscription?.cancel();
    _chainsSubscription?.cancel();

    _controller = controller;
    _form = FiltersFormState.fromGraphFilterState(
      controller.filters,
      forceDefaults: true,
    );
    _lastFilterState = controller.filters;
    _lastNodesReference = controller.nodes;
    _lastMetricsReference = controller.metrics;
    _lastEventChainsReference = controller.eventChains;
    _setSearchText(_form.pattern);
    _rebuildDerivedState(forceEmit: true);
    _subscribeToController(controller);
  }

  void syncPanelToggles({bool? filterAllPanels, bool? autoCompactEnabled}) {
    bool changed = false;
    if (filterAllPanels != null && filterAllPanels != _filterAllPanels) {
      _filterAllPanels = filterAllPanels;
      changed = true;
    }
    if (autoCompactEnabled != null &&
        autoCompactEnabled != _autoCompactEnabled) {
      _autoCompactEnabled = autoCompactEnabled;
      changed = true;
    }
    if (changed) {
      _emitState();
    }
  }

  void updateFilterAllPanels(bool next) {
    if (next == _filterAllPanels) return;
    _filterAllPanels = next;
    _emitState();
  }

  void updateAutoCompact(bool next) {
    if (next == _autoCompactEnabled) return;
    _autoCompactEnabled = next;
    _emitState();
  }

  void toggleDebounce() {
    _debounceEnabled = !_debounceEnabled;
    if (_debounceEnabled) {
      applyNow();
    } else {
      _autoApplyTimer?.cancel();
      _autoApplyTimer = null;
    }
    _emitState();
  }

  void applyNow() {
    _autoApplyTimer?.cancel();
    _autoApplyTimer = null;
    final GraphFilterState nextState = _form.toGraphFilterState();
    final GraphFilterUpdateResult result = _controller.updateFilters(nextState);
    _applyState(result.state, forceDefaults: false);
    _rebuildDerivedState(forceEmit: true);
  }

  void clearFilters() {
    _autoApplyTimer?.cancel();
    _autoApplyTimer = null;
    final GraphFilterState current = _controller.filters;
    final GraphFilterState next = GraphFilterState(
      search: null,
      tags: null,
      nodes: null,
      grouping: current.grouping,
      parent: current.parent,
      severity: null,
    );
    final GraphFilterUpdateResult result = _controller.updateFilters(next);
    _applyState(result.state, forceDefaults: false);
    _rebuildDerivedState(forceEmit: true);
  }

  void setPattern(String value) {
    if (value == _form.pattern) return;
    _form = _form.withPattern(value);
    _emitState();
    _onFiltersDirty();
  }

  void clearPattern() {
    if (_form.pattern.isEmpty) return;
    _setSearchText('');
    _form = _form.withPattern('');
    _emitState();
    _onFiltersDirty();
  }

  void cycleSearchMode() {
    _form = _form.cycleSearchMode();
    _emitState();
    _onFiltersDirty();
  }

  void toggleCaseSensitive() {
    _form = _form.toggleCaseSensitive();
    _emitState();
    _onFiltersDirty();
  }

  void updateSelectedTags(List<String> next) {
    _form = _form.withSelectedTags(next);
    _emitState();
    _onFiltersDirty();
  }

  void clearTags() {
    if (!_form.hasTags) return;
    _form = _form.clearTags();
    _emitState();
    _onFiltersDirty();
  }

  void cycleTagsMode() {
    _form = _form.cycleTagsMode();
    _emitState();
    _onFiltersDirty();
  }

  void cycleTagsLogic() {
    final FiltersFormState next = _form.cycleTagsLogic();
    if (identical(next, _form)) return;
    _form = next;
    _emitState();
    _onFiltersDirty();
  }

  void toggleNodeMode() {
    _form = _form.toggleNodeMode();
    _emitState();
    _onFiltersDirty();
  }

  void updateSelectedNodeIds(List<String> next) {
    _form = _form.withSelectedNodeIds(next);
    _emitState();
    _onFiltersDirty();
  }

  void clearNodes() {
    if (!_form.hasNodes) return;
    _form = _form.clearNodes();
    _emitState();
    _onFiltersDirty();
  }

  void setSeverity(UyavaSeverity? severity) {
    _form = _form.withSeverity(severity);
    _emitState();
    _onFiltersDirty();
  }

  void clearSeverity() {
    if (!_form.hasSeverity) return;
    _form = _form.clearSeverity();
    _emitState();
    _onFiltersDirty();
  }

  void cycleSeverityOperator() {
    _form = _form.withSeverityOperator(
      _nextSeverityOperator(_form.severityOperator),
    );
    _emitState();
    if (_form.hasSeverity) {
      _onFiltersDirty();
    }
  }

  void _handleSearchChanged() {
    if (_isDisposed || _updatingSearchText) return;
    final String text = _searchController.text;
    if (text != _form.pattern) {
      _form = _form.withPattern(text);
    }
    _emitState();
    _onFiltersDirty();
  }

  void _onFiltersDirty() {
    if (_suppressAutoApply || !_debounceEnabled || _isDisposed) return;
    _scheduleAutoApply();
  }

  void _scheduleAutoApply() {
    _autoApplyTimer?.cancel();
    _autoApplyTimer = Timer(_autoApplyDebounce, () {
      _autoApplyTimer = null;
      if (_isDisposed) return;
      applyNow();
    });
  }

  void _applyState(GraphFilterState state, {required bool forceDefaults}) {
    _autoApplyTimer?.cancel();
    _autoApplyTimer = null;
    _suppressAutoApply = true;
    try {
      _lastFilterState = state;
      final FiltersFormState next = FiltersFormState.fromGraphFilterState(
        state,
        fallback: forceDefaults ? null : _form,
        forceDefaults: forceDefaults,
      );
      _form = next;
      _setSearchText(next.pattern);
    } finally {
      _suppressAutoApply = false;
    }
  }

  void _subscribeToController(GraphController controller) {
    _filtersSubscription?.cancel();
    _metricsSubscription?.cancel();
    _chainsSubscription?.cancel();

    _filtersSubscription = controller.filtersStream.listen((
      GraphFilterResult result,
    ) {
      final GraphFilterState nextState = result.state;
      final bool nodesChanged = !identical(
        controller.nodes,
        _lastNodesReference,
      );
      final bool stateChanged = nextState != _lastFilterState;
      if (!stateChanged && !nodesChanged) return;
      _applyState(nextState, forceDefaults: false);
      _lastNodesReference = controller.nodes;
      _rebuildDerivedState(forceEmit: true);
    });

    _metricsSubscription = controller.metricsStream.listen((
      List<GraphMetricSnapshot> snapshots,
    ) {
      if (_isDisposed) return;
      _lastMetricsReference = snapshots;
      _rebuildDerivedState(forceEmit: true);
    });

    _chainsSubscription = controller.eventChainsStream.listen((
      List<GraphEventChainSnapshot> snapshots,
    ) {
      if (_isDisposed) return;
      _lastEventChainsReference = snapshots;
      _rebuildDerivedState(forceEmit: true);
    });
  }

  void _setSearchText(String text) {
    if (_searchController.text == text) return;
    _updatingSearchText = true;
    _searchController.value = _searchController.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
    _updatingSearchText = false;
  }

  void _rebuildDerivedState({required bool forceEmit}) {
    _lastNodesReference = _controller.nodes;
    _lastMetricsReference = _controller.metrics;
    _lastEventChainsReference = _controller.eventChains;
    final FiltersDerivedState derived = _derivedBuilder.build(
      form: _form,
      nodes: _lastNodesReference,
      metrics: _lastMetricsReference,
      eventChains: _lastEventChainsReference,
    );
    final bool formChanged = !identical(_form, derived.form);
    _form = derived.form;
    _derived = derived;
    if (forceEmit || formChanged) {
      _emitState();
    }
  }

  void _emitState() {
    if (_isDisposed) return;
    _state = FiltersViewState(
      form: _form,
      nodeOptions: _derived.nodeOptions,
      nodeLookup: _derived.nodeLookup,
      nodeDescendants: _derived.nodeDescendants,
      tagOptions: _derived.tagOptions,
      tagLookup: _derived.tagLookup,
      filterAllPanels: _filterAllPanels,
      autoCompactEnabled: _autoCompactEnabled,
      debounceEnabled: _debounceEnabled,
    );
    _stateController.add(_state);
  }

  UyavaFilterSeverityOperator _nextSeverityOperator(
    UyavaFilterSeverityOperator current,
  ) {
    final List<UyavaFilterSeverityOperator> values =
        UyavaFilterSeverityOperator.values;
    final int index = values.indexOf(current);
    final int next = (index + 1) % values.length;
    return values[next];
  }
}
