import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_devtools_extension/main.dart';
import 'package:uyava_ui/uyava_ui.dart';

import 'graph_view_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerGraphViewTestHarness();

  testWidgets('Viewport state persists between sessions', (tester) async {
    final TestViewportStorage viewportStorage = TestViewportStorage();
    final InMemoryPanelLayoutStorage panelLayoutStorage =
        InMemoryPanelLayoutStorage();

    await pumpGraphViewPage(
      tester,
      graphPayload: basicGraphPayload(),
      viewportStorage: viewportStorage,
      panelLayoutStorage: panelLayoutStorage,
    );

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final GraphViewportState? savedState = viewportStorage.lastSavedState;
    expect(savedState, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpGraphViewPage(
      tester,
      graphPayload: basicGraphPayload(),
      viewportStorage: viewportStorage,
      panelLayoutStorage: panelLayoutStorage,
    );
    final dynamic restoredState = tester.state(find.byType(GraphViewPage));

    final GraphViewportState restoredViewport = GraphViewportState.fromMatrix(
      restoredState.transformationController.value,
    );
    expect(restoredViewport, equals(savedState));
  });

  testWidgets('Viewport storage can be injected for testing', (tester) async {
    final TestViewportStorage viewportStorage = TestViewportStorage();

    Future<dynamic> pumpGraphView() async {
      await pumpGraphViewPage(tester, graphPayload: basicGraphPayload());
      final dynamic graphState = tester.state(find.byType(GraphViewPage));
      await graphState.setViewportStorageForTesting(viewportStorage);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      return graphState;
    }

    final dynamic firstState = await pumpGraphView();
    const GraphViewportState persistedState = GraphViewportState(
      scale: 1.35,
      translation: Offset(96, -32),
    );
    firstState.transformationController.value = persistedState.toMatrix();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(viewportStorage.lastSavedState, equals(persistedState));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final dynamic restoredState = await pumpGraphView();
    await tester.pump();
    await tester.pump();

    final GraphViewportState restoredViewport = GraphViewportState.fromMatrix(
      restoredState.transformationController.value,
    );
    expect(restoredViewport, equals(persistedState));
  });
}
