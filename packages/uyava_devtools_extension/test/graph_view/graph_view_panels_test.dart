import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

import 'graph_view_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerGraphViewTestHarness();

  testWidgets('Panel menu switches layout presets', (tester) async {
    final dynamic graphState = await pumpGraphViewPage(tester);
    expect(graphState.panelLayoutConfigurationId, equals('graph-details-v3'));

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    await tester.tap(panelMenuItemFinder('Layout · Vertical stack'));
    await tester.pumpAndSettle();
    expect(graphState.panelLayoutConfigurationId, equals('stacked-v3'));
    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    await tester.tap(panelMenuItemFinder('Layout · Graph with details'));
    await tester.pumpAndSettle();

    expect(graphState.panelLayoutConfigurationId, equals('graph-details-v3'));
  });

  testWidgets('Panel menu toggles optional panels', (tester) async {
    final dynamic graphState = await pumpGraphViewPage(tester);

    expect(find.text('Pattern'), findsOneWidget);
    expect(graphState.isDashboardPanelVisible, isTrue);
    expect(graphState.isChainsPanelVisible, isTrue);
    expect(find.text('No event chains'), findsOneWidget);

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();

    await tester.tap(panelMenuItemFinder('Dashboard panel'));
    await tester.pumpAndSettle();

    expect(graphState.isDashboardPanelVisible, isFalse);

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();

    final Finder dashboardItemFinder = panelMenuItemFinder('Dashboard panel');
    final CheckedPopupMenuItem<dynamic> dashboardItem = tester.widget(
      dashboardItemFinder,
    );
    expect(dashboardItem.checked, isFalse);

    await tester.tap(panelMenuItemFinder('Chains panel'));
    await tester.pumpAndSettle();
    expect(graphState.isChainsPanelVisible, isFalse);
    expect(find.text('No event chains'), findsNothing);

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    await tester.tap(panelMenuItemFinder('Dashboard panel'));
    await tester.pumpAndSettle();

    expect(graphState.isDashboardPanelVisible, isTrue);
  });

  testWidgets('Dashboard panel renders metric aggregates', (tester) async {
    final dynamic graphState = await pumpGraphViewPage(tester);

    if (!graphState.isDashboardPanelVisible) {
      await tester.tap(find.byTooltip('Configure panels'));
      await tester.pumpAndSettle();
      await tester.tap(panelMenuItemFinder('Dashboard panel'));
      await tester.pumpAndSettle();
    }

    final GraphController controller =
        graphState.graphController as GraphController;

    controller.registerMetricDefinition(<String, dynamic>{
      'id': 'latency',
      'label': 'Latency',
      'unit': 'ms',
      'aggregators': <String>['last', 'min', 'max', 'sum'],
    });
    controller.recordMetricSample(<String, dynamic>{
      'id': 'latency',
      'value': 12,
      'timestamp': '2024-01-01T00:00:01Z',
    });

    await tester.pump();
    await tester.pump();

    expect(find.text('No metrics'), findsNothing);
    expect(find.text('Latency'), findsOneWidget);
    expect(find.text('12 ms'), findsWidgets);
    expect(find.text('Samples: 1'), findsOneWidget);
  });

  testWidgets('Panel layout changes persist through storage', (tester) async {
    final dynamic graphState = await pumpGraphViewPage(tester);
    final UyavaPanelLayoutStorage storage =
        graphState.panelLayoutStorage as UyavaPanelLayoutStorage;

    expect(await storage.loadState(), isNull);

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    await tester.tap(panelMenuItemFinder('Layout · Vertical stack'));
    await tester.pumpAndSettle();
    await tester.pump();

    final UyavaPanelLayoutState? afterPreset = await storage.loadState();
    expect(afterPreset, isNotNull);
    expect(afterPreset!.configurationId, equals('stacked-v3'));

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    await tester.tap(panelMenuItemFinder('Dashboard panel'));
    await tester.pumpAndSettle();
    await tester.pump();

    final UyavaPanelLayoutState? afterToggle = await storage.loadState();
    expect(afterToggle, isNotNull);
    final entry = afterToggle!.entries.firstWhere(
      (e) => e.id.value == 'dashboard',
    );
    expect(entry.visibility, equals(UyavaPanelVisibility.hidden));
  });
}
