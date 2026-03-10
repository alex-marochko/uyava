import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_devtools_extension/main.dart';
import 'package:uyava_ui/uyava_ui.dart';

import 'graph_view_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerGraphViewTestHarness();

  testWidgets('GraphViewPage paints nodes and edges after graph updates', (
    tester,
  ) async {
    await pumpGraphViewPage(tester);

    await tester.tap(find.byTooltip('Configure panels'));
    await tester.pumpAndSettle();
    await tester.tap(panelMenuItemFinder('Dashboard panel'));
    await tester.pumpAndSettle();

    final dynamic graphState = tester.state(find.byType(GraphViewPage));
    graphState.replaceGraphForTesting(basicGraphPayload());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final graphPainterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is GraphPainter,
    );
    expect(graphPainterFinder, findsOneWidget);

    GraphPainter painter =
        (tester.widget<CustomPaint>(graphPainterFinder).painter!
            as GraphPainter);
    expect(painter.displayNodes.map((n) => n.id).toSet(), {
      'serviceA',
      'serviceB',
    });
    expect(
      (graphState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceA', 'serviceB'}),
    );
    expect(
      painter.edges.map((edge) => edge.id).toSet(),
      equals({'serviceA-serviceB'}),
    );

    graphState.addNodeForTesting(<String, dynamic>{
      'id': 'serviceC',
      'type': 'service',
      'label': 'Service C',
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    painter =
        (tester.widget<CustomPaint>(graphPainterFinder).painter!
            as GraphPainter);
    expect(
      painter.displayNodes.map((n) => n.id).toSet(),
      equals({'serviceA', 'serviceB', 'serviceC'}),
    );
    expect(
      (graphState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceA', 'serviceB', 'serviceC'}),
    );

    graphState.addEdgeForTesting(<String, dynamic>{
      'id': 'serviceB-serviceC',
      'source': 'serviceB',
      'target': 'serviceC',
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    painter =
        (tester.widget<CustomPaint>(graphPainterFinder).painter!
            as GraphPainter);
    expect(
      painter.edges.map((edge) => edge.id).toSet(),
      equals({'serviceA-serviceB', 'serviceB-serviceC'}),
    );
    expect(
      (graphState.visibleEdgeIds as List<String>).toSet(),
      equals({'serviceA-serviceB', 'serviceB-serviceC'}),
    );

    await tester.pumpAndSettle();
    final TransformationController transformController =
        graphState.transformationController;
    final double initialScale = transformController.value.storage[0];
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    final double zoomedScale = transformController.value.storage[0];
    expect(zoomedScale, greaterThan(initialScale));

    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();
    final double afterZoomOut = transformController.value.storage[0];
    expect(afterZoomOut, lessThanOrEqualTo(zoomedScale));
  });

  testWidgets('Graph context menu toggles focus for nodes', (tester) async {
    await pumpGraphViewPage(tester);

    final dynamic graphState = tester.state(find.byType(GraphViewPage));
    graphState.replaceGraphForTesting(basicGraphPayload());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final Finder painterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is GraphPainter,
    );
    final CustomPaint paintWidget = tester.widget<CustomPaint>(painterFinder);
    final GraphPainter painter = paintWidget.painter! as GraphPainter;
    final DisplayNode node = painter.displayNodes.firstWhere(
      (n) => n.id == 'serviceA',
    );
    final RenderBox renderBox = tester.renderObject(painterFinder) as RenderBox;
    final Offset globalTapPosition = renderBox.localToGlobal(node.position);

    final TestWidgetsFlutterBinding binding = tester.binding;
    final TestPointer pointer = TestPointer(301, PointerDeviceKind.mouse);
    binding.handlePointerEvent(
      pointer.down(globalTapPosition, buttons: kSecondaryButton),
    );
    await tester.pumpAndSettle();
    binding.handlePointerEvent(pointer.up());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to focus'));
    await tester.pumpAndSettle();

    final GraphFocusController focusController =
        graphState.focusControllerForTesting as GraphFocusController;
    expect(focusController.state.nodeIds, contains('serviceA'));
    final GraphPainter focusedPainter =
        (tester.widget<CustomPaint>(painterFinder).painter! as GraphPainter);
    expect(focusedPainter.focusedNodeIds, equals({'serviceA'}));
    expect(
      focusedPainter.displayNodes.map((n) => n.id).toSet(),
      equals({'serviceA', 'serviceB'}),
    );
    final DisplayNode focusedNode = focusedPainter.displayNodes.firstWhere(
      (n) => n.id == 'serviceA',
    );
    final Offset focusedGlobalPosition = renderBox.localToGlobal(
      focusedNode.position,
    );

    final TestPointer pointer2 = TestPointer(302, PointerDeviceKind.mouse);
    binding.handlePointerEvent(
      pointer2.down(focusedGlobalPosition, buttons: kSecondaryButton),
    );
    await tester.pumpAndSettle();
    binding.handlePointerEvent(pointer2.up());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove from focus'));
    await tester.pumpAndSettle();

    expect(focusController.state.nodeIds, isEmpty);
    final GraphPainter clearedPainter =
        (tester.widget<CustomPaint>(painterFinder).painter! as GraphPainter);
    expect(
      clearedPainter.displayNodes.map((n) => n.id).toSet(),
      equals({'serviceA', 'serviceB'}),
    );
  });

  testWidgets('Pan mode toggle prevents parent collapse during drag', (
    tester,
  ) async {
    await pumpGraphViewPage(tester);

    final dynamic graphState = tester.state(find.byType(GraphViewPage));

    graphState.replaceGraphForTesting(<String, dynamic>{
      'nodes': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'group', 'type': 'group', 'label': 'Group'},
        <String, dynamic>{
          'id': 'child',
          'type': 'service',
          'label': 'Child',
          'parentId': 'group',
        },
      ],
      'edges': const <Map<String, dynamic>>[],
    });

    await tester.pump();

    expect(graphState.isPanModeEnabled, isFalse);
    expect(graphState.collapsedParentIds, isEmpty);

    graphState.handleParentTapForTesting('group');
    await tester.pump();
    expect(graphState.collapsedParentIds, contains('group'));

    graphState.handleParentTapForTesting('group');
    await tester.pump();
    expect(graphState.collapsedParentIds, isEmpty);

    await tester.tap(find.byTooltip('Enable drag-to-pan mode'));
    await tester.pumpAndSettle();
    expect(graphState.isPanModeEnabled, isTrue);

    graphState.handleParentTapForTesting('group');
    await tester.pump();
    expect(graphState.collapsedParentIds, isEmpty);

    await tester.tap(find.byTooltip('Disable drag-to-pan mode'));
    await tester.pumpAndSettle();
    expect(graphState.isPanModeEnabled, isFalse);

    graphState.handleParentTapForTesting('group');
    await tester.pump();
    expect(graphState.collapsedParentIds, contains('group'));
  });
}
