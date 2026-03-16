import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/src/focus_controller.dart';
import 'package:uyava_ui/src/journal/journal_controller.dart';
import 'package:uyava_ui/src/journal/journal_entry.dart';
import 'package:uyava_ui/src/journal/journal_link.dart';
import 'package:uyava_ui/src/journal/journal_view_model.dart';

void main() {
  test('GraphJournalViewModel caches detail payloads per entry', () {
    final graphController = GraphController(engine: GridLayout());
    final journalController = GraphJournalController(
      graphController: graphController,
    );

    addTearDown(() {
      journalController.dispose();
      graphController.dispose();
    });

    graphController.replaceGraph({
      'nodes': [
        {'id': 'nodeA', 'type': 'service'},
      ],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(600, 400));

    journalController.addNodeEvent(
      UyavaNodeEvent(
        nodeId: 'nodeA',
        message: 'hello world',
        timestamp: DateTime.utc(2024, 7, 15, 12),
        severity: UyavaSeverity.info,
        sourceRef: 'package:app/main.dart:10:5',
      ),
    );

    final viewModel = GraphJournalViewModel(
      journalState: journalController.value,
      graphController: graphController,
      focusState: GraphFocusState.empty,
      focusFilterPaused: false,
      respectsGraphFilter: true,
      normalizedQuery: '',
    );

    final Map<int, GraphJournalEventDetailCache> cache =
        <int, GraphJournalEventDetailCache>{};
    final GraphJournalEventEntry entry = viewModel.events.single;

    final GraphJournalEventDetailCache first = viewModel.ensureDetailCache(
      cache,
      entry,
    );
    final GraphJournalEventDetailCache second = viewModel.ensureDetailCache(
      cache,
      entry,
    );

    expect(identical(first, second), isTrue);
    expect(cache[entry.sequence], same(first));
    expect(first.subjectLabel, 'node:nodeA');
    expect(first.severityLabel, 'INFO');
    expect(first.focusTarget, isA<GraphJournalNodeLink>());
  });
}
