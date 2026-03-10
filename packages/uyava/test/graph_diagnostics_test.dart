import 'package:test/test.dart';
import 'package:uyava/uyava.dart';

typedef _CapturedEvent = ({String type, Map<String, dynamic> payload});

void main() {
  group('Uyava diagnostics bridge', () {
    late List<_CapturedEvent> events;
    late List<Map<String, dynamic>> diagnostics;

    setUp(() {
      events = <_CapturedEvent>[];
      diagnostics = <Map<String, dynamic>>[];
      Uyava.replaceGraph();
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        final entry = (type: type, payload: Map<String, dynamic>.from(payload));
        events.add(entry);
        if (type == UyavaEventTypes.graphDiagnostics) {
          diagnostics.add(entry.payload);
        }
      };
    });

    tearDown(() {
      Uyava.postEventObserver = null;
      Uyava.replaceGraph();
    });

    test('emits diagnostic when addEdge references unknown source', () {
      Uyava.replaceGraph(nodes: <UyavaNode>[const UyavaNode(id: 'target')]);

      final stopwatch = Stopwatch()..start();
      Uyava.addEdge(
        const UyavaEdge(id: 'dangling', from: 'missing', to: 'target'),
      );
      stopwatch.stop();

      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 5)),
        reason:
            'addEdge should short-circuit invalid payloads quickly '
            '(actual ${stopwatch.elapsedMicroseconds} μs)',
      );

      expect(diagnostics, hasLength(1));
      final Map<String, dynamic> diag = diagnostics.single;
      expect(diag['codeEnum'], 'edgesDanglingSource');
      expect(diag['level'], UyavaDiagnosticLevel.error.toWireString());
      expect(diag['edgeId'], 'dangling');
      expect(diag['context'], containsPair('origin', 'addEdge'));
      expect(diag['context'], containsPair('source', 'missing'));
    });

    test('emits diagnostics for duplicate nodes during loadGraph', () {
      final stopwatch = Stopwatch()..start();
      Uyava.loadGraph(
        nodes: const <UyavaNode>[
          UyavaNode(id: 'a'),
          UyavaNode(id: 'a', label: 'dupe'),
        ],
      );
      stopwatch.stop();

      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'loadGraph should remain under the 200 ms guard '
            '(actual ${stopwatch.elapsedMilliseconds} ms)',
      );

      final duplicateDiagnostics = diagnostics.where(
        (diag) => diag['codeEnum'] == 'nodesDuplicateId',
      );
      expect(duplicateDiagnostics.length, 1);
      final Map<String, dynamic> duplicate = duplicateDiagnostics.single;
      expect(duplicate['nodeId'], 'a');
      expect(duplicate['context'], containsPair('source', 'loadGraph_batch'));
    });

    test('keeps diagnostics stream clean for valid loadGraph payload', () {
      final stopwatch = Stopwatch()..start();
      Uyava.loadGraph(
        nodes: const <UyavaNode>[
          UyavaNode(id: 'a', label: 'Service A'),
          UyavaNode(id: 'b', parentId: 'a'),
        ],
        edges: const <UyavaEdge>[UyavaEdge(id: 'ab', from: 'a', to: 'b')],
      );
      stopwatch.stop();

      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'loadGraph valid payload should stay within the 200 ms budget '
            '(actual ${stopwatch.elapsedMilliseconds} ms)',
      );
      expect(diagnostics, isEmpty);
    });

    test('logs conflicts when loadGraph overwrites node style', () {
      Uyava.replaceGraph(
        nodes: const <UyavaNode>[
          UyavaNode(id: 'foo', color: '#112233', tags: <String>['alpha']),
        ],
      );
      events.clear();
      diagnostics.clear();

      final stopwatch = Stopwatch()..start();
      Uyava.loadGraph(
        nodes: const <UyavaNode>[
          UyavaNode(
            id: 'foo',
            color: '#445566',
            tags: <String>['alpha', 'beta'],
          ),
        ],
      );
      stopwatch.stop();

      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'loadGraph overwrite should stay fast (actual '
            '${stopwatch.elapsedMilliseconds} ms)',
      );

      final codes = diagnostics.map((diag) => diag['codeEnum']).toSet();
      expect(codes.contains('nodesConflictingColor'), isTrue);
      expect(codes.contains('nodesConflictingTags'), isTrue);
      final duplicate = diagnostics.singleWhere(
        (diag) => diag['codeEnum'] == 'nodesDuplicateId',
      );
      expect(duplicate['nodeId'], 'foo');
      expect(
        duplicate['context'],
        containsPair('source', 'loadGraph_existing'),
      );
    });

    test(
      'ignores unknown ids in updateNodesListLifecycle without diagnostics',
      () {
        Uyava.replaceGraph(
          nodes: const <UyavaNode>[
            UyavaNode(id: 'a'),
            UyavaNode(id: 'b'),
          ],
        );
        events.clear();
        diagnostics.clear();

        final stopwatch = Stopwatch()..start();
        Uyava.updateNodesListLifecycle(
          nodeIds: const <String>['missing', 'a', 'missing', 'b'],
          state: UyavaLifecycleState.initialized,
        );
        stopwatch.stop();

        expect(
          stopwatch.elapsed,
          lessThan(const Duration(milliseconds: 5)),
          reason:
              'updateNodesListLifecycle should fan out quickly '
              '(actual ${stopwatch.elapsedMicroseconds} μs)',
        );

        expect(diagnostics, isEmpty);
        final lifecycleEvents = events.where(
          (event) => event.type == UyavaEventTypes.nodeLifecycle,
        );
        expect(lifecycleEvents.length, 2);
        final affectedIds = lifecycleEvents
            .map((event) => event.payload['nodeId'] as String)
            .toSet();
        expect(affectedIds, {'a', 'b'});
      },
    );
  });
}
