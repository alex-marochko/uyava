import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:uyava_core/uyava_core.dart';

class EventChainsViewModel extends ChangeNotifier {
  EventChainsViewModel({
    required GraphController controller,
    bool applyFilters = true,
    String? initialChainId,
    String? initialAttemptKey,
    Set<String> pinnedChains = const <String>{},
  }) : _controller = controller,
       _applyFilters = applyFilters,
       _selectedChainId = initialChainId,
       _selectedAttemptKey = initialAttemptKey,
       _pinnedChains = Set<String>.of(pinnedChains) {
    _chains = _currentChains();
    _syncSelection();
    _chainsSub = _controller.eventChainsStream.listen(_handleChainsUpdate);
    _filtersSub = _controller.filtersStream.listen(_handleFiltersChange);
  }

  final GraphController _controller;
  bool _applyFilters;
  late List<GraphEventChainSnapshot> _chains;
  Set<String> _pinnedChains;
  String? _selectedChainId;
  String? _selectedAttemptKey;

  StreamSubscription<List<GraphEventChainSnapshot>>? _chainsSub;
  StreamSubscription<GraphFilterResult>? _filtersSub;

  UnmodifiableListView<EventChainViewData> get chainViews {
    final List<GraphEventChainSnapshot> ordered = _orderedChains();
    final List<EventChainViewData> views = <EventChainViewData>[
      for (final GraphEventChainSnapshot chain in ordered)
        EventChainViewData(
          snapshot: chain,
          progressLabel: _progressLabelForChain(chain),
          isSelected: chain.id == _selectedChainId,
          pinned: _pinnedChains.contains(chain.id),
          selectedAttemptKey: chain.id == _selectedChainId
              ? _selectedAttemptKey
              : null,
          attempts: _attemptViewData(chain),
          selectedAttempt: chain.id == _selectedChainId
              ? _attemptForKey(chain, _selectedAttemptKey)
              : null,
        ),
    ];
    return UnmodifiableListView<EventChainViewData>(views);
  }

  bool get hasChains => _chains.isNotEmpty;

  bool get canResetAll => _chains.any(
    (GraphEventChainSnapshot chain) =>
        chain.successCount > 0 ||
        chain.failureCount > 0 ||
        chain.activeAttempts.isNotEmpty,
  );

  String? get selectedChainId => _selectedChainId;

  String? get selectedAttemptKey => _selectedAttemptKey;

  Set<String> get pinnedChainIds => Set.unmodifiable(_pinnedChains);

  void toggleChainSelection(String chainId) {
    if (_selectedChainId == chainId) {
      _selectedChainId = null;
      _selectedAttemptKey = null;
    } else {
      _selectedChainId = chainId;
      _selectedAttemptKey = null;
      final GraphEventChainSnapshot? chain = _selectedChain;
      if (chain != null) {
        _syncAttemptSelection(chain);
      }
    }
    notifyListeners();
  }

  void selectAttempt(String key) {
    if (_selectedChainId == null || key == _selectedAttemptKey) return;
    _selectedAttemptKey = key;
    notifyListeners();
  }

  void togglePin(String chainId) {
    if (_pinnedChains.contains(chainId)) {
      _pinnedChains.remove(chainId);
    } else {
      _pinnedChains.add(chainId);
    }
    notifyListeners();
  }

  void setPinnedChains(Set<String> pinned) {
    if (setEquals(_pinnedChains, pinned)) return;
    _pinnedChains = Set<String>.of(pinned);
    notifyListeners();
  }

  void setApplyFilters(bool applyFilters) {
    if (_applyFilters == applyFilters) return;
    _applyFilters = applyFilters;
    _refreshChains();
  }

  void setSelectionFromHost(String? chainId, String? attemptKey) {
    _selectedChainId = chainId;
    _selectedAttemptKey = attemptKey;
    if (_selectedChainId != null) {
      final GraphEventChainSnapshot? chain = _selectedChain;
      if (chain != null) {
        _syncAttemptSelection(chain);
      } else {
        _selectedChainId = null;
        _selectedAttemptKey = null;
      }
    }
    notifyListeners();
  }

  void resetChain(String chainId) {
    final bool reset = _controller.resetEventChain(chainId);
    if (!reset) return;
    if (_selectedChainId == chainId) {
      _selectedAttemptKey = null;
    }
    notifyListeners();
  }

  void resetAllChains() {
    if (!canResetAll) return;
    _controller.resetAllEventChains();
  }

  @override
  void dispose() {
    _chainsSub?.cancel();
    _filtersSub?.cancel();
    super.dispose();
  }

  void _handleChainsUpdate(List<GraphEventChainSnapshot> snapshots) {
    _chains = _applyFilters ? _controller.filteredEventChains : snapshots;
    if (_chains.isNotEmpty) {
      _prunePinnedChainsLocked();
    }
    _syncSelection();
    notifyListeners();
  }

  void _handleFiltersChange(GraphFilterResult _) {
    if (!_applyFilters) return;
    _refreshChains();
  }

  void _refreshChains() {
    _chains = _currentChains();
    if (_chains.isNotEmpty) {
      _prunePinnedChainsLocked();
    }
    _syncSelection();
    notifyListeners();
  }

  void _syncSelection() {
    if (_chains.isEmpty) {
      _selectedChainId = null;
      _selectedAttemptKey = null;
      return;
    }
    if (_selectedChainId != null &&
        !_chains.any((GraphEventChainSnapshot chain) {
          return chain.id == _selectedChainId;
        })) {
      _selectedChainId = null;
      _selectedAttemptKey = null;
      return;
    }
    if (_selectedChainId != null) {
      final GraphEventChainSnapshot? chain = _selectedChain;
      if (chain != null) {
        _syncAttemptSelection(chain);
      } else {
        _selectedAttemptKey = null;
      }
    }
  }

  void _syncAttemptSelection(GraphEventChainSnapshot chain) {
    final List<String> attemptKeys = <String>[
      for (int index = 0; index < chain.activeAttempts.length; index++)
        _attemptKey(chain.activeAttempts[index], index),
    ];
    if (attemptKeys.isEmpty) {
      _selectedAttemptKey = null;
      return;
    }
    if (_selectedAttemptKey == null ||
        !attemptKeys.contains(_selectedAttemptKey)) {
      _selectedAttemptKey = attemptKeys.first;
    }
  }

  GraphEventChainSnapshot? get _selectedChain {
    if (_selectedChainId == null) return null;
    for (final GraphEventChainSnapshot chain in _chains) {
      if (chain.id == _selectedChainId) return chain;
    }
    return null;
  }

  List<GraphEventChainSnapshot> _orderedChains() {
    if (_pinnedChains.isEmpty) {
      return _chains;
    }
    final List<GraphEventChainSnapshot> pinned = <GraphEventChainSnapshot>[];
    final List<GraphEventChainSnapshot> others = <GraphEventChainSnapshot>[];
    for (final GraphEventChainSnapshot chain in _chains) {
      if (_pinnedChains.contains(chain.id)) {
        pinned.add(chain);
      } else {
        others.add(chain);
      }
    }
    return <GraphEventChainSnapshot>[...pinned, ...others];
  }

  List<EventChainAttemptViewData> _attemptViewData(
    GraphEventChainSnapshot chain,
  ) {
    final int totalSteps = chain.definition.steps.length;
    final List<EventChainAttemptViewData> attempts =
        <EventChainAttemptViewData>[];
    for (int index = 0; index < chain.activeAttempts.length; index++) {
      final GraphEventChainAttemptSnapshot attempt =
          chain.activeAttempts[index];
      if (attempt.nextStepIndex > totalSteps) continue;
      attempts.add(
        EventChainAttemptViewData(
          snapshot: attempt,
          key: _attemptKey(attempt, index),
          index: index,
        ),
      );
    }
    return attempts;
  }

  bool _prunePinnedChainsLocked() {
    if (_chains.isEmpty) return false;
    bool changed = false;
    _pinnedChains.removeWhere((String id) {
      final bool missing = !_chains.any(
        (GraphEventChainSnapshot chain) => chain.id == id,
      );
      if (missing) {
        changed = true;
      }
      return missing;
    });
    return changed;
  }

  List<GraphEventChainSnapshot> _currentChains() {
    return _applyFilters
        ? _controller.filteredEventChains
        : _controller.eventChains;
  }

  GraphEventChainAttemptSnapshot? _attemptForKey(
    GraphEventChainSnapshot chain,
    String? key,
  ) {
    if (key == null) return null;
    for (int index = 0; index < chain.activeAttempts.length; index++) {
      final GraphEventChainAttemptSnapshot attempt =
          chain.activeAttempts[index];
      if (_attemptKey(attempt, index) == key) {
        return attempt;
      }
    }
    return null;
  }

  String _attemptKey(GraphEventChainAttemptSnapshot attempt, int index) {
    final String? id = attempt.attemptId;
    if (id != null && id.isNotEmpty) {
      return id;
    }
    return '__seq_$index';
  }

  String _progressLabelForChain(GraphEventChainSnapshot chain) {
    final int totalSteps = chain.definition.steps.length;
    if (totalSteps <= 0) {
      return '0/0';
    }

    GraphEventChainAttemptSnapshot? attempt = _attemptForKey(
      chain,
      chain.id == _selectedChainId ? _selectedAttemptKey : null,
    );
    attempt ??= chain.activeAttempts.isNotEmpty
        ? chain.activeAttempts.first
        : null;
    if (attempt != null) {
      final int completed = attempt.nextStepIndex.clamp(0, totalSteps);
      return '$completed/$totalSteps';
    }

    if (chain.successCount > 0) {
      return '$totalSteps/$totalSteps';
    }
    return '0/$totalSteps';
  }
}

class EventChainViewData {
  const EventChainViewData({
    required this.snapshot,
    required this.progressLabel,
    required this.isSelected,
    required this.pinned,
    required this.selectedAttemptKey,
    required this.attempts,
    required this.selectedAttempt,
  });

  final GraphEventChainSnapshot snapshot;
  final String progressLabel;
  final bool isSelected;
  final bool pinned;
  final String? selectedAttemptKey;
  final List<EventChainAttemptViewData> attempts;
  final GraphEventChainAttemptSnapshot? selectedAttempt;
}

class EventChainAttemptViewData {
  const EventChainAttemptViewData({
    required this.snapshot,
    required this.key,
    required this.index,
  });

  final GraphEventChainAttemptSnapshot snapshot;
  final String key;
  final int index;
}
