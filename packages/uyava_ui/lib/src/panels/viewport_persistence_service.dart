import 'dart:async';

import '../viewport.dart';
import 'panel_contract.dart';
import 'panel_storage.dart';

typedef ViewportPersistenceLogSink =
    void Function(String message, Object error, StackTrace stackTrace);

/// Coordinates persistence for viewport state and panel layout snapshots.
///
/// The actual IO is delegated to [ViewportPersistenceAdapter] implementations
/// supplied by each host (e.g., localStorage in DevTools, file system on
/// Desktop) to keep the UI layer platform-agnostic.
class ViewportPersistenceService {
  ViewportPersistenceService({
    required ViewportPersistenceAdapter viewportStorage,
    required UyavaPanelLayoutStorage panelLayoutStorage,
    this.viewportSaveDebounce = const Duration(milliseconds: 350),
    this.logSink,
  }) : _viewportStorage = viewportStorage,
       _panelLayoutStorage = panelLayoutStorage;

  final Duration viewportSaveDebounce;
  final ViewportPersistenceLogSink? logSink;

  ViewportPersistenceAdapter _viewportStorage;
  UyavaPanelLayoutStorage _panelLayoutStorage;
  Timer? _viewportPersistTimer;
  GraphViewportState? _pendingViewportState;

  ViewportPersistenceAdapter get viewportStorage => _viewportStorage;
  UyavaPanelLayoutStorage get panelLayoutStorage => _panelLayoutStorage;

  void updateViewportStorage(ViewportPersistenceAdapter storage) {
    _viewportPersistTimer?.cancel();
    _pendingViewportState = null;
    _viewportStorage = storage;
  }

  void updatePanelLayoutStorage(UyavaPanelLayoutStorage storage) {
    _panelLayoutStorage = storage;
  }

  void scheduleViewportSave(GraphViewportState state) {
    _pendingViewportState = state;
    _viewportPersistTimer?.cancel();
    _viewportPersistTimer = Timer(viewportSaveDebounce, () {
      final GraphViewportState? snapshot = _pendingViewportState;
      if (snapshot == null) return;
      unawaited(_persistViewport(snapshot));
    });
  }

  Future<GraphViewportState?> restoreViewportState() async {
    try {
      return await _viewportStorage.load();
    } catch (error, stackTrace) {
      _log('Failed to restore viewport state', error, stackTrace);
      return null;
    }
  }

  Future<void> clearViewportState() async {
    try {
      await _viewportStorage.clear();
    } catch (error, stackTrace) {
      _log('Failed to clear viewport state', error, stackTrace);
    }
  }

  Future<UyavaPanelLayoutState?> restorePanelLayout() async {
    try {
      return await _panelLayoutStorage.loadState();
    } catch (error, stackTrace) {
      _log('Failed to restore panel layout', error, stackTrace);
      return null;
    }
  }

  void persistPanelLayout(UyavaPanelLayoutState state) {
    unawaited(() async {
      try {
        await _panelLayoutStorage.saveState(state);
      } catch (error, stackTrace) {
        _log('Failed to persist panel layout', error, stackTrace);
      }
    }());
  }

  void dispose() {
    _viewportPersistTimer?.cancel();
    _viewportPersistTimer = null;
    _pendingViewportState = null;
  }

  Future<void> _persistViewport(GraphViewportState state) async {
    try {
      await _viewportStorage.save(state);
    } catch (error, stackTrace) {
      _log('Failed to persist viewport state', error, stackTrace);
    }
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    logSink?.call(message, error, stackTrace);
  }
}

/// Host-provided adapter that knows how to persist viewport snapshots.
abstract class ViewportPersistenceAdapter {
  Future<GraphViewportState?> load();
  Future<void> save(GraphViewportState state);
  Future<void> clear();
}
