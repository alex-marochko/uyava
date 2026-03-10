import 'dart:math' as math;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:uyava_core/uyava_core.dart';

class GraphValidationBenchmark extends BenchmarkBase {
  GraphValidationBenchmark() : super('graph_validation_1k');

  late GraphController _controller;
  late Map<String, dynamic> _payload;

  @override
  void setup() {
    _controller = GraphController(engine: _NoopLayoutEngine());
    _payload = _buildPayload(nodeCount: 1000, extraEdgesPerNode: 1);
  }

  @override
  void run() {
    _controller.replaceGraph(_payload, const Size2D(1920, 1080));
  }
}

Map<String, dynamic> _buildPayload({
  required int nodeCount,
  required int extraEdgesPerNode,
}) {
  final List<Map<String, dynamic>> nodes = <Map<String, dynamic>>[];
  for (var i = 0; i < nodeCount; i++) {
    nodes.add({
      'id': 'node_$i',
      'label': 'Node $i',
      'type': i % 2 == 0 ? 'service' : 'repository',
    });
  }

  final List<Map<String, dynamic>> edges = <Map<String, dynamic>>[];
  for (var i = 0; i < nodeCount; i++) {
    final int target = (i + 1) % nodeCount;
    edges.add({
      'id': 'edge_${i}_$target',
      'source': 'node_$i',
      'target': 'node_$target',
    });
  }

  final math.Random random = math.Random(42);
  for (var i = 0; i < nodeCount * extraEdgesPerNode; i++) {
    final int from = random.nextInt(nodeCount);
    final int to = random.nextInt(nodeCount);
    if (from == to) continue; // skip self loops to keep payload valid
    edges.add({
      'id': 'edge_extra_${i}_${from}_$to',
      'source': 'node_$from',
      'target': 'node_$to',
    });
  }

  return {'nodes': nodes, 'edges': edges};
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
  GraphValidationBenchmark().report();
}
