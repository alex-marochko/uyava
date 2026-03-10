import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

class _NoopEngine implements LayoutEngine {
  @override
  bool get isConverged => true;

  @override
  Map<String, Vector2> get positions => const {};

  @override
  void initialize({
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
    required Size2D size,
    Map<String, Vector2>? initialPositions,
  }) {}

  @override
  void step() {}
}

void main() {
  group('NodeLifecycle updates', () {
    test('defaults to unknown and updates to initialized', () {
      final controller = GraphController(engine: _NoopEngine());
      controller.replaceGraph({
        'nodes': [
          {'id': 'A', 'label': 'A'},
        ],
        'edges': [],
      }, const Size2D(100, 100));

      expect(controller.nodes.single.lifecycle, NodeLifecycle.unknown);
      controller.updateNodeLifecycle('A', NodeLifecycle.initialized);
      expect(controller.nodes.single.lifecycle, NodeLifecycle.initialized);
      expect(controller.nodes.single.data['lifecycle'], 'initialized');
    });

    test('allows disposed then re-initialized', () {
      final controller = GraphController(engine: _NoopEngine());
      controller.replaceGraph({
        'nodes': [
          {'id': 'N1', 'label': 'N1'},
        ],
        'edges': [],
      }, const Size2D(100, 100));

      controller.updateNodeLifecycle('N1', NodeLifecycle.disposed);
      expect(controller.nodes.single.lifecycle, NodeLifecycle.disposed);
      expect(controller.nodes.single.data['lifecycle'], 'disposed');
      controller.updateNodeLifecycle('N1', NodeLifecycle.initialized);
      expect(controller.nodes.single.lifecycle, NodeLifecycle.initialized);
      expect(controller.nodes.single.data['lifecycle'], 'initialized');
    });

    test('reads lifecycle from payload when provided', () {
      final controller = GraphController(engine: _NoopEngine());
      controller.replaceGraph({
        'nodes': [
          {'id': 'B', 'label': 'B', 'lifecycle': 'disposed'},
        ],
        'edges': [],
      }, const Size2D(100, 100));

      expect(controller.nodes.single.lifecycle, NodeLifecycle.disposed);
      expect(controller.nodes.single.data['lifecycle'], 'disposed');
    });

    test('invalid lifecycle payload falls back to unknown', () {
      final controller = GraphController(engine: _NoopEngine());
      controller.replaceGraph({
        'nodes': [
          {'id': 'C', 'label': 'C', 'lifecycle': 'bogus'},
        ],
        'edges': [],
      }, const Size2D(100, 100));

      expect(controller.nodes.single.lifecycle, NodeLifecycle.unknown);
      expect(controller.nodes.single.data['lifecycle'], 'unknown');
    });

    test('batch lifecycle update applies to all known nodes', () {
      final controller = GraphController(engine: _NoopEngine());
      controller.replaceGraph({
        'nodes': [
          {'id': 'N1', 'label': 'N1'},
          {'id': 'N2', 'label': 'N2'},
          {'id': 'N3', 'label': 'N3'},
        ],
        'edges': [],
      }, const Size2D(100, 100));

      controller.updateNodesListLifecycle([
        'N1',
        'N2',
        'missing',
        'N2',
      ], NodeLifecycle.disposed);

      expect(controller.nodes[0].lifecycle, NodeLifecycle.disposed);
      expect(controller.nodes[0].data['lifecycle'], 'disposed');
      expect(controller.nodes[1].lifecycle, NodeLifecycle.disposed);
      expect(controller.nodes[1].data['lifecycle'], 'disposed');
      expect(controller.nodes[2].lifecycle, NodeLifecycle.unknown);
    });

    test('filtered nodes reflect lifecycle changes immediately', () {
      final controller = GraphController(engine: _NoopEngine());
      controller.replaceGraph({
        'nodes': [
          {'id': 'A', 'label': 'A'},
        ],
        'edges': [],
      }, const Size2D(100, 100));

      expect(controller.filteredNodes.single.lifecycle, NodeLifecycle.unknown);
      controller.updateNodeLifecycle('A', NodeLifecycle.disposed);
      expect(controller.filteredNodes.single.lifecycle, NodeLifecycle.disposed);
      expect(controller.filteredNodes.single.data['lifecycle'], 'disposed');
    });
  });
}
