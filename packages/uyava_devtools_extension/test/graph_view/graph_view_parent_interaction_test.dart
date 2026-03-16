import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_devtools_extension/main.dart';
import 'package:uyava_ui/uyava_ui.dart';

import 'graph_view_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerGraphViewTestHarness();

  testWidgets('Grouping depth can be expanded manually', (tester) async {
    await pumpGraphViewPage(tester);

    final dynamic graphState = tester.state(find.byType(GraphViewPage));
    graphState.replaceGraphForTesting(hierarchyGraphPayload());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final Finder levelZeroButton = find
        .widgetWithText(OutlinedButton, '0')
        .first;
    await tester.ensureVisible(levelZeroButton);
    await tester.tap(levelZeroButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      graphState.graphController.autoCollapsedParents.contains('root'),
      isTrue,
    );

    final Finder graphPainterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is GraphPainter,
    );
    GraphPainter painter =
        (tester.widget<CustomPaint>(graphPainterFinder).painter!
            as GraphPainter);
    expect(painter.displayNodes.map((n) => n.id).toSet(), equals({'root'}));

    graphState.handleParentTapForTesting('root');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    painter =
        (tester.widget<CustomPaint>(graphPainterFinder).painter!
            as GraphPainter);
    expect(
      painter.displayNodes.map((n) => n.id).toSet(),
      equals({'childA', 'childB', 'grandChild', 'root'}),
    );
    expect(graphState.collapsedParentIds, isNot(contains('root')));

    await tester.tap(levelZeroButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    painter =
        (tester.widget<CustomPaint>(graphPainterFinder).painter!
            as GraphPainter);
    expect(painter.displayNodes.map((n) => n.id).toSet(), equals({'root'}));
    expect(graphState.graphController.autoCollapsedParents, contains('root'));
  });

  testWidgets('parent tap accounts for viewport transform', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 16));

    final TransformationController controller =
        graphState.transformationController as TransformationController;
    controller.value = Matrix4.identity();
    controller.value.setTranslationRaw(120.0, 80.0, 0.0);
    await tester.pump();

    final graphPainterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is GraphPainter,
    );
    final CustomPaint graphPaint = tester.widget<CustomPaint>(
      graphPainterFinder,
    );
    final GraphPainter painter = graphPaint.painter! as GraphPainter;
    final DisplayNode parentNode = painter.displayNodes.firstWhere(
      (node) => node.id == 'group',
    );
    final Offset localTap = parentNode.position;
    final Map<String, List<UyavaNode>> childrenByParent =
        <String, List<UyavaNode>>{};
    for (final DisplayNode node in painter.displayNodes) {
      final String? parentId = node.parentId;
      if (parentId == null) continue;
      (childrenByParent[parentId] ??= <UyavaNode>[]).add(node.node);
    }
    expect(
      hitTestParentIdAt(
        localTap,
        painter.displayNodes,
        childrenByParent,
        const RenderConfig(),
      ),
      equals('group'),
    );

    final Finder detectorFinder = find.descendant(
      of: find.byType(InteractiveViewer),
      matching: find.byType(GestureDetector),
    );
    final GestureDetector detector = tester
        .widgetList<GestureDetector>(detectorFinder)
        .firstWhere((candidate) => candidate.onTapUp != null);
    detector.onTapUp?.call(
      TapUpDetails(localPosition: localTap, kind: PointerDeviceKind.touch),
    );
    await tester.pump();

    expect(graphState.collapsedParentIds, contains('group'));
  });

  testWidgets('parent tap near panel boundary with layout transforms', (
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
    await tester.pump(const Duration(milliseconds: 16));

    final TransformationController controller =
        graphState.transformationController as TransformationController;
    final Finder graphPainterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is GraphPainter,
    );
    final CustomPaint graphPaint = tester.widget<CustomPaint>(
      graphPainterFinder,
    );
    final GraphPainter painter = graphPaint.painter! as GraphPainter;
    final DisplayNode parentNode = painter.displayNodes.firstWhere(
      (node) => node.id == 'group',
    );

    final RenderBox renderBox =
        tester.renderObject(graphPainterFinder) as RenderBox;
    final Size viewportSize = renderBox.size;

    final Offset scenePos = parentNode.position;
    final Offset targetViewport = Offset(
      viewportSize.width - 24,
      viewportSize.height / 2,
    );
    controller.value = Matrix4.identity();
    controller.value.setTranslationRaw(
      targetViewport.dx - scenePos.dx,
      targetViewport.dy - scenePos.dy,
      0.0,
    );
    await tester.pump();

    final Offset globalTap = renderBox.localToGlobal(scenePos);

    expect(graphState.collapsedParentIds, isNot(contains('group')));
    final TestWidgetsFlutterBinding binding = tester.binding;
    final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
    binding.handlePointerEvent(
      pointer.down(globalTap, buttons: kPrimaryButton),
    );
    await tester.pump();
    binding.handlePointerEvent(pointer.up());
    await tester.pumpAndSettle();

    expect(graphState.collapsedParentIds, contains('group'));
  });

  testWidgets(
    'parent tap near bottom boundary succeeds with vertical stack layout',
    (tester) async {
      await pumpGraphViewPage(tester);

      await tester.tap(find.byTooltip('Configure panels'));
      await tester.pumpAndSettle();
      await tester.tap(panelMenuItemFinder('Layout · Vertical stack'));
      await tester.pumpAndSettle();

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
      await tester.pump(const Duration(milliseconds: 16));

      final TransformationController controller =
          graphState.transformationController as TransformationController;
      final Finder graphPainterFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is GraphPainter,
      );
      final CustomPaint graphPaint = tester.widget<CustomPaint>(
        graphPainterFinder,
      );
      final GraphPainter painter = graphPaint.painter! as GraphPainter;
      final DisplayNode parentNode = painter.displayNodes.firstWhere(
        (node) => node.id == 'group',
      );

      final RenderBox renderBox =
          tester.renderObject(graphPainterFinder) as RenderBox;
      final Size viewportSize = renderBox.size;

      final Offset scenePos = parentNode.position;
      final Offset targetViewport = Offset(
        viewportSize.width / 2,
        viewportSize.height - 24,
      );
      controller.value = Matrix4.identity();
      controller.value.setTranslationRaw(
        targetViewport.dx - scenePos.dx,
        targetViewport.dy - scenePos.dy,
        0.0,
      );
      await tester.pump();

      final Offset globalTap = renderBox.localToGlobal(scenePos);

      expect(graphState.collapsedParentIds, isNot(contains('group')));
      final TestWidgetsFlutterBinding binding = tester.binding;
      final TestPointer pointer = TestPointer(2, PointerDeviceKind.mouse);
      binding.handlePointerEvent(
        pointer.down(globalTap, buttons: kPrimaryButton),
      );
      await tester.pump();
      binding.handlePointerEvent(pointer.up());
      await tester.pumpAndSettle();

      expect(graphState.collapsedParentIds, contains('group'));
    },
  );
}
