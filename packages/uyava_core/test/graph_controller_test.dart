import 'package:test/test.dart';

import 'package:uyava_core/uyava_core.dart';

class _MockEngine implements LayoutEngine {
  bool _converged = false;
  final Map<String, Vector2> _positions = {};
  int steps = 0;

  @override
  void initialize({
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
    required Size2D size,
    Map<String, Vector2>? initialPositions,
  }) {
    _positions
      ..clear()
      ..addEntries(nodes.map((n) => MapEntry(n.id, const Vector2(0, 0))));
    _converged = false;
    steps = 0;
  }

  @override
  bool get isConverged => _converged;

  @override
  Map<String, Vector2> get positions => Map.unmodifiable(_positions);

  @override
  void step() {
    steps += 1;
    // Move each node by +1 on x per step.
    _positions.updateAll((key, value) => value + const Vector2(1, 0));
    // Converge after first step for test simplicity.
    _converged = true;
  }
}

void main() {
  group('GraphController with injected LayoutEngine', () {
    test('replaceGraph initializes positions via engine', () {
      final engine = _MockEngine();
      final controller = GraphController(engine: engine);

      final graphData = {
        'nodes': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'edges': [
          {'id': 'a-b', 'source': 'a', 'target': 'b'},
        ],
      };

      controller.replaceGraph(graphData, const Size2D(800, 600));

      expect(controller.isInitialized, isTrue);
      expect(controller.positions.keys, containsAll(['a', 'b']));
      expect(controller.positions['a'], const Vector2(0, 0));
      expect(controller.positions['b'], const Vector2(0, 0));
    });

    test('step() advances engine and updates positions', () {
      final engine = _MockEngine();
      final controller = GraphController(engine: engine);

      final graphData = {
        'nodes': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'edges': [],
      };

      controller.replaceGraph(graphData, const Size2D(100, 100));

      controller.step();
      expect(engine.steps, 1);
      expect(controller.positions['a'], const Vector2(1, 0));
      expect(controller.positions['b'], const Vector2(1, 0));

      // Engine converged; further step() should not change positions
      controller.step();
      expect(engine.steps, 1);
      expect(controller.positions['a'], const Vector2(1, 0));
      expect(controller.positions['b'], const Vector2(1, 0));
    });
  });
}
