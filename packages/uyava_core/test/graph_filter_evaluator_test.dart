import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('GraphFilterEngine', () {
    late List<UyavaNode> nodes;
    late List<UyavaEdge> edges;
    late List<GraphMetricSnapshot> metrics;
    late List<GraphEventChainSnapshot> chains;

    setUp(() {
      nodes = <UyavaNode>[
        UyavaNode.fromPayload(
          const UyavaGraphNodePayload(id: 'root', label: 'Root Node'),
        ),
        UyavaNode.fromPayload(
          const UyavaGraphNodePayload(
            id: 'worker',
            label: 'Latency Worker',
            parentId: 'root',
            tags: <String>['perf'],
            tagsNormalized: <String>['perf'],
          ),
        ),
        UyavaNode.fromPayload(
          const UyavaGraphNodePayload(id: 'db', label: 'Database'),
        ),
      ];

      edges = <UyavaEdge>[
        UyavaEdge.fromPayload(
          const UyavaGraphEdgePayload(
            id: 'edge_root_worker',
            source: 'root',
            target: 'worker',
          ),
        ),
      ];

      metrics = <GraphMetricSnapshot>[
        GraphMetricSnapshot(
          definition: const UyavaMetricDefinitionPayload(
            id: 'latency',
            label: 'Latency',
            tags: <String>['PERF'],
            tagsNormalized: <String>[],
            aggregators: <UyavaMetricAggregator>[UyavaMetricAggregator.last],
          ),
          aggregates: const <UyavaMetricAggregator, num>{
            UyavaMetricAggregator.last: 7,
          },
          severities: const <UyavaMetricAggregator, UyavaSeverity>{},
          sampleCount: 1,
          lastTimestamp: null,
        ),
        GraphMetricSnapshot(
          definition: const UyavaMetricDefinitionPayload(
            id: 'throughput',
            label: 'Requests',
            tags: <String>['ops'],
            tagsNormalized: <String>['ops'],
            aggregators: <UyavaMetricAggregator>[UyavaMetricAggregator.last],
          ),
          aggregates: const <UyavaMetricAggregator, num>{
            UyavaMetricAggregator.last: 100,
          },
          severities: const <UyavaMetricAggregator, UyavaSeverity>{},
          sampleCount: 1,
          lastTimestamp: null,
        ),
      ];

      chains = <GraphEventChainSnapshot>[
        GraphEventChainSnapshot(
          definition: const UyavaEventChainDefinitionPayload(
            id: 'login_chain',
            label: 'Login Flow',
            tags: <String>['perf'],
            tagsNormalized: <String>['perf'],
            steps: <UyavaEventChainStepPayload>[
              UyavaEventChainStepPayload(stepId: 'start', nodeId: 'root'),
            ],
          ),
          successCount: 1,
          failureCount: 0,
          activeAttempts: const <GraphEventChainAttemptSnapshot>[],
        ),
      ];
    });

    test('applies substring search across nodes and metrics', () {
      final GraphFilterResult result = GraphFilterEngine.apply(
        state: GraphFilterState(
          search: GraphFilterSearch(
            mode: UyavaFilterSearchMode.substring,
            pattern: 'latency',
            caseSensitive: false,
          ),
        ),
        nodes: nodes,
        edges: edges,
        metrics: metrics,
        eventChains: chains,
      );

      expect(result.visibleNodes.map((node) => node.id), ['root', 'worker']);
      expect(result.visibleEdges.map((edge) => edge.id), ['edge_root_worker']);
      expect(result.visibleMetrics.map((metric) => metric.id), ['latency']);
      expect(result.visibleEventChains, isEmpty);
    });

    test('filters by tags across nodes, metrics, and chains', () {
      final GraphFilterResult result = GraphFilterEngine.apply(
        state: GraphFilterState(
          tags: GraphFilterTags(
            mode: UyavaFilterTagsMode.include,
            values: const <String>['perf'],
            valuesNormalized: const <String>['perf'],
            logic: UyavaFilterTagLogic.any,
          ),
        ),
        nodes: nodes,
        edges: edges,
        metrics: metrics,
        eventChains: chains,
      );

      expect(result.visibleNodes.map((node) => node.id), ['root', 'worker']);
      expect(result.visibleMetrics.map((metric) => metric.id), ['latency']);
      expect(result.visibleEventChains.map((chain) => chain.id), [
        'login_chain',
      ]);
    });

    test(
      'filters metrics and chains when definitions lack normalized tags',
      () {
        final GraphEventChainSnapshot chain = GraphEventChainSnapshot(
          definition: const UyavaEventChainDefinitionPayload(
            id: 'legacy_chain',
            tags: <String>['PERF'],
            tagsNormalized: <String>[],
            steps: <UyavaEventChainStepPayload>[
              UyavaEventChainStepPayload(stepId: 'start', nodeId: 'root'),
            ],
          ),
          successCount: 0,
          failureCount: 0,
          activeAttempts: const <GraphEventChainAttemptSnapshot>[],
        );

        final GraphFilterResult result = GraphFilterEngine.apply(
          state: GraphFilterState(
            tags: GraphFilterTags(
              mode: UyavaFilterTagsMode.include,
              values: const <String>['perf'],
              valuesNormalized: const <String>['perf'],
              logic: UyavaFilterTagLogic.any,
            ),
          ),
          nodes: nodes,
          edges: edges,
          metrics: metrics,
          eventChains: <GraphEventChainSnapshot>[chain],
        );

        expect(result.visibleMetrics.map((metric) => metric.id), ['latency']);
        expect(result.visibleEventChains.map((chain) => chain.id), [
          'legacy_chain',
        ]);
      },
    );

    test('respects parent scopes and depth limits', () {
      final List<UyavaNode> scopedNodes = <UyavaNode>[
        UyavaNode.fromPayload(
          const UyavaGraphNodePayload(id: 'root', label: 'Root'),
        ),
        UyavaNode.fromPayload(
          const UyavaGraphNodePayload(
            id: 'mid',
            label: 'Mid',
            parentId: 'root',
          ),
        ),
        UyavaNode.fromPayload(
          const UyavaGraphNodePayload(
            id: 'leaf',
            label: 'Leaf',
            parentId: 'mid',
          ),
        ),
      ];

      final List<UyavaEdge> scopedEdges = <UyavaEdge>[
        UyavaEdge.fromPayload(
          const UyavaGraphEdgePayload(
            id: 'edge_root_mid',
            source: 'root',
            target: 'mid',
          ),
        ),
        UyavaEdge.fromPayload(
          const UyavaGraphEdgePayload(
            id: 'edge_mid_leaf',
            source: 'mid',
            target: 'leaf',
          ),
        ),
      ];

      final GraphFilterResult result = GraphFilterEngine.apply(
        state: const GraphFilterState(
          parent: GraphFilterParent(rootId: 'root', depth: 1),
        ),
        nodes: scopedNodes,
        edges: scopedEdges,
        metrics: const <GraphMetricSnapshot>[],
        eventChains: const <GraphEventChainSnapshot>[],
      );

      expect(result.visibleNodeIds, containsAll(<String>['root', 'mid']));
      expect(result.visibleNodeIds.contains('leaf'), isFalse);
      expect(result.hiddenByDepthNodeIds, contains('leaf'));
      expect(result.autoCollapsedParents, contains('mid'));
      expect(result.visibleEdges.map((edge) => edge.id), ['edge_root_mid']);
    });
  });
}
