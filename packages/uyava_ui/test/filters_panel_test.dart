import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';
import 'package:uyava_protocol/uyava_protocol.dart'
    show UyavaFilterGroupingMode;

Future<GraphController> _createController() async {
  final GraphController controller = GraphController(engine: GridLayout());
  controller.replaceGraph(<String, dynamic>{
    'nodes': <Map<String, dynamic>>[
      {
        'id': 'root',
        'label': 'Parent Node',
        'tags': <String>['TagA', 'TagB'],
      },
      {
        'id': 'child1',
        'label': 'Child 1',
        'parentId': 'root',
        'tags': <String>['TagA'],
      },
      {'id': 'child2', 'label': 'Child 2', 'parentId': 'root'},
      {'id': 'grandchild', 'label': 'Grandchild', 'parentId': 'child1'},
    ],
    'edges': const <Map<String, dynamic>>[],
  }, const Size2D(800, 600));
  controller.registerEventChainDefinition(<String, dynamic>{
    'id': 'flow',
    'tags': <String>['ChainTag', 'shared'],
    'steps': const <Map<String, String>>[
      {'stepId': 'start', 'nodeId': 'root'},
      {'stepId': 'finish', 'nodeId': 'child1'},
    ],
  });

  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UyavaFiltersPanel multi-select', () {
    testWidgets('keeps tag dropdown open when focusing search field', (
      WidgetTester tester,
    ) async {
      final GraphController controller = await _createController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: UyavaFiltersPanel(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      // Disable debounce to avoid waiting for timers during the test.
      await tester.tap(find.byIcon(Icons.timer));
      await tester.pump();

      await tester.tap(find.text('Tags').first);
      await tester.pumpAndSettle();

      final Finder searchField = find.byWidgetPredicate(
        (Widget widget) =>
            widget is TextField && widget.decoration?.hintText == 'Filter tags',
      );
      expect(searchField, findsOneWidget);

      await tester.tap(searchField);
      await tester.pump();

      expect(find.text('TagA'), findsOneWidget);
    });

    testWidgets('selecting a parent node cascades to descendants', (
      WidgetTester tester,
    ) async {
      final GraphController controller = await _createController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: UyavaFiltersPanel(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.timer));
      await tester.pump();

      await tester.tap(find.text('Nodes').first);
      await tester.pumpAndSettle();

      final Finder parentTile = find.widgetWithText(
        CheckboxListTile,
        'Parent Node',
      );
      expect(parentTile, findsOneWidget);

      await tester.tap(parentTile);
      await tester.pump();
      expect(find.text('(4 nodes)'), findsOneWidget);

      await tester.tap(parentTile);
      await tester.pump();
      expect(find.text('(4 nodes)'), findsNothing);
    });

    testWidgets('filtering nodes by label ignores case', (
      WidgetTester tester,
    ) async {
      final GraphController controller = await _createController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: UyavaFiltersPanel(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nodes').first);
      await tester.pumpAndSettle();

      final Finder searchField = find.byWidgetPredicate(
        (Widget widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search nodes',
      );
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'parent');
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(CheckboxListTile, 'Parent Node'),
        findsOneWidget,
      );
      expect(find.widgetWithText(CheckboxListTile, 'Child 1'), findsNothing);
      expect(find.widgetWithText(CheckboxListTile, 'Child 2'), findsNothing);
    });

    testWidgets('tag selector includes chain tags', (
      WidgetTester tester,
    ) async {
      final GraphController controller = await _createController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: UyavaFiltersPanel(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tags').first);
      await tester.pumpAndSettle();

      expect(find.text('ChainTag'), findsOneWidget);
    });

    testWidgets('filtering within tags keeps menu open and applies selection', (
      WidgetTester tester,
    ) async {
      final GraphController controller = await _createController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: UyavaFiltersPanel(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tags').first);
      await tester.pumpAndSettle();

      final Finder searchField = find.byWidgetPredicate(
        (Widget widget) =>
            widget is TextField && widget.decoration?.hintText == 'Filter tags',
      );
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'TagA');
      await tester.pumpAndSettle();

      final Finder tagTile = find.widgetWithText(CheckboxListTile, 'TagA');
      expect(tagTile, findsOneWidget);

      await tester.tap(tagTile);
      await tester.pump();

      final CheckboxListTile tile = tester.widget(tagTile);
      expect(tile.value, isTrue);

      // Wait for debounce-driven auto-apply.
      await tester.pump(const Duration(milliseconds: 400));

      final GraphFilterTags? tags = controller.filters.tags;
      expect(tags, isNotNull);
      expect(tags!.values, equals(<String>['TagA']));

      // Menu remains open, allowing additional selections.
      expect(find.widgetWithText(CheckboxListTile, 'TagA'), findsOneWidget);
    });

    testWidgets('auto-compact toggle surfaces callback', (
      WidgetTester tester,
    ) async {
      final GraphController controller = await _createController();
      addTearDown(controller.dispose);

      bool? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: UyavaFiltersPanel(
              controller: controller,
              autoCompactEnabled: false,
              onAutoCompactChanged: (bool next) {
                lastValue = next;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder toggleFinder = find.byIcon(Icons.center_focus_strong);
      expect(toggleFinder, findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pump();

      expect(lastValue, isTrue);
    });

    testWidgets(
      'clear button enabled only when filters active and preserves grouping',
      (WidgetTester tester) async {
        final GraphController controller = await _createController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Material(child: UyavaFiltersPanel(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        final Finder clearFinder = find.widgetWithIcon(
          FilledButton,
          Icons.filter_alt_off,
        );
        FilledButton clearButton = tester.widget(clearFinder);
        expect(clearButton.onPressed, isNull);

        controller.updateFilters(
          const GraphFilterState(
            grouping: GraphFilterGrouping(
              mode: UyavaFilterGroupingMode.level,
              levelDepth: 1,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.filters.grouping?.levelDepth, 1);

        final Finder patternField = find.byWidgetPredicate(
          (Widget widget) =>
              widget is TextField && widget.decoration?.hintText == 'Pattern',
        );
        await tester.enterText(patternField, 'auth');
        await tester.pump();

        clearButton = tester.widget(clearFinder);
        expect(clearButton.onPressed, isNotNull);

        await tester.tap(clearFinder);
        await tester.pumpAndSettle();

        expect(controller.filters.grouping?.levelDepth, 1);
        clearButton = tester.widget(clearFinder);
        expect(clearButton.onPressed, isNull);
      },
    );

    testWidgets('search mode button cycles through options', (
      WidgetTester tester,
    ) async {
      final GraphController controller = await _createController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: UyavaFiltersPanel(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      final Finder modeButton = find.text('Substr');
      expect(modeButton, findsOneWidget);

      await tester.tap(modeButton);
      await tester.pump();
      expect(find.text('Mask'), findsOneWidget);

      await tester.tap(find.text('Mask'));
      await tester.pump();
      expect(find.text('Regex'), findsOneWidget);
    });
  });
}
