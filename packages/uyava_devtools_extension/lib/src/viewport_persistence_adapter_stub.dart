import 'package:uyava_ui/uyava_ui.dart';

ViewportPersistenceAdapter createViewportPersistenceAdapterImpl() =>
    _MemoryViewportPersistenceAdapter();

class _MemoryViewportPersistenceAdapter implements ViewportPersistenceAdapter {
  GraphViewportState? _state;

  @override
  Future<GraphViewportState?> load() async => _state;

  @override
  Future<void> save(GraphViewportState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}
