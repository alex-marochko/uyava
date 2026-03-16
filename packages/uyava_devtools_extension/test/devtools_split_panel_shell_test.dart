import 'package:devtools_app_shared/ui.dart' as devtools_ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_devtools_extension/src/panel_shell/devtools_split_panel_shell.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const panelA = UyavaPanelId('panelA');
  const panelB = UyavaPanelId('panelB');
  const leafA = UyavaPanelLeaf(panelA);
  const leafB = UyavaPanelLeaf(panelB);

  UyavaPanelShellSpec horizontalSpec() => UyavaPanelShellSpec(
    root: UyavaPanelSplit(
      key: 'root',
      axis: UyavaPanelSplitAxis.horizontal,
      children: const [leafA, leafB],
    ),
  );

  UyavaPanelShellSpec verticalSpec() => UyavaPanelShellSpec(
    root: UyavaPanelSplit(
      key: 'root',
      axis: UyavaPanelSplitAxis.vertical,
      children: const [leafA, leafB],
    ),
  );

  UyavaPanelShellController buildController(UyavaPanelShellSpec spec) =>
      UyavaPanelShellController(
        registry: [
          UyavaPanelRegistryEntry(id: panelA, title: 'Panel A'),
          UyavaPanelRegistryEntry(id: panelB, title: 'Panel B'),
        ],
        spec: spec,
      );

  List<UyavaPanelDefinition> buildDefinitions() => [
    UyavaPanelDefinition(
      id: panelA,
      title: 'Panel A',
      builder: (context, panelContext) => const Text('Panel A content'),
      minimumSize: const Size(320, 240),
    ),
    UyavaPanelDefinition(
      id: panelB,
      title: 'Panel B',
      builder: (context, panelContext) => const Text('Panel B content'),
      minimumSize: const Size(320, 240),
    ),
  ];

  Widget buildShell(UyavaPanelShellController controller) => MaterialApp(
    home: Scaffold(
      body: DevToolsSplitPanelShell(
        controller: controller,
        definitions: buildDefinitions(),
      ),
    ),
  );

  testWidgets('reflects controller visibility updates', (tester) async {
    final controller = buildController(horizontalSpec());
    await tester.pumpWidget(buildShell(controller));
    await tester.pump();

    expect(find.text('Panel A content'), findsOneWidget);
    expect(find.text('Panel B content'), findsOneWidget);

    controller.setVisibility(panelB, UyavaPanelVisibility.hidden);
    await tester.pumpAndSettle();
    expect(find.text('Panel B content'), findsNothing);

    controller.setVisibility(panelB, UyavaPanelVisibility.visible);
    await tester.pumpAndSettle();
    expect(find.text('Panel B content'), findsOneWidget);
  });

  testWidgets('propagates focus to controller on tap', (tester) async {
    final controller = buildController(horizontalSpec());
    await tester.pumpWidget(buildShell(controller));
    await tester.pump();

    expect(controller.state.focusedPanel, isNull);

    await tester.tap(find.text('Panel B content'));
    await tester.pump();

    expect(controller.state.focusedPanel, equals(panelB));
  });

  testWidgets('resizing horizontally updates fractions', (tester) async {
    final controller = buildController(horizontalSpec());
    await tester.pumpWidget(buildShell(controller));
    await tester.pumpAndSettle();

    final Finder splitPaneFinder = find.byType(devtools_ui.SplitPane);
    final devtools_ui.SplitPane splitPane = tester
        .widget<devtools_ui.SplitPane>(splitPaneFinder);
    final Finder handleFinder = find.byKey(splitPane.dividerKey(0));

    final double initialWidth = tester
        .getSize(find.text('Panel A content'))
        .width;

    await tester.drag(handleFinder, const Offset(80, 0));
    await tester.pumpAndSettle();

    final double updatedWidth = tester
        .getSize(find.text('Panel A content'))
        .width;
    expect(updatedWidth, greaterThan(initialWidth));

    final double updatedFraction = controller.splitFractionForSlot(leafA, 2);
    expect(updatedFraction, greaterThan(0.5));
  });

  testWidgets('resizing vertically updates fractions', (tester) async {
    final controller = buildController(verticalSpec());
    await tester.pumpWidget(buildShell(controller));
    await tester.pumpAndSettle();

    final Finder splitPaneFinder = find.byType(devtools_ui.SplitPane);
    final devtools_ui.SplitPane splitPane = tester
        .widget<devtools_ui.SplitPane>(splitPaneFinder);
    final Finder handleFinder = find.byKey(splitPane.dividerKey(0));

    final double initialHeight = tester
        .getSize(find.text('Panel A content'))
        .height;

    await tester.drag(handleFinder, const Offset(0, 80));
    await tester.pumpAndSettle();

    final double updatedHeight = tester
        .getSize(find.text('Panel A content'))
        .height;
    expect(updatedHeight, greaterThan(initialHeight));

    final double updatedFraction = controller.splitFractionForSlot(leafA, 2);
    expect(updatedFraction, greaterThan(0.5));
  });
}
