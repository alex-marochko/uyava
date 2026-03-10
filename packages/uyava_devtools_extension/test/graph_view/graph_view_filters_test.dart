import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_devtools_extension/main.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/uyava_ui.dart';

import 'graph_view_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerGraphViewTestHarness();

  testWidgets('Filters panel applies substring search', (tester) async {
    final dynamic graphState = await pumpGraphViewPage(
      tester,
      graphPayload: basicGraphPayload(),
    );

    final Finder patternField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Pattern',
    );
    expect(patternField, findsOneWidget);

    await tester.tap(patternField);
    await tester.enterText(patternField, 'Service A');
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      (graphState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceA'}),
    );
    expect((graphState.visibleEdgeIds as List<String>).toSet(), isEmpty);

    await tester.ensureVisible(find.byTooltip('Clear filters'));
    await tester.tap(find.byTooltip('Clear filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      (graphState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceA', 'serviceB'}),
    );
    expect(
      (graphState.visibleEdgeIds as List<String>).toSet(),
      equals({'serviceA-serviceB'}),
    );
  });

  testWidgets('Filters panel supports tag include/all logic', (tester) async {
    await pumpGraphViewPage(tester);
    final dynamic graphState = tester.state(find.byType(GraphViewPage));
    graphState.replaceGraphForTesting(taggedGraphPayload());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Tags'), findsWidgets);

    final GraphController controller = graphState.graphController;
    controller.updateFiltersCommand({
      'tags': {
        'mode': 'include',
        'values': ['Core', 'Backend'],
        'logic': 'all',
      },
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      (graphState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceA'}),
    );

    controller.updateFilters(GraphFilterState.empty);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      (graphState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceA', 'serviceB', 'serviceC'}),
    );
  });

  testWidgets('Root scope controls are removed from filters panel', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GraphViewPage()));
    await tester.pump();

    expect(find.text('Advanced filter +'), findsNothing);
    expect(find.text('Advanced filter -'), findsNothing);

    final Finder rootField = find.byWidgetPredicate((widget) {
      if (widget is! TextField) return false;
      final InputDecoration? decoration = widget.decoration;
      return decoration != null && decoration.hintText == 'Root node id';
    });
    final Finder depthField = find.byWidgetPredicate((widget) {
      if (widget is! TextField) return false;
      final InputDecoration? decoration = widget.decoration;
      return decoration != null && decoration.hintText == 'Depth';
    });

    expect(rootField, findsNothing);
    expect(depthField, findsNothing);
  });

  testWidgets('Filters panel state persists across reloads', (tester) async {
    final TestViewportStorage viewportStorage = TestViewportStorage();
    final InMemoryPanelLayoutStorage panelLayoutStorage =
        InMemoryPanelLayoutStorage();

    Future<void> pumpGraphView() async {
      await pumpGraphViewPage(
        tester,
        viewportStorage: viewportStorage,
        panelLayoutStorage: panelLayoutStorage,
      );
    }

    await pumpGraphView();
    final dynamic graphState = tester.state(find.byType(GraphViewPage));
    final GraphController controller = graphState.graphController;
    graphState.replaceGraphForTesting(taggedGraphPayload());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Tags'), findsWidgets);

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    await tester.tap(panelMenuItemFinder('Filters bar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    await tester.tap(panelMenuItemFinder('Filters bar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tags').first);
    await tester.pumpAndSettle();

    graphState.setFiltersScopeForTesting(false);
    graphState.setAutoCompactFiltersForTesting(false);
    await tester.pump();

    controller.updateFiltersCommand(<String, Object?>{
      'tags': <String, Object?>{
        'mode': 'include',
        'values': <String>['Core', 'Backend'],
        'logic': 'all',
      },
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.timer));
    await tester.pump();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final GraphFilterTags? persistedTags = controller.filters.tags;
    expect(persistedTags, isNotNull);
    expect(persistedTags!.logic, equals(UyavaFilterTagLogic.all));
    expect(persistedTags.values, unorderedEquals(<String>['Core', 'Backend']));

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    await tester.tap(panelMenuItemFinder('Filters bar'));
    await tester.pumpAndSettle();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final UyavaPanelLayoutState? persisted = await panelLayoutStorage
        .loadState();
    expect(persisted, isNotNull);
    final UyavaPanelLayoutEntry filtersEntry = persisted!.entries.firstWhere(
      (entry) => entry.id.value == 'filters',
    );
    final Map<String, Object?>? extraState = filtersEntry.extraState;
    expect(extraState, isNotNull);
    expect(extraState!['filtersVisible'], isFalse);
    expect(extraState['filterAllPanels'], isFalse);
    expect(extraState['autoCompactFilters'], isFalse);
    final GraphFilterState? storedFilters = const GraphFilterStateCodec()
        .decode(extraState['filters']);
    expect(storedFilters?.tags, isNotNull);
    final GraphFilterTags storedTags = storedFilters!.tags!;
    expect(storedTags.logic.name, equals('all'));
    expect(storedTags.values, unorderedEquals(<String>['Core', 'Backend']));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpGraphView();
    final dynamic restoredState = tester.state(find.byType(GraphViewPage));
    restoredState.replaceGraphForTesting(taggedGraphPayload());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      (restoredState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceA'}),
    );

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    final CheckedPopupMenuItem<dynamic> filtersMenu = tester.widget(
      panelMenuItemFinder('Filters bar'),
    );
    expect(filtersMenu.checked, isFalse);
    await tester.tapAt(Offset.zero); // Dismiss the popup menu.
  });

  testWidgets('Restores filters UI state after reload', (tester) async {
    final InMemoryPanelLayoutStorage panelLayoutStorage =
        InMemoryPanelLayoutStorage();
    final TestViewportStorage viewportStorage = TestViewportStorage();

    Future<void> pumpGraphView() => pumpGraphViewPage(
      tester,
      graphPayload: taggedGraphPayload(),
      viewportStorage: viewportStorage,
      panelLayoutStorage: panelLayoutStorage,
    );

    await pumpGraphView();
    final dynamic graphState = tester.state(find.byType(GraphViewPage));
    final GraphController controller = graphState.graphController;
    controller.updateFiltersCommand(<String, Object?>{
      'tags': <String, Object?>{
        'mode': 'include',
        'values': <String>['Core'],
        'logic': 'any',
      },
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpGraphView();
    final dynamic restoredState = tester.state(find.byType(GraphViewPage));
    restoredState.replaceGraphForTesting(taggedGraphPayload());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      (restoredState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceA'}),
    );

    final FilledButton clearButton = tester.widget(
      find.descendant(
        of: find.byTooltip('Clear filters'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(clearButton.onPressed, isNotNull);
    expect(find.text('Core'), findsWidgets);
  });
}
