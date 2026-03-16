import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('GridLayout', () {
    test('initializes deterministic positions and converges immediately', () {
      final engine = GridLayout(padding: 24.0, minCellSize: 48.0);

      final nodes = [
        UyavaNode(rawData: {'id': 'n1'}),
        UyavaNode(rawData: {'id': 'n2'}),
        UyavaNode(rawData: {'id': 'n3'}),
        UyavaNode(rawData: {'id': 'n4'}),
        UyavaNode(rawData: {'id': 'n5'}),
      ];

      engine.initialize(
        nodes: nodes,
        edges: const [],
        size: const Size2D(200, 200),
      );

      expect(engine.isConverged, isTrue);
      expect(engine.positions.length, nodes.length);

      // Positions are within the viewport (respecting padding margins)
      for (final p in engine.positions.values) {
        expect(p.dx, inInclusiveRange(24.0, 200.0 - 24.0));
        expect(p.dy, inInclusiveRange(24.0, 200.0 - 24.0));
      }

      // Static layout: step() does not change positions
      final before = Map.of(engine.positions);
      engine.step();
      final after = engine.positions;
      expect(after, equals(before));
    });
  });
}
