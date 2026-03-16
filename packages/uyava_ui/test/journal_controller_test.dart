import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  late GraphController graphController;

  setUp(() {
    graphController = GraphController(engine: GridLayout());
  });

  tearDown(() {
    graphController.dispose();
  });

  test('adds node events without trimming and keeps snapshots stable', () {
    final journal = GraphJournalController(graphController: graphController);

    addTearDown(journal.dispose);

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'a',
        message: 'a test event',
        timestamp: DateTime.utc(2024, 1, 1, 12, 0, 0, 100),
      ),
    );
    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'b',
        message: 'b test event',
        timestamp: DateTime.utc(2024, 1, 1, 12, 0, 1, 200),
      ),
    );
    final snapshot = journal.events;
    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'c',
        message: 'c test event',
        timestamp: DateTime.utc(2024, 1, 1, 12, 0, 2, 300),
      ),
    );

    expect(journal.events.length, 3);
    expect(journal.value.events.first.nodeEvent!.nodeId, 'a');
    expect(journal.value.events.last.nodeEvent!.nodeId, 'c');
    expect(journal.value.events.first.deltaSincePrevious, isNull);
    expect(
      journal.value.events.last.deltaSincePrevious,
      const Duration(milliseconds: 1100),
    );
    expect(snapshot.length, 2);
    expect(snapshot.last.nodeEvent!.nodeId, 'b');
    expect(journal.value.totalEventsTrimmed, 0);
  });

  test('listens to diagnostics stream without truncating records', () async {
    final journal = GraphJournalController(graphController: graphController);
    addTearDown(journal.dispose);

    // Initial state mirrors the controller.
    expect(journal.diagnostics, isEmpty);

    graphController.addAppDiagnostic(
      code: 'nodes.test',
      level: UyavaDiagnosticLevel.warning,
    );
    await pumpEventQueue();
    expect(journal.diagnostics, hasLength(1));

    graphController.addAppDiagnostic(
      code: 'edges.test',
      level: UyavaDiagnosticLevel.error,
    );
    graphController.addAppDiagnostic(
      code: 'extra',
      level: UyavaDiagnosticLevel.info,
    );
    await pumpEventQueue();

    expect(journal.diagnostics, hasLength(3));
    // Latest entries should remain.
    final codes = journal.diagnostics.map((record) => record.code);
    expect(codes, containsAll(['nodes.test', 'edges.test', 'extra']));
  });

  test('soft limit trims oldest entries and flags state', () {
    final journal = GraphJournalController(
      graphController: graphController,
      maxEntriesSoftLimit: 2,
    );

    addTearDown(journal.dispose);

    journal
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'a',
          message: 'a test event',
          timestamp: DateTime.utc(2024, 1, 1, 12, 0),
        ),
      )
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'b',
          message: 'b test event',
          timestamp: DateTime.utc(2024, 1, 1, 12, 1),
        ),
      )
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'c',
          message: 'c test event',
          timestamp: DateTime.utc(2024, 1, 1, 12, 2),
        ),
      );

    expect(journal.events.length, 2);
    expect(journal.value.events.first.nodeEvent!.nodeId, 'b');
    expect(journal.value.eventsTrimmed, isTrue);
    expect(journal.value.events.first.deltaSincePrevious, isNull);
    expect(journal.value.totalEventsTrimmed, 1);
  });

  test('large overflow trims in batches but caps the snapshot size', () {
    const int limit = 128;
    const int extra = 1500;
    final journal = GraphJournalController(
      graphController: graphController,
      maxEntriesSoftLimit: limit,
    );
    addTearDown(journal.dispose);

    final DateTime base = DateTime.utc(2024, 1, 1, 12, 0);
    for (int i = 0; i < limit + extra; i++) {
      journal.addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'node_$i',
          message: 'node_$i test event',
          timestamp: base.add(Duration(milliseconds: i)),
        ),
      );
    }

    expect(journal.events.length, limit);
    expect(journal.value.eventsTrimmed, isTrue);
    expect(journal.value.totalEventsTrimmed, extra);
    expect(journal.value.events.first.deltaSincePrevious, isNull);
  });

  test('clearLog removes events and diagnostics', () async {
    final journal = GraphJournalController(
      graphController: graphController,
      maxEntriesSoftLimit: 1,
    );
    addTearDown(journal.dispose);

    journal
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'z',
          message: 'z test event',
          timestamp: DateTime.utc(2024, 1, 1, 12, 0),
        ),
      )
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'y',
          message: 'y test event',
          timestamp: DateTime.utc(2024, 1, 1, 12, 0, 1),
        ),
      );
    graphController.addAppDiagnostic(
      code: 'nodes.test',
      level: UyavaDiagnosticLevel.warning,
    );
    await pumpEventQueue();
    expect(journal.events, isNotEmpty);
    expect(journal.diagnostics, isNotEmpty);
    expect(journal.value.eventsTrimmed, isTrue);

    journal.clearLog();
    await pumpEventQueue();

    expect(journal.events, isEmpty);
    expect(journal.diagnostics, isEmpty);
    expect(graphController.diagnostics.records, isEmpty);
    expect(journal.value.eventsTrimmed, isFalse);
    expect(journal.value.totalEventsTrimmed, 0);
  });

  test('preserves source metadata on journal entries', () {
    final journal = GraphJournalController(graphController: graphController);
    addTearDown(journal.dispose);

    journal
      ..addEdgeEvent(
        UyavaEvent(
          from: 'a',
          to: 'b',
          message: 'edge with source',
          timestamp: DateTime.utc(2024, 1, 1, 12, 0),
          sourceId: 'routerA',
          sourceType: 'vmService',
        ),
      )
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'c',
          message: 'node with source',
          timestamp: DateTime.utc(2024, 1, 1, 12, 0, 1),
          sourceId: 'routerA',
          sourceType: 'vmService',
        ),
      );

    expect(journal.events.first.sourceId, 'routerA');
    expect(journal.events.first.sourceType, 'vmService');
    expect(journal.events.last.sourceId, 'routerA');
    expect(journal.events.last.sourceType, 'vmService');
  });
}
