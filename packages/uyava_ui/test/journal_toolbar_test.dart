import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';
import 'package:uyava_ui/src/journal/journal_toolbar.dart';
import 'package:uyava_ui/src/journal/journal_view_model.dart';

void main() {
  testWidgets('GraphJournalToolbar shows counts and triggers callbacks', (
    tester,
  ) async {
    final graphController = GraphController(engine: GridLayout());
    graphController.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(400, 300));

    final journalState = GraphJournalState(
      events: <GraphJournalEventEntry>[
        GraphJournalEventEntry.node(
          sequence: 0,
          event: UyavaNodeEvent(
            nodeId: 'nodeA',
            message: 'built',
            timestamp: DateTime.utc(2024, 1, 1),
          ),
          deltaSincePrevious: null,
        ),
      ],
      diagnostics: const <GraphDiagnosticRecord>[],
      eventsTrimmed: false,
      totalEventsTrimmed: 0,
    );

    final viewModel = GraphJournalViewModel(
      journalState: journalState,
      graphController: graphController,
      focusState: GraphFocusState.empty,
      focusFilterPaused: false,
      respectsGraphFilter: true,
      normalizedQuery: '',
    );

    addTearDown(() {
      graphController.dispose();
    });

    bool rawToggled = false;
    bool autoScrollPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) {
                final TabController tabController = DefaultTabController.of(
                  context,
                );
                return GraphJournalToolbar(
                  tabController: tabController,
                  viewModel: viewModel,
                  focusFilterPaused: false,
                  onFocusFilterToggle: () {},
                  onClearFocus: null,
                  onRemoveNodeFromFocus: null,
                  onRemoveEdgeFromFocus: null,
                  onRevealFocus: null,
                  respectsGraphFilter: true,
                  onGraphFilterToggle: () {},
                  isEventsTabActive: true,
                  isCurrentTabRaw: false,
                  onRawToggle: () => rawToggled = true,
                  autoScrollEnabled: true,
                  onAutoScrollPressed: () => autoScrollPressed = true,
                  onCopyVisibleLog: () {},
                  copyEnabled: true,
                  onClearLog: () {},
                  clearEnabled: true,
                  filterController: TextEditingController(),
                  onFocusPauseTooltip: 'Pause',
                  hasActiveFilters: false,
                  controlsEnabled: true,
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Events (1)'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);

    await tester.tap(find.byTooltip('Show event details'));
    expect(rawToggled, isTrue);

    await tester.tap(find.byTooltip('Disable auto-scroll'));
    expect(autoScrollPressed, isTrue);
  });

  testWidgets('GraphJournalToolbar prefers totalEventsCount when provided', (
    tester,
  ) async {
    final graphController = GraphController(engine: GridLayout());
    graphController.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(400, 300));

    final journalState = GraphJournalState(
      events: <GraphJournalEventEntry>[
        GraphJournalEventEntry.node(
          sequence: 0,
          event: UyavaNodeEvent(
            nodeId: 'nodeA',
            message: 'built',
            timestamp: DateTime.utc(2024, 1, 1),
          ),
          deltaSincePrevious: null,
        ),
      ],
      diagnostics: const <GraphDiagnosticRecord>[],
      eventsTrimmed: false,
      totalEventsTrimmed: 0,
    );

    final viewModel = GraphJournalViewModel(
      journalState: journalState,
      graphController: graphController,
      focusState: GraphFocusState.empty,
      focusFilterPaused: false,
      respectsGraphFilter: true,
      normalizedQuery: '',
    );

    addTearDown(() {
      graphController.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) {
                final TabController tabController = DefaultTabController.of(
                  context,
                );
                return GraphJournalToolbar(
                  tabController: tabController,
                  viewModel: viewModel,
                  totalEventsCount: 10,
                  totalWarnCount: 5,
                  totalCriticalCount: 7,
                  focusFilterPaused: false,
                  onFocusFilterToggle: () {},
                  onClearFocus: null,
                  onRemoveNodeFromFocus: null,
                  onRemoveEdgeFromFocus: null,
                  onRevealFocus: null,
                  respectsGraphFilter: true,
                  onGraphFilterToggle: () {},
                  isEventsTabActive: true,
                  isCurrentTabRaw: false,
                  onRawToggle: () {},
                  autoScrollEnabled: true,
                  onAutoScrollPressed: () {},
                  onCopyVisibleLog: () {},
                  copyEnabled: true,
                  onClearLog: () {},
                  clearEnabled: true,
                  filterController: TextEditingController(),
                  onFocusPauseTooltip: 'Pause',
                  hasActiveFilters: false,
                  controlsEnabled: true,
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Events (10)'), findsOneWidget);
    // Overrides applied.
    expect(find.textContaining('('), findsNWidgets(2));
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('GraphJournalToolbar uses visible counts when filters active', (
    tester,
  ) async {
    final graphController = GraphController(engine: GridLayout());
    graphController.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(400, 300));

    final journalState = GraphJournalState(
      events: <GraphJournalEventEntry>[
        GraphJournalEventEntry.node(
          sequence: 0,
          event: UyavaNodeEvent(
            nodeId: 'nodeA',
            message: 'built',
            severity: UyavaSeverity.warn,
            timestamp: DateTime.utc(2024, 1, 1),
          ),
          deltaSincePrevious: null,
        ),
      ],
      diagnostics: const <GraphDiagnosticRecord>[],
      eventsTrimmed: false,
      totalEventsTrimmed: 0,
    );

    final viewModel = GraphJournalViewModel(
      journalState: journalState,
      graphController: graphController,
      focusState: GraphFocusState.empty,
      focusFilterPaused: false,
      respectsGraphFilter: true,
      normalizedQuery: '',
    );

    addTearDown(() {
      graphController.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) {
                final TabController tabController = DefaultTabController.of(
                  context,
                );
                return GraphJournalToolbar(
                  tabController: tabController,
                  viewModel: viewModel,
                  totalEventsCount: 10,
                  totalWarnCount: 5,
                  totalCriticalCount: 7,
                  focusFilterPaused: false,
                  onFocusFilterToggle: () {},
                  onClearFocus: null,
                  onRemoveNodeFromFocus: null,
                  onRemoveEdgeFromFocus: null,
                  onRevealFocus: null,
                  respectsGraphFilter: true,
                  onGraphFilterToggle: () {},
                  isEventsTabActive: true,
                  isCurrentTabRaw: false,
                  onRawToggle: () {},
                  autoScrollEnabled: true,
                  onAutoScrollPressed: () {},
                  onCopyVisibleLog: () {},
                  copyEnabled: true,
                  onClearLog: () {},
                  clearEnabled: true,
                  filterController: TextEditingController(),
                  onFocusPauseTooltip: 'Pause',
                  hasActiveFilters: true,
                  controlsEnabled: true,
                );
              },
            ),
          ),
        ),
      ),
    );

    // Should fall back to visible counts when filters are active.
    final List<Text> texts = tester
        .widgetList<Text>(find.byType(Text))
        .toList();
    expect(texts.map((t) => t.data), contains('Events (1)'));
    expect(texts.map((t) => t.data), isNot(contains('Events (10)')));
  });
}
