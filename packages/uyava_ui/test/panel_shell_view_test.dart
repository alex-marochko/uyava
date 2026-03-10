import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const panelA = UyavaPanelId('panelA');
  const panelB = UyavaPanelId('panelB');

  UyavaPanelDefinition buildDefinition(UyavaPanelId id, String label) {
    return UyavaPanelDefinition(
      id: id,
      title: label,
      builder: (context, panelContext) => Container(
        key: ValueKey('panel-${id.value}'),
        alignment: Alignment.center,
        color: panelContext.hasFocus ? Colors.orange : Colors.grey.shade300,
        child: Text('$label(${panelContext.hasFocus})'),
      ),
    );
  }

  UyavaPanelShellController buildController() {
    return UyavaPanelShellController(
      registry: [
        buildDefinition(panelA, 'A').toRegistryEntry(),
        buildDefinition(panelB, 'B').toRegistryEntry(),
      ],
      spec: UyavaPanelShellSpec(
        root: UyavaPanelSplit(
          key: 'root',
          axis: UyavaPanelSplitAxis.horizontal,
          children: const [UyavaPanelLeaf(panelA), UyavaPanelLeaf(panelB)],
        ),
      ),
    );
  }

  group('UyavaPanelShellView', () {
    testWidgets('renders visible panels and responds to focus taps', (
      tester,
    ) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 600,
            height: 300,
            child: UyavaPanelShellView(
              controller: controller,
              definitions: [
                buildDefinition(panelA, 'A'),
                buildDefinition(panelB, 'B'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('panel-panelA')), findsOneWidget);
      expect(find.byKey(const ValueKey('panel-panelB')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('panel-panelB')));
      await tester.pump();
      expect(controller.state.focusedPanel, equals(panelB));
    });

    testWidgets('resizing updates controller fractions', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 600,
            height: 300,
            child: UyavaPanelShellView(
              controller: controller,
              definitions: [
                buildDefinition(panelA, 'A'),
                buildDefinition(panelB, 'B'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder handle = find.byKey(const ValueKey('uyavaSplitHandle-0'));
      final double initialFraction = controller.splitFractionFor(panelA, 2);

      await tester.drag(handle, const Offset(120, 0));
      await tester.pumpAndSettle();

      final double updatedFraction = controller.splitFractionFor(panelA, 2);
      expect(updatedFraction, greaterThan(initialFraction));
    });

    testWidgets('hidden panels are skipped within splits', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.setVisibility(panelB, UyavaPanelVisibility.hidden);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 600,
            height: 300,
            child: UyavaPanelShellView(
              controller: controller,
              definitions: [
                buildDefinition(panelA, 'A'),
                buildDefinition(panelB, 'B'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('panel-panelB')), findsNothing);
      expect(find.byKey(const ValueKey('panel-panelA')), findsOneWidget);
    });
  });
}
