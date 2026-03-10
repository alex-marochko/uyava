import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_devtools_extension/graph_view_page.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  testWidgets('Panel menu propagates selection state', (tester) async {
    var toggledDashboard = 0;
    final toggles = [
      UyavaPanelMenuToggle(
        label: 'Dashboard panel',
        isChecked: () => false,
        onToggle: () => toggledDashboard++,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UyavaPanelMenu(
            isStackedLayout: true,
            onLayoutStacked: () {},
            onLayoutGraphWithDetails: () {},
            toggles: toggles,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(UyavaPanelMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dashboard panel'));
    expect(toggledDashboard, 1);
  });

  testWidgets('DiagnosticsBanner shows count and invokes callback', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiagnosticsBanner(count: 3, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byType(DiagnosticsBanner));
    expect(tapped, isTrue);
  });

  testWidgets('GraphViewScaffold toggles filters panel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GraphViewScaffold(
          filtersVisible: true,
          filtersPanelBuilder: (context) => const Text('filters'),
          topBarActions: const [],
          panelShell: const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text('filters'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: GraphViewScaffold(
          filtersVisible: false,
          filtersPanelBuilder: (context) => const Text('filters'),
          topBarActions: [DiagnosticsBanner(count: 2, onTap: () {})],
          panelShell: const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text('filters'), findsNothing);
    expect(find.byType(DiagnosticsBanner), findsOneWidget);
  });

  testWidgets('HoverOverlay proxies to GraphHoverOverlay', (tester) async {
    final node = UyavaNode(
      rawData: const {'id': 'a', 'type': 'service', 'label': 'A'},
    );
    final displayNode = DisplayNode(node: node, position: Offset.zero);
    final target = GraphHoverTarget.node(displayNode);
    final details = GraphHoverDetails(
      target: target,
      viewportPosition: Offset.zero,
      scenePosition: Offset.zero,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              HoverOverlay(
                details: details,
                viewportSize: const Size(400, 400),
                anchorViewportPosition: const Offset(10, 20),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(GraphHoverOverlay), findsOneWidget);
  });

  testWidgets('GraphViewportPane invokes builder with panel context', (
    tester,
  ) async {
    const panelContext = UyavaPanelContext(
      hasFocus: true,
      availableSize: Size(100, 80),
    );
    final built = <Size>[];
    await tester.pumpWidget(
      MaterialApp(
        home: GraphViewportPane(
          builder: (ctx, ctxPanel) {
            built.add(ctxPanel.availableSize);
            return const Text('built pane');
          },
          panelContext: panelContext,
        ),
      ),
    );
    expect(built, equals([panelContext.availableSize]));
    expect(find.text('built pane'), findsOneWidget);
  });
}
