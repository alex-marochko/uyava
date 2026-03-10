import 'package:flutter/foundation.dart';
import 'package:uyava_ui/uyava_ui.dart';

/// DevTools-specific adapter that bridges [UyavaPanelShellController] updates
/// to host callbacks while keeping layout persistence centralized.
class DevToolsPanelShellAdapter extends UyavaPanelShellViewAdapter {
  DevToolsPanelShellAdapter({
    required ValueChanged<UyavaPanelShellSnapshot> onSnapshot,
    required ValueChanged<UyavaPanelLayoutState> onPersistedState,
    VoidCallback? onControllerDisposed,
  }) : _onSnapshot = onSnapshot,
       _onPersistedState = onPersistedState,
       _onControllerDisposed = onControllerDisposed;

  final ValueChanged<UyavaPanelShellSnapshot> _onSnapshot;
  final ValueChanged<UyavaPanelLayoutState> _onPersistedState;
  final VoidCallback? _onControllerDisposed;

  @override
  void didUpdateSnapshot(UyavaPanelShellSnapshot snapshot) {
    _onSnapshot(snapshot);
  }

  @override
  void handlePersistedState(UyavaPanelLayoutState state) {
    _onPersistedState(state);
  }

  @override
  void handleControllerDisposed() {
    _onControllerDisposed?.call();
  }
}
