import 'panel_contract.dart';

typedef UyavaPanelShellListener = void Function();

class UyavaPanelShellController {
  UyavaPanelShellController({
    required List<UyavaPanelRegistryEntry> registry,
    required UyavaPanelShellSpec spec,
    UyavaPanelLayoutState? persistedState,
    UyavaPanelShellViewAdapter? viewAdapter,
    String layoutSchemaId = kDefaultPanelLayoutSchemaId,
    String filtersSchemaId = kDefaultFiltersSchemaId,
  }) : assert(layoutSchemaId.isNotEmpty, 'layoutSchemaId must not be empty.'),
       assert(filtersSchemaId.isNotEmpty, 'filtersSchemaId must not be empty.'),
       _registry = Map.unmodifiable({
         for (final entry in registry) entry.id: entry,
       }),
       _layoutSchemaId = layoutSchemaId,
       _filtersSchemaId = filtersSchemaId,
       _viewAdapter = viewAdapter {
    _spec = spec;
    _state = _mergeState(persistedState);
    _snapshot = UyavaPanelShellSnapshot(spec: _spec, state: _state);
    final adapter = _viewAdapter;
    if (adapter != null) {
      adapter.didUpdateSnapshot(_snapshot);
      adapter.handlePersistedState(_state);
    }
  }

  final Map<UyavaPanelId, UyavaPanelRegistryEntry> _registry;
  final String _layoutSchemaId;
  final String _filtersSchemaId;
  final List<UyavaPanelShellListener> _listeners = [];
  UyavaPanelShellViewAdapter? _viewAdapter;

  late UyavaPanelShellSpec _spec;
  late UyavaPanelLayoutState _state;
  late UyavaPanelShellSnapshot _snapshot;

  static String _slotStorageKey(UyavaPanelSlot slot) {
    return slot.map(
      leaf: (leaf) => 'panel:${leaf.id.value}',
      split: (split) => 'split:${split.key}',
    );
  }

  /// Current effective layout state.
  UyavaPanelLayoutState get state => _state;

  /// The structural specification describing how panels are arranged.
  UyavaPanelShellSpec get spec => _spec;

  /// Latest combined snapshot consumed by adapters.
  UyavaPanelShellSnapshot get snapshot => _snapshot;

  /// Returns metadata for the given panel id if registered.
  UyavaPanelRegistryEntry? registryFor(UyavaPanelId id) => _registry[id];

  /// Returns the persisted entry for a panel if available.
  UyavaPanelLayoutEntry? entryFor(UyavaPanelId id) {
    for (final entry in _state.entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Returns the resolved visibility for a panel.
  UyavaPanelVisibility visibilityFor(UyavaPanelId id) {
    final entry = entryFor(id);
    final definition = _registry[id];
    return entry?.visibility ??
        definition?.defaultVisibility ??
        UyavaPanelVisibility.visible;
  }

  /// Returns the resolved split fraction for a panel.
  double splitFractionFor(UyavaPanelId id, int siblingCount) =>
      splitFractionForSlot(UyavaPanelLeaf(id), siblingCount);

  double splitFractionForSlot(UyavaPanelSlot slot, int siblingCount) {
    final key = _slotStorageKey(slot);
    final storedSlot = _state.splitFractions[key];
    if (storedSlot != null && storedSlot > 0) {
      return storedSlot;
    }
    return slot.map(
      leaf: (leaf) {
        final storedLeaf = entryFor(leaf.id)?.splitFraction;
        if (storedLeaf != null && storedLeaf > 0) {
          return storedLeaf;
        }
        return siblingCount <= 0 ? 1 : 1 / siblingCount;
      },
      split: (_) => siblingCount <= 0 ? 1 : 1 / siblingCount,
    );
  }

  /// Updates visibility for a panel and notifies listeners.
  void setVisibility(UyavaPanelId id, UyavaPanelVisibility visibility) {
    if (visibilityFor(id) == visibility) return;
    _updateEntry(
      id,
      (entry) => entry.copyWith(visibility: visibility),
      () => UyavaPanelLayoutEntry(id: id, visibility: visibility),
    );
  }

  /// Updates stored fractional size for a panel in its split group.
  void setSplitFraction(UyavaPanelId id, double fraction) {
    setSlotFraction(UyavaPanelLeaf(id), fraction);
  }

  /// Updates stored fractional size for a slot (panel leaf or nested split).
  void setSlotFraction(UyavaPanelSlot slot, double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    final key = _slotStorageKey(slot);
    var changed = false;
    final entries = List<UyavaPanelLayoutEntry>.of(_state.entries);
    if (slot is UyavaPanelLeaf) {
      final index = entries.indexWhere((entry) => entry.id == slot.id);
      if (index >= 0) {
        final existing = entries[index];
        if (existing.splitFraction == null ||
            (existing.splitFraction! - clamped).abs() >= 1e-6) {
          entries[index] = existing.copyWith(splitFraction: clamped);
          changed = true;
        }
      } else {
        entries.add(
          UyavaPanelLayoutEntry(
            id: slot.id,
            splitFraction: clamped,
            order: entries.length,
          ),
        );
        changed = true;
      }
    }

    final fractions = Map<String, double>.from(_state.splitFractions);
    final current = fractions[key];
    if (current == null || (current - clamped).abs() >= 1e-6) {
      fractions[key] = clamped;
      changed = true;
    }
    if (!changed) {
      return;
    }

    entries.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    _setState(
      UyavaPanelLayoutState(
        entries: entries,
        focusedPanel: _state.focusedPanel,
        splitFractions: fractions,
        configurationId: _state.configurationId,
        layoutSchemaId: _state.layoutSchemaId,
        filtersSchemaId: _state.filtersSchemaId,
      ),
    );
  }

  /// Persists an arbitrary extra state payload for the given panel.
  void setExtraState(UyavaPanelId id, Map<String, Object?>? extraState) {
    final Map<String, Object?>? sanitized =
        extraState == null || extraState.isEmpty
        ? null
        : Map<String, Object?>.from(extraState);
    _updateEntry(
      id,
      (entry) => entry.copyWith(extraState: sanitized),
      () => UyavaPanelLayoutEntry(id: id, extraState: sanitized),
    );
  }

  /// Persists the focus ownership to the given panel.
  void setFocusedPanel(UyavaPanelId? id) {
    if (_state.focusedPanel == id) return;
    _setState(
      UyavaPanelLayoutState(
        entries: _state.entries,
        focusedPanel: id,
        splitFractions: _state.splitFractions,
        configurationId: _state.configurationId,
        layoutSchemaId: _state.layoutSchemaId,
        filtersSchemaId: _state.filtersSchemaId,
      ),
      persist: false,
    );
  }

  /// Replaces the current state with the merged result of [persisted] and the
  /// structural specification. Useful when persisted layouts load
  /// asynchronously.
  void restoreState(UyavaPanelLayoutState? persisted) {
    final merged = _mergeState(persisted);
    if (_state == merged) {
      return;
    }
    _setState(merged);
  }

  /// Updates the structural specification while preserving compatible state.
  void updateSpec(UyavaPanelShellSpec spec) {
    if (identical(_spec, spec)) {
      return;
    }
    _spec = spec;
    final merged = _mergeState(_state);
    if (_state == merged) {
      _emitSnapshot();
      return;
    }
    _setState(merged);
  }

  /// Persists the currently selected layout configuration identifier.
  void setConfigurationId(String? configurationId) {
    if (_state.configurationId == configurationId) {
      return;
    }
    _setState(
      UyavaPanelLayoutState(
        entries: _state.entries,
        focusedPanel: _state.focusedPanel,
        splitFractions: _state.splitFractions,
        configurationId: configurationId,
        layoutSchemaId: _state.layoutSchemaId,
        filtersSchemaId: _state.filtersSchemaId,
      ),
    );
  }

  /// Adds a listener that is invoked whenever the controller emits a new
  /// snapshot. Listeners are invoked synchronously in the order they were
  /// registered.
  void addListener(UyavaPanelShellListener listener) {
    if (_listeners.contains(listener)) {
      return;
    }
    _listeners.add(listener);
  }

  /// Removes a previously registered [listener].
  void removeListener(UyavaPanelShellListener listener) {
    _listeners.remove(listener);
  }

  /// Attaches a view adapter that will receive snapshot updates. If
  /// [replaySnapshot] is true (default), the current snapshot is sent
  /// immediately.
  void attachAdapter(
    UyavaPanelShellViewAdapter adapter, {
    bool replaySnapshot = true,
  }) {
    _viewAdapter = adapter;
    if (replaySnapshot) {
      adapter.didUpdateSnapshot(_snapshot);
      adapter.handlePersistedState(_state);
    }
  }

  /// Detaches the given [adapter] if currently attached.
  void detachAdapter(UyavaPanelShellViewAdapter adapter) {
    if (identical(_viewAdapter, adapter)) {
      _viewAdapter = null;
    }
  }

  /// Disposes the controller and notifies the attached adapter.
  void dispose() {
    final adapter = _viewAdapter;
    if (adapter != null) {
      adapter.handleControllerDisposed();
    }
    _viewAdapter = null;
    _listeners.clear();
  }

  UyavaPanelLayoutState _mergeState(UyavaPanelLayoutState? persisted) {
    final entriesById = <UyavaPanelId, UyavaPanelLayoutEntry>{};
    if (persisted != null) {
      for (final entry in persisted.entries) {
        entriesById[entry.id] = entry;
      }
    }
    final mergedEntries = <UyavaPanelLayoutEntry>[];
    final validSplitKeys = <String>{};
    var order = 0;
    void visit(UyavaPanelSlot slot) {
      validSplitKeys.add(_slotStorageKey(slot));
      slot.map(
        leaf: (leaf) {
          final definition = _registry[leaf.id];
          if (definition == null) return;
          final persistedEntry = entriesById[leaf.id];
          final entry =
              persistedEntry ??
              UyavaPanelLayoutEntry(
                id: leaf.id,
                visibility: definition.defaultVisibility,
              );
          mergedEntries.add(entry.copyWith(order: entry.order ?? order));
          order++;
        },
        split: (split) {
          for (final child in split.children) {
            visit(child);
          }
        },
      );
    }

    visit(_spec.root);
    mergedEntries.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    final persistedFractions = persisted?.splitFractions ?? const {};
    final filteredFractions = <String, double>{};
    for (final key in validSplitKeys) {
      final value = persistedFractions[key];
      if (value != null) {
        filteredFractions[key] = value;
      }
    }

    final String layoutSchemaId = persisted?.layoutSchemaId ?? _layoutSchemaId;
    final String filtersSchemaId =
        persisted?.filtersSchemaId ?? _filtersSchemaId;

    return UyavaPanelLayoutState(
      entries: mergedEntries,
      focusedPanel: persisted?.focusedPanel,
      splitFractions: filteredFractions,
      configurationId: persisted?.configurationId,
      layoutSchemaId: layoutSchemaId,
      filtersSchemaId: filtersSchemaId,
    );
  }

  void _updateEntry(
    UyavaPanelId id,
    UyavaPanelLayoutEntry Function(UyavaPanelLayoutEntry) update,
    UyavaPanelLayoutEntry Function() create,
  ) {
    final entries = List<UyavaPanelLayoutEntry>.of(_state.entries);
    final index = entries.indexWhere((entry) => entry.id == id);
    if (index >= 0) {
      final updated = update(entries[index]);
      if (entries[index] == updated) {
        return;
      }
      entries[index] = updated;
    } else {
      final created = update(create());
      final withOrder = created.copyWith(
        order: created.order ?? entries.length,
      );
      entries.add(withOrder);
    }

    entries.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    final newState = UyavaPanelLayoutState(
      entries: entries,
      focusedPanel: _state.focusedPanel,
      splitFractions: _state.splitFractions,
      configurationId: _state.configurationId,
      layoutSchemaId: _state.layoutSchemaId,
      filtersSchemaId: _state.filtersSchemaId,
    );
    if (newState == _state) {
      return;
    }
    _setState(newState);
  }

  void _setState(UyavaPanelLayoutState newState, {bool persist = true}) {
    if (_state == newState) {
      if (!persist) {
        _emitSnapshot(persist: false);
      }
      return;
    }
    _state = newState;
    _emitSnapshot(persist: persist);
  }

  void _emitSnapshot({bool persist = true}) {
    _snapshot = UyavaPanelShellSnapshot(spec: _spec, state: _state);
    if (_listeners.isNotEmpty) {
      final listeners = List<UyavaPanelShellListener>.of(_listeners);
      for (final listener in listeners) {
        listener();
      }
    }
    final adapter = _viewAdapter;
    if (adapter != null) {
      adapter.didUpdateSnapshot(_snapshot);
      if (persist) {
        adapter.handlePersistedState(_state);
      }
    }
  }
}
