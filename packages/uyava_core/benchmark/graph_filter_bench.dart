import 'dart:math' as math;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

class GraphFilterBenchmark extends BenchmarkBase {
  GraphFilterBenchmark() : super('graph_filter_1k_filters');

  late GraphController _controller;
  late List<GraphFilterState> _states;
  int _stateIndex = 0;

  @override
  void setup() {
    _controller = GraphController(engine: _NoopLayoutEngine());
    final _FilterBenchmarkFixture fixture = _buildFixture(
      groupCount: 20,
      nodesPerGroup: 50,
      metricsPerGroup: 3,
      chainCount: 20,
    );

    _controller.replaceGraph(fixture.graphPayload, const Size2D(1920, 1080));

    for (final Map<String, dynamic> definition in fixture.metricDefinitions) {
      _controller.registerMetricDefinition(definition);
    }
    for (final Map<String, dynamic> sample in fixture.metricSamples) {
      _controller.recordMetricSample(sample);
    }
    for (final Map<String, dynamic> definition in fixture.chainDefinitions) {
      _controller.registerEventChainDefinition(definition);
    }
    for (final _ChainEvent event in fixture.chainEvents) {
      _controller.recordEventChainProgress(
        nodeId: event.nodeId,
        chain: event.chainPayload,
        severity: event.severity,
        timestamp: event.timestamp,
      );
    }

    _states = fixture.filterStates;
  }

  @override
  void run() {
    final GraphFilterState current = _states[_stateIndex];
    _stateIndex = (_stateIndex + 1) % _states.length;
    _controller.updateFilters(current);
  }
}

class _FilterBenchmarkFixture {
  const _FilterBenchmarkFixture({
    required this.graphPayload,
    required this.metricDefinitions,
    required this.metricSamples,
    required this.chainDefinitions,
    required this.chainEvents,
    required this.filterStates,
  });

  final Map<String, dynamic> graphPayload;
  final List<Map<String, dynamic>> metricDefinitions;
  final List<Map<String, dynamic>> metricSamples;
  final List<Map<String, dynamic>> chainDefinitions;
  final List<_ChainEvent> chainEvents;
  final List<GraphFilterState> filterStates;
}

class _ChainEvent {
  const _ChainEvent({
    required this.nodeId,
    required this.chainPayload,
    this.severity,
    required this.timestamp,
  });

  final String nodeId;
  final Map<String, String> chainPayload;
  final UyavaSeverity? severity;
  final DateTime timestamp;
}

_FilterBenchmarkFixture _buildFixture({
  required int groupCount,
  required int nodesPerGroup,
  required int metricsPerGroup,
  required int chainCount,
}) {
  final List<Map<String, dynamic>> nodes = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> edges = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> metricDefinitions = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> metricSamples = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> chainDefinitions = <Map<String, dynamic>>[];
  final List<_ChainEvent> chainEvents = <_ChainEvent>[];

  final math.Random random = math.Random(7);

  final List<String> domains = <String>[
    'domain:auth',
    'domain:checkout',
    'domain:inventory',
    'domain:notifications',
    'domain:analytics',
  ];

  for (var groupIndex = 0; groupIndex < groupCount; groupIndex++) {
    final String groupId = 'group_$groupIndex';
    final String groupTag = 'group:$groupIndex';
    nodes.add({
      'id': groupId,
      'label': 'Group $groupIndex',
      'type': 'group',
      'tags': <String>[groupTag, domains[groupIndex % domains.length]],
    });

    for (var nodeIndex = 0; nodeIndex < nodesPerGroup; nodeIndex++) {
      final String nodeId = 'node_${groupIndex}_$nodeIndex';
      final List<String> tags = <String>[
        domains[(groupIndex + nodeIndex) % domains.length],
        if (nodeIndex % 3 == 0) 'tier:critical' else 'tier:standard',
        if (nodeIndex % 7 == 0) 'chain:flow_${groupIndex % chainCount}',
      ];

      nodes.add({
        'id': nodeId,
        'label': 'Service ${groupIndex}_$nodeIndex',
        'type': 'service',
        'parentId': groupId,
        'tags': tags,
      });

      edges.add({
        'id': 'edge_parent_${groupIndex}_$nodeIndex',
        'source': groupId,
        'target': nodeId,
      });

      if (nodeIndex > 0) {
        final String prevNode = 'node_${groupIndex}_${nodeIndex - 1}';
        edges.add({
          'id': 'edge_chain_${groupIndex}_$nodeIndex',
          'source': prevNode,
          'target': nodeId,
        });
      }
    }

    for (var metricIndex = 0; metricIndex < metricsPerGroup; metricIndex++) {
      final String metricId = 'metric_${groupIndex}_$metricIndex';
      metricDefinitions.add({
        'id': metricId,
        'label': 'Latency ${groupIndex}_$metricIndex',
        'tags': <String>[
          domains[groupIndex % domains.length],
          'metric:latency',
        ],
        'aggregators': <String>['last', 'max', 'min', 'sum'],
      });
      metricSamples.add({
        'id': metricId,
        'value': 50 + random.nextDouble() * 100,
        'timestamp': DateTime.utc(
          2025,
          1,
          1,
          12,
          metricIndex,
          groupIndex,
        ).toIso8601String(),
      });
    }
  }

  final int totalNodes = groupCount * nodesPerGroup;
  for (var extra = 0; extra < totalNodes; extra++) {
    final int leftGroup = extra % groupCount;
    final int rightGroup = (extra + 3) % groupCount;
    final String from = 'node_${leftGroup}_${extra % nodesPerGroup}';
    final String to = 'node_${rightGroup}_${(extra * 7) % nodesPerGroup}';
    if (from == to) continue;
    edges.add({'id': 'edge_cross_$extra', 'source': from, 'target': to});
  }

  final int chainsToBuild = math.min(chainCount, groupCount);
  for (var chainIndex = 0; chainIndex < chainsToBuild; chainIndex++) {
    final String chainId = 'flow_$chainIndex';
    final String chainTag = 'chain:$chainId';
    final List<Map<String, String>> steps = <Map<String, String>>[];
    for (var step = 0; step < 4; step++) {
      steps.add({
        'stepId': 'step_$step',
        'nodeId': 'node_${chainIndex}_${(step * 5) % nodesPerGroup}',
      });
    }
    chainDefinitions.add({
      'id': chainId,
      'tag': chainTag,
      'label': 'Chain $chainIndex',
      'steps': steps,
    });

    final String attemptId = 'attempt_${chainIndex}_0';
    for (var step = 0; step < steps.length; step++) {
      final Map<String, String> stepData = steps[step];
      chainEvents.add(
        _ChainEvent(
          nodeId: stepData['nodeId']!,
          chainPayload: <String, String>{
            'id': chainId,
            'step': stepData['stepId']!,
            'attempt': attemptId,
          },
          severity: step.isEven ? UyavaSeverity.info : UyavaSeverity.warn,
          timestamp: DateTime.utc(2025, 1, 1, 12, chainIndex, step),
        ),
      );
    }
  }

  final List<GraphFilterState> states = <GraphFilterState>[
    GraphFilterState(
      search: GraphFilterSearch(
        mode: UyavaFilterSearchMode.substring,
        pattern: 'Service 1_',
        caseSensitive: false,
      ),
    ),
    GraphFilterState(
      tags: GraphFilterTags(
        mode: UyavaFilterTagsMode.include,
        values: <String>['domain:auth', 'tier:critical'],
        valuesNormalized: <String>['domain:auth', 'tier:critical'],
        logic: UyavaFilterTagLogic.any,
      ),
    ),
    GraphFilterState(
      parent: GraphFilterParent(rootId: 'group_0', depth: 2),
      grouping: GraphFilterGrouping(
        mode: UyavaFilterGroupingMode.level,
        levelDepth: 1,
      ),
      tags: GraphFilterTags(
        mode: UyavaFilterTagsMode.exclude,
        values: <String>['tier:standard'],
        valuesNormalized: <String>['tier:standard'],
        logic: UyavaFilterTagLogic.any,
      ),
    ),
  ];

  return _FilterBenchmarkFixture(
    graphPayload: <String, Object>{'nodes': nodes, 'edges': edges},
    metricDefinitions: metricDefinitions,
    metricSamples: metricSamples,
    chainDefinitions: chainDefinitions,
    chainEvents: chainEvents,
    filterStates: states,
  );
}

class _NoopLayoutEngine implements LayoutEngine {
  final Map<String, Vector2> _positions = <String, Vector2>{};

  @override
  bool get isConverged => true;

  @override
  Map<String, Vector2> get positions => _positions;

  @override
  void initialize({
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
    required Size2D size,
    Map<String, Vector2>? initialPositions,
  }) {
    _positions
      ..clear()
      ..addEntries(
        nodes.map(
          (node) =>
              MapEntry(node.id, initialPositions?[node.id] ?? Vector2.zero),
        ),
      );
  }

  @override
  void step() {}
}

void main() {
  GraphFilterBenchmark().report();
}
