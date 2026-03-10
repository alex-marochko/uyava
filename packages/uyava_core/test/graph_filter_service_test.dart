import 'dart:async';

import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('GraphFilterService', () {
    late GraphDiagnosticsService diagnostics;
    late GraphFilterService service;
    late GraphFilterContext context;

    setUp(() {
      diagnostics = GraphDiagnosticsService();
      service = GraphFilterService(diagnosticsService: diagnostics);

      context = GraphFilterContext(
        nodes: <UyavaNode>[
          UyavaNode.fromPayload(
            const UyavaGraphNodePayload(id: 'a', label: 'Alpha'),
          ),
          UyavaNode.fromPayload(
            const UyavaGraphNodePayload(id: 'b', label: 'Beta'),
          ),
        ],
        edges: const <UyavaEdge>[],
        metrics: const <GraphMetricSnapshot>[],
        eventChains: const <GraphEventChainSnapshot>[],
      );
    });

    test('applies sanitized search commands and emits filtered view', () async {
      final List<GraphFilterResult> emissions = <GraphFilterResult>[];
      final StreamSubscription<GraphFilterResult> subscription = service.stream
          .listen(emissions.add);

      final GraphFilterUpdateResult result = service.updateFromCommand(
        <String, Object?>{
          'search': const <String, Object?>{'pattern': 'Alpha'},
        },
        context,
      );

      expect(result.applied, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(
        service.result.visibleNodes.map((node) => node.id),
        containsAll(<String>['a']),
      );
      expect(emissions, isNotEmpty);

      await subscription.cancel();
    });

    test(
      'records diagnostics for unknown nodes and keeps state consistent',
      () {
        final GraphFilterState nextState = GraphFilterState(
          nodes: GraphFilterNodeSet(
            include: const <String>['missing'],
            exclude: const <String>[],
          ),
        );

        final GraphFilterUpdateResult result = service.update(
          nextState,
          context,
        );

        expect(result.applied, isTrue);
        expect(result.diagnostics, hasLength(1));
        expect(
          diagnostics.diagnostics.records.map((record) => record.code),
          contains(UyavaGraphIntegrityCode.filtersUnknownNode.toWireString()),
        );
      },
    );

    test('rebuild reapplies current filters to new context', () {
      service.updateFromCommand(<String, Object?>{
        'search': const <String, Object?>{'pattern': 'Alpha'},
      }, context);

      final GraphFilterContext nextContext = GraphFilterContext(
        nodes: <UyavaNode>[
          UyavaNode.fromPayload(
            const UyavaGraphNodePayload(id: 'c', label: 'Gamma'),
          ),
        ],
        edges: const <UyavaEdge>[],
        metrics: const <GraphMetricSnapshot>[],
        eventChains: const <GraphEventChainSnapshot>[],
      );

      service.rebuild(nextContext);

      expect(service.result.visibleNodes, isEmpty);
      expect(service.result.state.search?.pattern, 'Alpha');
    });
  });
}
