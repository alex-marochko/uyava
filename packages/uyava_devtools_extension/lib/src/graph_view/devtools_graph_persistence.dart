part of '../../graph_view_page.dart';

typedef DevToolsGraphPersistenceLogSink = ViewportPersistenceLogSink;

class DevToolsGraphPersistence extends ViewportPersistenceService {
  DevToolsGraphPersistence({
    required super.viewportStorage,
    required super.panelLayoutStorage,
    super.viewportSaveDebounce = const Duration(milliseconds: 350),
    super.logSink,
  });
}
