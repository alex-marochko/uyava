import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final bool passed =
        result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpJournal(
    WidgetTester tester, {
    required GraphJournalController journal,
    required GraphController controller,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 500);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 720,
              height: 420,
              child: UyavaGraphJournalPanel(
                controller: journal,
                graphController: controller,
                focusState: GraphFocusState.empty,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UyavaGraphJournalPanel golden', () {
    final GoldenFileComparator previousComparator = goldenFileComparator;
    setUpAll(() {
      goldenFileComparator = _TolerantGoldenFileComparator(
        Uri.parse('test/journal_panel_golden_test.dart'),
        precisionTolerance: 0.02,
      );
    });
    tearDownAll(() {
      goldenFileComparator = previousComparator;
    });

    testWidgets('events tab renders latest entries', (tester) async {
      final controller = GraphController(engine: GridLayout());
      final journal = GraphJournalController(graphController: controller);
      addTearDown(() {
        journal.dispose();
        controller.dispose();
      });

      controller.replaceGraph({
        'nodes': [
          {'id': 'nodeA', 'label': 'Node A'},
          {'id': 'nodeB', 'label': 'Node B'},
        ],
        'edges': const <Map<String, Object?>>[],
      }, const Size2D(600, 400));

      journal.addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'nodeA',
          message: 'User tapped login button',
          severity: UyavaSeverity.info,
          timestamp: DateTime.utc(2024, 5, 1, 10, 0, 0),
          tags: const ['ui', 'flow'],
        ),
      );
      journal.addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'nodeB',
          message: 'Form validation failed',
          severity: UyavaSeverity.warn,
          timestamp: DateTime.utc(2024, 5, 1, 10, 0, 3, 250),
          tags: const ['validation'],
        ),
      );

      await pumpJournal(tester, journal: journal, controller: controller);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/journal_panel_events.png'),
      );
    });

    testWidgets('diagnostics tab displays warnings', (tester) async {
      final controller = GraphController(engine: GridLayout());
      final journal = GraphJournalController(graphController: controller);
      addTearDown(() {
        journal.dispose();
        controller.dispose();
      });

      controller.replaceGraph({
        'nodes': [
          {'id': 'nodeA', 'label': 'Node A'},
        ],
        'edges': const <Map<String, Object?>>[],
      }, const Size2D(600, 400));

      controller.diagnostics.addAppDiagnostic(
        code: 'nodes.invalid_color',
        level: UyavaDiagnosticLevel.warning,
        subjects: const ['nodeA'],
        context: const {'color': '#ZZZZZZ'},
      );
      controller.diagnostics.addAppDiagnostic(
        code: 'edges.dangling_target',
        level: UyavaDiagnosticLevel.error,
        subjects: const ['edge-login'],
        context: const {'target': 'missing_node'},
      );
      journal.refreshDiagnostics();
      expect(journal.value.diagnostics, hasLength(2));

      await pumpJournal(tester, journal: journal, controller: controller);
      await tester.tap(find.textContaining('Diagnostics'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/journal_panel_diagnostics.png'),
      );
    });
  });
}
