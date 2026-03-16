import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_devtools_extension/main.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  testWidgets('GraphViewPage wires storages and layout preset', (tester) async {
    final viewportStorage = _RecordingViewportStorage();
    final panelStorage = _RecordingPanelLayoutStorage();

    await tester.pumpWidget(
      MaterialApp(
        home: GraphViewPage(
          viewportStorage: viewportStorage,
          panelLayoutStorage: panelStorage,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final dynamic state = tester.state(find.byType(GraphViewPage));

    expect(state.panelLayoutStorage, same(panelStorage));
    expect(state.panelLayoutConfigurationId, equals('graph-details-v3'));
    expect(viewportStorage.loadCount, greaterThanOrEqualTo(1));
    expect(panelStorage.readCount, greaterThanOrEqualTo(1));
  });
}

class _RecordingViewportStorage implements ViewportPersistenceAdapter {
  int loadCount = 0;

  @override
  Future<void> clear() async {}

  @override
  Future<GraphViewportState?> load() async {
    loadCount++;
    return null;
  }

  @override
  Future<void> save(GraphViewportState state) async {}
}

class _RecordingPanelLayoutStorage extends UyavaPanelLayoutStorage {
  _RecordingPanelLayoutStorage() : super(maxAge: const Duration(days: 30));

  String? _state;
  int readCount = 0;

  @override
  Future<void> deleteRaw() async {
    _state = null;
  }

  @override
  Future<String?> readRaw() async {
    readCount++;
    return _state;
  }

  @override
  Future<void> writeRaw(String data) async {
    _state = data;
  }
}
