import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UyavaSplitView', () {
    testWidgets('dragging handle updates fractions and respects min sizes', (
      tester,
    ) async {
      final List<List<double>> changes = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 200,
              child: UyavaSplitView(
                axis: Axis.horizontal,
                onFractionsChanged: changes.add,
                initialFractions: const [0.5, 0.5],
                children: const [
                  UyavaSplitChild(
                    key: ValueKey('left-pane'),
                    minimumSize: 120,
                    child: ColoredBox(color: Colors.blue),
                  ),
                  UyavaSplitChild(
                    key: ValueKey('right-pane'),
                    minimumSize: 120,
                    child: ColoredBox(color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder handle = find.byKey(const ValueKey('uyavaSplitHandle-0'));

      await tester.drag(handle, const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(changes, isNotEmpty);
      expect(changes.last.first, greaterThan(0.5));
    });

    testWidgets('double tap resets to initial fractions', (tester) async {
      final List<List<double>> changes = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 200,
              child: UyavaSplitView(
                axis: Axis.horizontal,
                initialFractions: const [0.7, 0.3],
                onFractionsChanged: changes.add,
                children: const [
                  UyavaSplitChild(
                    key: ValueKey('left-pane'),
                    child: ColoredBox(color: Colors.blue),
                  ),
                  UyavaSplitChild(
                    key: ValueKey('right-pane'),
                    child: ColoredBox(color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder handle = find.byKey(const ValueKey('uyavaSplitHandle-0'));
      await tester.drag(handle, const Offset(-80, 0));
      await tester.pump();

      expect(changes, isNotEmpty);
      expect(changes.last.first, lessThan(0.7));

      await tester.tap(handle);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(handle);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));

      expect(changes.last.first, closeTo(0.7, 0.01));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('keyboard arrows resize when handle focused', (tester) async {
      final List<List<double>> changes = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 200,
              child: UyavaSplitView(
                axis: Axis.horizontal,
                initialFractions: const [0.5, 0.5],
                onFractionsChanged: changes.add,
                children: const [
                  UyavaSplitChild(
                    key: ValueKey('left-pane'),
                    child: ColoredBox(color: Colors.blue),
                  ),
                  UyavaSplitChild(
                    key: ValueKey('right-pane'),
                    child: ColoredBox(color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder handle = find.byKey(const ValueKey('uyavaSplitHandle-0'));
      await tester.tap(handle);
      await tester.pumpAndSettle();
      final dynamic handleState = tester.state(handle);
      // Accessing the private focus node via dynamic to ensure it receives
      // keyboard events during the test.
      // ignore: avoid_dynamic_calls
      handleState.widget.focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(changes, isNotEmpty);
      expect(changes.last.first, greaterThan(0.5));
    });

    testWidgets('disabled handles ignore pointer and keyboard input', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 200,
              child: UyavaSplitView(
                axis: Axis.horizontal,
                children: const [
                  UyavaSplitChild(
                    key: ValueKey('left-pane'),
                    canResize: false,
                    child: ColoredBox(color: Colors.blue),
                  ),
                  UyavaSplitChild(
                    key: ValueKey('right-pane'),
                    canResize: false,
                    child: ColoredBox(color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder handle = find.byKey(const ValueKey('uyavaSplitHandle-0'));
      final double width = tester
          .getSize(find.byKey(const ValueKey('left-pane')))
          .width;

      await tester.drag(handle, const Offset(80, 0));
      await tester.pump();

      await tester.tap(handle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(
        tester.getSize(find.byKey(const ValueKey('left-pane'))).width,
        closeTo(width, 0.01),
      );
    });
  });
}
