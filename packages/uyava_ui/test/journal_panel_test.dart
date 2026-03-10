import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/uyava_ui.dart';
import 'package:uyava_ui/src/journal/journal_shared_widgets.dart';

void main() {
  testWidgets('renders events tab and updates when entries arrive', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'login_button', 'type': 'service'},
        {'id': 'login_submit', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Events (0)'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.textContaining('Node'), findsNothing);

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'login_button',
        message: 'login_button test event',
        timestamp: DateTime.utc(2024, 5, 1, 10, 0, 0),
        severity: UyavaSeverity.info,
        tags: const ['ui'],
        sourceRef: 'package:app/main.dart:10:5',
        isolateName: 'ui',
        isolateNumber: 1,
        isolateId: 'isol-login',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Events (1)'), findsOneWidget);
    expect(find.text('login_button'), findsOneWidget);
    expect(find.textContaining('login_button test event'), findsOneWidget);

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'login_submit',
        message: 'login_submit test event',
        timestamp: DateTime.utc(2024, 5, 1, 10, 0, 5, 500),
        severity: UyavaSeverity.warn,
        isolateName: 'worker',
        isolateNumber: 2,
        isolateId: 'isol-worker',
      ),
    );

    await tester.pump();

    expect(find.text('Events (2)'), findsOneWidget);
    expect(find.text('login_submit'), findsOneWidget);
    expect(find.text('login_submit test event'), findsOneWidget);
    expect(find.textContaining('+5.50 s'), findsOneWidget);
  });

  testWidgets('focus filters journal entries', (tester) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service', 'label': 'Node A'},
        {'id': 'nodeB', 'type': 'service', 'label': 'Node B'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'nodeA',
        message: 'nodeA test event',
        timestamp: DateTime.utc(2024, 5, 2, 12),
        severity: UyavaSeverity.info,
      ),
    );
    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'nodeB',
        message: 'nodeB test event',
        timestamp: DateTime.utc(2024, 5, 2, 12, 0, 10),
        severity: UyavaSeverity.warn,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState(nodeIds: {'nodeA'}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Events (1)'), findsOneWidget);
    expect(find.text('nodeA'), findsOneWidget);
    expect(find.text('nodeB'), findsNothing);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('Focus · 1 node'), findsOneWidget);
  });

  testWidgets('focus filtering can ignore main graph filter when disabled', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service', 'label': 'Node A'},
        {'id': 'nodeB', 'type': 'service', 'label': 'Node B'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    controller.updateFilters(
      GraphFilterState(
        nodes: GraphFilterNodeSet(
          include: const <String>[],
          exclude: const <String>['nodeA'],
        ),
      ),
    );

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'nodeA',
        message: 'nodeA test event',
        timestamp: DateTime.utc(2024, 5, 2, 12),
        severity: UyavaSeverity.info,
      ),
    );

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState(nodeIds: {'nodeA'}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Events (0)'), findsOneWidget);
    expect(find.text('nodeA'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState(nodeIds: {'nodeA'}),
              initialFocusRespectsGraphFilter: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Events (1)'), findsOneWidget);
    expect(find.text('nodeA'), findsOneWidget);
  });

  testWidgets('diagnostics list shows docs button and relative timing', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
        {'id': 'nodeB', 'type': 'service'},
      ],
      'edges': [
        {'id': 'edge1', 'source': 'nodeA', 'target': 'nodeB', 'type': 'route'},
      ],
    }, const Size2D(600, 400));

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    controller.addAppDiagnostic(
      code: 'nodes.invalid_color',
      level: UyavaDiagnosticLevel.warning,
      subjects: const ['nodeA'],
      context: const {'color': '#FF00FF'},
      timestamp: DateTime.utc(2024, 5, 1, 12, 0, 0),
    );
    controller.addAppDiagnostic(
      code: 'edges.dangling_source',
      level: UyavaDiagnosticLevel.error,
      subjects: const ['edge1'],
      context: const {'source': 'missing'},
      timestamp: DateTime.utc(2024, 5, 1, 12, 0, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              onOpenDiagnosticDocs: (_) async {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Diagnostics (2)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('nodesInvalidColor'), findsOneWidget);
    expect(find.textContaining('edgesDanglingSource'), findsOneWidget);
    expect(find.text('Docs'), findsNWidgets(2));
    expect(find.textContaining('+2.00 s'), findsOneWidget);

    expect(find.byTooltip('Show details'), findsNothing);
    expect(find.byTooltip('Hide details'), findsNothing);
    expect(find.text('Subjects:'), findsNWidgets(2));
  });

  testWidgets(
    'diagnostics with unknown subjects bypass graph visibility filter',
    (tester) async {
      final controller = GraphController(engine: GridLayout());
      final journal = GraphJournalController(graphController: controller);

      controller.replaceGraph({
        'nodes': [
          {'id': 'nodeA', 'type': 'service'},
          {'id': 'nodeB', 'type': 'service'},
        ],
        'edges': const <Map<String, Object?>>[],
      }, const Size2D(600, 400));

      controller.updateFilters(
        GraphFilterState(
          nodes: GraphFilterNodeSet(
            include: const ['nodeA'],
            exclude: const [],
          ),
        ),
      );

      addTearDown(() {
        journal.dispose();
        controller.dispose();
      });

      controller
        ..addAppDiagnostic(
          code: UyavaGraphIntegrityCode.nodesInvalidColor.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.nodesInvalidColor,
          level: UyavaDiagnosticLevel.warning,
          subjects: const ['nodeA'],
          timestamp: DateTime.utc(2024, 6, 2, 12, 0, 0),
        )
        ..addAppDiagnostic(
          code: UyavaGraphIntegrityCode.nodesConflictingTags.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.nodesConflictingTags,
          level: UyavaDiagnosticLevel.warning,
          subjects: const ['nodeB'],
          timestamp: DateTime.utc(2024, 6, 2, 12, 0, 1),
        )
        ..addAppDiagnostic(
          code: UyavaGraphIntegrityCode.edgesDanglingSource.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.edgesDanglingSource,
          level: UyavaDiagnosticLevel.error,
          subjects: const ['missing-edge'],
          context: const {'origin': 'loadGraph'},
          timestamp: DateTime.utc(2024, 6, 2, 12, 0, 2),
        );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: UyavaGraphJournalPanel(
                controller: journal,
                graphController: controller,
                focusState: GraphFocusState.empty,
                initialFocusRespectsGraphFilter: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Diagnostics (2)'), findsOneWidget);

      await tester.tap(find.text('Diagnostics (2)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('nodesInvalidColor'), findsOneWidget);
      expect(find.textContaining('edgesDanglingSource'), findsOneWidget);
      expect(find.textContaining('nodesConflictingTags'), findsNothing);
    },
  );

  testWidgets('subjectless diagnostics remain visible even with graph filter', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
        {'id': 'nodeB', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    controller.updateFilters(
      GraphFilterState(
        nodes: GraphFilterNodeSet(include: const ['nodeA'], exclude: const []),
      ),
    );

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    controller
      ..addAppDiagnostic(
        code: UyavaGraphIntegrityCode.nodesConflictingTags.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.nodesConflictingTags,
        level: UyavaDiagnosticLevel.warning,
        subjects: const ['nodeB'],
        timestamp: DateTime.utc(2024, 6, 3, 12, 0, 0),
      )
      ..addAppDiagnostic(
        code: UyavaGraphIntegrityCode.chainsInvalidStepOrder.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.chainsInvalidStepOrder,
        level: UyavaDiagnosticLevel.error,
        subjects: const <String>[],
        context: const {'chainId': 'checkout'},
        timestamp: DateTime.utc(2024, 6, 3, 12, 0, 1),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              initialFocusRespectsGraphFilter: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Diagnostics (1)'), findsOneWidget);

    await tester.tap(find.text('Diagnostics (1)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('chainsInvalidStepOrder'), findsOneWidget);
    expect(find.textContaining('nodesConflictingTags'), findsNothing);
  });

  testWidgets('details mode shows JSON payload for selected event', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'nodeA',
        message: 'nodeA test event',
        timestamp: DateTime.utc(2024, 5, 3, 9, 30),
        severity: UyavaSeverity.info,
        tags: const ['auth'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 260,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              initialEventsRaw: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('uyava_journal_event_details_panel')),
      findsNothing,
    );

    await tester.tap(find.text('nodeA'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('uyava_journal_event_details_panel')),
      findsOneWidget,
    );
    expect(find.textContaining('"nodeId": "nodeA"'), findsOneWidget);
  });

  testWidgets('trim notice stays over scrollable events list', (tester) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(
      graphController: controller,
      maxEntriesSoftLimit: 1,
    );

    controller.replaceGraph({
      'nodes': [
        {'id': 'node_0', 'type': 'service'},
        {'id': 'node_1', 'type': 'service'},
        {'id': 'node_2', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    for (int i = 0; i < 3; i++) {
      journal.addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'node_$i',
          message: 'node_$i test event',
          timestamp: DateTime.utc(2024, 5, 4, 9, 0, i),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 600,
              height: 220,
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

    expect(
      find.byKey(const PageStorageKey<String>('uyava_journal_events')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Showing the last 1 events; older entries were trimmed automatically.',
      ),
      findsOneWidget,
    );
    expect(find.text('node_2'), findsOneWidget);
  });

  testWidgets('clear log button removes events and diagnostics', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'nodeA',
        message: 'nodeA test event',
        timestamp: DateTime.utc(2024, 5, 2, 12),
      ),
    );
    controller.addAppDiagnostic(
      code: 'nodes.invalid_color',
      level: UyavaDiagnosticLevel.warning,
      subjects: const ['nodeA'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 260,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Events (1)'), findsOneWidget);
    expect(find.text('Diagnostics (1)'), findsOneWidget);

    final Finder clearButton = find.byTooltip('Clear log');
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('Events (0)'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
  });

  testWidgets('shows overflow notice when journal trims entries', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(
      graphController: controller,
      maxEntriesSoftLimit: 2,
    );

    controller.replaceGraph({
      'nodes': [
        {'id': 'a', 'type': 'service'},
        {'id': 'b', 'type': 'service'},
        {'id': 'c', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    journal
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'a',
          message: 'a test event',
          timestamp: DateTime.utc(2024, 5, 2, 12, 0),
        ),
      )
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'b',
          message: 'b test event',
          timestamp: DateTime.utc(2024, 5, 2, 12, 1),
        ),
      )
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'c',
          message: 'c test event',
          timestamp: DateTime.utc(2024, 5, 2, 12, 2),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 260,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Showing the last 2 events'), findsOneWidget);
  });

  testWidgets('details toggle splits events view when enabled', (tester) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);
    String? openedRef;
    final view = tester.view;
    view
      ..physicalSize = const Size(680, 800)
      ..devicePixelRatio = 1.0;

    controller.replaceGraph({
      'nodes': [
        {'id': 'widget_built', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    addTearDown(() {
      journal.dispose();
      controller.dispose();
      view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'widget_built',
        message: 'widget_built test event',
        timestamp: DateTime.utc(2024, 6, 1, 9, 30, 0),
        severity: UyavaSeverity.info,
        tags: const ['render'],
        sourceRef: 'package:test/widget.dart:42:10',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              onOpenInIde: (sourceRef) async {
                openedRef = sourceRef;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('widget_built'), findsOneWidget);
    expect(
      find.byKey(const Key('uyava_journal_event_details_panel')),
      findsNothing,
    );

    await tester.tap(find.text('widget_built'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('uyava_journal_event_details_panel')),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Show event details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('widget_built'));
    await tester.pumpAndSettle();

    final Finder detailsPanel = find.byKey(
      const Key('uyava_journal_event_details_panel'),
    );
    expect(detailsPanel, findsOneWidget);
    expect(find.textContaining('"nodeId": "widget_built"'), findsOneWidget);
    expect(find.text('package:test/widget.dart:42:10'), findsOneWidget);

    final GraphJournalMetadataChip sourceChip = tester
        .widgetList<GraphJournalMetadataChip>(
          find.byType(GraphJournalMetadataChip),
        )
        .firstWhere((chip) => chip.label == 'package:test/widget.dart:42:10');
    sourceChip.onPressed!();
    await tester.pump();
    expect(openedRef, equals('package:test/widget.dart:42:10'));

    await tester.tap(find.byTooltip('Show event details'));
    await tester.pumpAndSettle();

    expect(detailsPanel, findsNothing);
    expect(find.textContaining('"nodeId": "widget_built"'), findsNothing);
  });

  testWidgets('display controller switches to diagnostics tab', (tester) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);
    final displayController = GraphJournalDisplayController();

    addTearDown(() {
      displayController.dispose();
      journal.dispose();
      controller.dispose();
    });

    controller.addAppDiagnostic(
      code: 'nodes.invalid_color',
      level: UyavaDiagnosticLevel.warning,
      subjects: const ['nodeA'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              displayController: displayController,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder stackFinder = find.byWidgetPredicate(
      (widget) => widget is IndexedStack && widget.children.length == 2,
    );
    expect(stackFinder, findsOneWidget);
    final IndexedStack initial = tester
        .widgetList<IndexedStack>(stackFinder)
        .first;
    expect(initial.index, 0);

    displayController.setActiveTab(GraphJournalTab.diagnostics);
    await tester.pump();

    final IndexedStack updated = tester
        .widgetList<IndexedStack>(stackFinder)
        .first;
    expect(updated.index, 1);
  });

  testWidgets('journal graph filter toggle is visible without focus', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byTooltip('Journal follows primary graph filter'),
      findsOneWidget,
    );
  });

  testWidgets(
    'severity filter applies when journal is bound to primary filter',
    (tester) async {
      final controller = GraphController(engine: GridLayout());
      final journal = GraphJournalController(graphController: controller);

      controller.replaceGraph({
        'nodes': [
          {'id': 'nodeA', 'type': 'service'},
          {'id': 'nodeB', 'type': 'service'},
        ],
        'edges': const <Map<String, Object?>>[],
      }, const Size2D(600, 400));

      controller.updateFilters(
        const GraphFilterState(
          severity: GraphFilterSeverity(
            operator: UyavaFilterSeverityOperator.atLeast,
            level: UyavaSeverity.warn,
          ),
        ),
      );

      journal
        ..addNodeEvent(
          UyavaNodeEvent(
            nodeId: 'nodeA',
            message: 'nodeA test event',
            timestamp: DateTime.utc(2024, 6, 1, 12),
            severity: UyavaSeverity.info,
          ),
        )
        ..addNodeEvent(
          UyavaNodeEvent(
            nodeId: 'nodeB',
            message: 'nodeB test event',
            timestamp: DateTime.utc(2024, 6, 1, 12, 0, 5),
            severity: UyavaSeverity.warn,
          ),
        );

      addTearDown(() {
        journal.dispose();
        controller.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 220,
              child: UyavaGraphJournalPanel(
                controller: journal,
                graphController: controller,
                focusState: GraphFocusState.empty,
                initialFocusRespectsGraphFilter: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Events (1)'), findsOneWidget);
      expect(find.text('nodeB'), findsOneWidget);
      expect(find.text('nodeA'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 220,
              child: UyavaGraphJournalPanel(
                controller: journal,
                graphController: controller,
                focusState: GraphFocusState.empty,
                initialFocusRespectsGraphFilter: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Events (2)'), findsOneWidget);
      expect(find.text('nodeA'), findsOneWidget);
    },
  );

  testWidgets('copy visible log button disabled when journal empty', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(400, 300));

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              initialFocusRespectsGraphFilter: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final IconButton copyButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.copy_all_outlined),
    );
    expect(copyButton.onPressed, isNull);
  });

  testWidgets('copy visible log button disabled when filters hide entries', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
        {'id': 'nodeB', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    controller.updateFilters(
      GraphFilterState(
        nodes: GraphFilterNodeSet(include: const ['nodeB'], exclude: const []),
      ),
    );

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'nodeA',
        message: 'nodeA hidden event',
        timestamp: DateTime.utc(2024, 6, 2, 9),
      ),
    );

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              initialFocusRespectsGraphFilter: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final IconButton copyButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.copy_all_outlined),
    );
    expect(copyButton.onPressed, isNull);
  });

  testWidgets('copy visible log respects active filters', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
        {'id': 'nodeB', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    controller.updateFilters(
      GraphFilterState(
        nodes: GraphFilterNodeSet(include: const ['nodeA'], exclude: const []),
      ),
    );

    journal
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'nodeA',
          message: 'nodeA test event',
          timestamp: DateTime.utc(2024, 6, 2, 9),
        ),
      )
      ..addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'nodeB',
          message: 'nodeB test event',
          timestamp: DateTime.utc(2024, 6, 2, 9, 0, 5),
        ),
      );

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedText = methodCall.arguments['text'] as String?;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              initialFocusRespectsGraphFilter: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Copy current tab'));
    await tester.pump();

    expect(copiedText, isNotNull);
    final Map<String, dynamic> payload =
        jsonDecode(copiedText!) as Map<String, dynamic>;
    final List<dynamic> events = payload['events'] as List<dynamic>;
    expect(events, hasLength(1));
    expect(events.single['nodeId'], 'nodeA');
  });

  testWidgets('host adapter logs structured actions', (tester) async {
    final controller = GraphController(engine: GridLayout());
    final hostAdapter = GraphJournalHostAdapter(graphController: controller);

    addTearDown(() {
      hostAdapter.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: UyavaGraphJournalPanel(
              controller: hostAdapter.controller,
              graphController: controller,
              focusState: GraphFocusState.empty,
              hostAdapter: hostAdapter,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Journal follows primary graph filter'));
    await tester.pumpAndSettle();

    final List<GraphDiagnosticRecord> records = controller.diagnostics.records;
    expect(records, isNotEmpty);
    final GraphDiagnosticRecord log = records.last;
    expect(log.code, 'journal.toggle_graph_filter_binding');
    expect(log.context?['action'], 'toggle_graph_filter_binding');
  });

  testWidgets('copy diagnostics tab exports diagnostics only', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(400, 300));

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'nodeA',
        message: 'nodeA event',
        timestamp: DateTime.utc(2024, 6, 3, 10),
      ),
    );
    controller.addAppDiagnostic(
      code: 'nodes.invalid_color',
      level: UyavaDiagnosticLevel.warning,
      subjects: const ['nodeA'],
      timestamp: DateTime.utc(2024, 6, 3, 10, 0, 1),
    );

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedText = methodCall.arguments['text'] as String?;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 260,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              initialFocusRespectsGraphFilter: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Diagnostics'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Copy current tab'));
    await tester.pump();

    expect(copiedText, isNotNull);
    final Map<String, dynamic> payload =
        jsonDecode(copiedText!) as Map<String, dynamic>;
    expect(payload.containsKey('events'), isFalse);
    final List<dynamic> diagnostics = payload['diagnostics'] as List<dynamic>;
    expect(diagnostics, hasLength(1));
    expect(diagnostics.single['code'], 'nodes.invalid_color');
  });

  testWidgets('copy button disabled when active tab has no entries', (
    tester,
  ) async {
    final controller = GraphController(engine: GridLayout());
    final journal = GraphJournalController(graphController: controller);

    controller.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(400, 300));

    journal.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'nodeA',
        message: 'nodeA event',
        timestamp: DateTime.utc(2024, 6, 3, 11),
      ),
    );

    addTearDown(() {
      journal.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              initialFocusRespectsGraphFilter: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diagnostics'));
    await tester.pumpAndSettle();

    final IconButton copyButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.copy_all_outlined),
    );
    expect(copyButton.onPressed, isNull);
  });
}
