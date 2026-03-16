import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/src/focus_controller.dart';
import 'package:uyava_ui/src/journal/journal_controller.dart';
import 'package:uyava_ui/src/journal/journal_view_model.dart';

void main() {
  group('GraphJournalViewModel', () {
    late GraphController controller;
    late GraphJournalController journal;

    setUp(() {
      controller = GraphController(
        layoutConfig: const LayoutConfig(),
        diagnostics: GraphDiagnosticsBuffer(maxRecords: 500),
      );
      journal = GraphJournalController(graphController: controller);
    });

    tearDown(() {
      journal.dispose();
      controller.dispose();
    });

    test(
      'keeps events when graph is empty but graph filter binding is enabled',
      () {
        final DateTime now = DateTime.utc(2024, 1, 1, 12);
        journal.addNodeEvent(
          UyavaNodeEvent(nodeId: 'a', message: 'node', timestamp: now),
        );
        journal.addEdgeEvent(
          UyavaEvent(
            from: 'a',
            to: 'b',
            message: 'edge',
            timestamp: now.add(const Duration(milliseconds: 1)),
          ),
        );

        final GraphJournalViewModel viewModel = GraphJournalViewModel(
          journalState: journal.value,
          graphController: controller,
          focusState: GraphFocusState.empty,
          focusFilterPaused: true,
          respectsGraphFilter: true,
          normalizedQuery: '',
        );

        expect(viewModel.events, hasLength(2));
      },
    );

    test('honors graph filters when nodes exist but are filtered out', () {
      controller.replaceGraph(const <String, Object?>{
        'nodes': <Map<String, Object?>>[
          <String, Object?>{'id': 'a', 'type': 'service'},
          <String, Object?>{'id': 'b', 'type': 'service'},
        ],
        'edges': <Map<String, Object?>>[
          <String, Object?>{'id': 'e1', 'from': 'a', 'to': 'b'},
        ],
      }, const Size2D(800, 600));
      controller.updateFilters(
        GraphFilterState(
          nodes: GraphFilterNodeSet(
            include: const <String>['z'],
            exclude: const <String>[],
          ),
        ),
      );
      journal.addEdgeEvent(
        UyavaEvent(
          from: 'a',
          to: 'b',
          message: 'edge',
          timestamp: DateTime.utc(2024, 1, 1, 12),
        ),
      );

      final GraphJournalViewModel viewModel = GraphJournalViewModel(
        journalState: journal.value,
        graphController: controller,
        focusState: GraphFocusState.empty,
        focusFilterPaused: true,
        respectsGraphFilter: true,
        normalizedQuery: '',
      );

      expect(viewModel.events, isEmpty);
    });

    test(
      'keeps events referencing unknown nodes while graph filters are applied',
      () {
        controller.replaceGraph(const <String, Object?>{
          'nodes': <Map<String, Object?>>[
            <String, Object?>{'id': 'a', 'type': 'service'},
          ],
          'edges': <Map<String, Object?>>[],
        }, const Size2D(800, 600));
        controller.updateFilters(
          GraphFilterState(
            nodes: GraphFilterNodeSet(
              include: const <String>['a'],
              exclude: const <String>[],
            ),
          ),
        );
        journal.addNodeEvent(
          UyavaNodeEvent(
            nodeId: 'missing',
            message: 'unknown node',
            timestamp: DateTime.utc(2024, 1, 1, 12),
          ),
        );

        final GraphJournalViewModel viewModel = GraphJournalViewModel(
          journalState: journal.value,
          graphController: controller,
          focusState: GraphFocusState.empty,
          focusFilterPaused: true,
          respectsGraphFilter: true,
          normalizedQuery: '',
        );

        expect(viewModel.events, hasLength(1));
        expect(viewModel.events.first.nodeEvent?.nodeId, 'missing');
      },
    );
  });
}
