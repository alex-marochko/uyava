import 'package:test/test.dart';
// Internal imports to test ForceDirectedLayout behavior directly.
import 'package:uyava_core/src/layout/layout.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('ForceDirectedLayout - forces and stability', () {
    test(
      'inter-group repulsion does not amplify ancestor-descendant pairs',
      () {
        final nodes = [
          UyavaNode(rawData: {'id': 'root'}),
          UyavaNode(rawData: {'id': 'child', 'parentId': 'root'}),
        ];

        final baseline = ForceDirectedLayout(
          config: const LayoutConfig(
            padding: 10,
            velocityDecay: 1.0,
            manyBodyStrength: -120.0,
            linkStrength: 0.0,
            gravityLinkStrength: 0.0,
            collisionRadius: 1.0,
            interGroupRepulsionFactor: 1.0,
            enableGroupAnchors: false,
          ),
        );
        final boosted = ForceDirectedLayout(
          config: const LayoutConfig(
            padding: 10,
            velocityDecay: 1.0,
            manyBodyStrength: -120.0,
            linkStrength: 0.0,
            gravityLinkStrength: 0.0,
            collisionRadius: 1.0,
            interGroupRepulsionFactor: 6.0,
            enableGroupAnchors: false,
          ),
        );

        const size = Size2D(1000, 800);
        baseline.initialize(nodes: nodes, edges: const [], size: size);
        boosted.initialize(nodes: nodes, edges: const [], size: size);

        baseline.step();
        boosted.step();

        final baselineDistance =
            (baseline.positions['root']! - baseline.positions['child']!)
                .distance;
        final boostedDistance =
            (boosted.positions['root']! - boosted.positions['child']!).distance;

        expect(boostedDistance, closeTo(baselineDistance, 1e-6));
      },
    );

    test(
      'inter-group repulsion uses immediate parent groups under same root',
      () {
        final nodes = [
          UyavaNode(rawData: {'id': 'root'}),
          UyavaNode(rawData: {'id': 'p1', 'parentId': 'root'}),
          UyavaNode(rawData: {'id': 'p2', 'parentId': 'root'}),
          UyavaNode(rawData: {'id': 'a', 'parentId': 'p1'}),
          UyavaNode(rawData: {'id': 'b', 'parentId': 'p2'}),
        ];

        final baseline = ForceDirectedLayout(
          config: const LayoutConfig(
            padding: 10,
            velocityDecay: 1.0,
            manyBodyStrength: -80.0,
            linkStrength: 0.0,
            gravityLinkStrength: 0.0,
            collisionRadius: 1.0,
            interGroupRepulsionFactor: 1.0,
            enableGroupAnchors: false,
          ),
        );

        final boosted = ForceDirectedLayout(
          config: const LayoutConfig(
            padding: 10,
            velocityDecay: 1.0,
            manyBodyStrength: -80.0,
            linkStrength: 0.0,
            gravityLinkStrength: 0.0,
            collisionRadius: 1.0,
            interGroupRepulsionFactor: 4.0,
            enableGroupAnchors: false,
          ),
        );

        const size = Size2D(2000, 1400);
        baseline.initialize(nodes: nodes, edges: const [], size: size);
        boosted.initialize(nodes: nodes, edges: const [], size: size);

        for (var i = 0; i < 6; i++) {
          baseline.step();
          boosted.step();
        }

        final baselineDistance =
            (baseline.positions['a']! - baseline.positions['b']!).distance;
        final boostedDistance =
            (boosted.positions['a']! - boosted.positions['b']!).distance;

        expect(boostedDistance, greaterThan(baselineDistance));
      },
    );

    test('subtree separation pushes sibling branches apart on each level', () {
      final nodes = [
        UyavaNode(rawData: {'id': 'root'}),
        UyavaNode(rawData: {'id': 'a', 'parentId': 'root'}),
        UyavaNode(rawData: {'id': 'b', 'parentId': 'root'}),
        UyavaNode(rawData: {'id': 'aa', 'parentId': 'a'}),
        UyavaNode(rawData: {'id': 'ab', 'parentId': 'a'}),
        UyavaNode(rawData: {'id': 'ba', 'parentId': 'b'}),
        UyavaNode(rawData: {'id': 'bb', 'parentId': 'b'}),
      ];
      final seeds = {
        for (final id in ['root', 'a', 'b', 'aa', 'ab', 'ba', 'bb'])
          id: const Vector2(500, 500),
      };

      final baseline = ForceDirectedLayout(
        config: const LayoutConfig(
          padding: 10,
          velocityDecay: 1.0,
          manyBodyStrength: 0.0,
          linkStrength: 0.0,
          gravityLinkStrength: 0.0,
          collisionRadius: 0.0,
          enableGroupAnchors: false,
          subtreeSeparationStrength: 0.0,
        ),
      );
      final separated = ForceDirectedLayout(
        config: const LayoutConfig(
          padding: 10,
          velocityDecay: 1.0,
          manyBodyStrength: 0.0,
          linkStrength: 0.0,
          gravityLinkStrength: 0.0,
          collisionRadius: 0.0,
          enableGroupAnchors: false,
          subtreeSeparationStrength: 0.8,
          subtreeSeparationScale: 1.0,
          subtreeSeparationGap: 32.0,
        ),
      );

      const size = Size2D(1000, 1000);
      baseline.initialize(
        nodes: nodes,
        edges: const [],
        size: size,
        initialPositions: seeds,
      );
      separated.initialize(
        nodes: nodes,
        edges: const [],
        size: size,
        initialPositions: seeds,
      );

      baseline.step();
      separated.step();

      final baselineTop =
          (baseline.positions['a']! - baseline.positions['b']!).distance;
      final separatedTop =
          (separated.positions['a']! - separated.positions['b']!).distance;
      final baselineNested =
          (baseline.positions['aa']! - baseline.positions['ab']!).distance;
      final separatedNested =
          (separated.positions['aa']! - separated.positions['ab']!).distance;

      expect(separatedTop, greaterThan(baselineTop + 1e-6));
      expect(separatedNested, greaterThan(baselineNested + 1e-6));
    });

    test('many-body repulsion increases pairwise distance', () {
      final engine = ForceDirectedLayout(
        config: const LayoutConfig(
          padding: 10,
          velocityDecay: 1.0,
          manyBodyStrength: -50.0,
          linkStrength: 0.0,
          gravityLinkStrength: 0.0,
          collisionRadius: 1.0,
        ),
      );

      final nodes = [
        UyavaNode(rawData: {'id': 'a'}),
        UyavaNode(rawData: {'id': 'b'}),
      ];
      engine.initialize(
        nodes: nodes,
        edges: const [],
        size: const Size2D(1000, 1000),
      );

      final p0 = engine.positions['a']!;
      final q0 = engine.positions['b']!;
      final initialDistance = (p0 - q0).distance;

      engine.step();

      final p1 = engine.positions['a']!;
      final q1 = engine.positions['b']!;
      final newDistance = (p1 - q1).distance;

      expect(newDistance, greaterThan(initialDistance));
      // Still bounded within viewport minus padding.
      expect(p1.dx, inInclusiveRange(10, 990));
      expect(p1.dy, inInclusiveRange(10, 990));
      expect(q1.dx, inInclusiveRange(10, 990));
      expect(q1.dy, inInclusiveRange(10, 990));
    });

    test('link force reduces distance towards target linkDistance', () {
      final targetDistance = 100.0;
      final engine = ForceDirectedLayout(
        config: LayoutConfig(
          padding: 10,
          velocityDecay: 1.0,
          manyBodyStrength: 0.0,
          linkDistance: targetDistance,
          linkStrength: 1.0,
          gravityLinkStrength: 0.0,
          collisionRadius: 1.0,
        ),
      );

      final nodes = [
        UyavaNode(rawData: {'id': 'a'}),
        UyavaNode(rawData: {'id': 'b'}),
      ];
      final edges = [
        UyavaEdge(data: {'id': 'e1', 'source': 'a', 'target': 'b'}),
      ];

      engine.initialize(
        nodes: nodes,
        edges: edges,
        size: const Size2D(1000, 1000),
      );

      final p0 = engine.positions['a']!;
      final q0 = engine.positions['b']!;
      final initialDistance = (p0 - q0).distance; // expected > targetDistance

      engine.step();

      final p1 = engine.positions['a']!;
      final q1 = engine.positions['b']!;
      final newDistance = (p1 - q1).distance;

      expect(initialDistance, greaterThan(targetDistance));
      expect(newDistance, lessThan(initialDistance));
    });

    test('collision separation enforces minimum distance', () {
      // Set collisionRadius high so the min distance dominates initial placement.
      const collisionRadius = 400.0; // min distance = 800
      final engine = ForceDirectedLayout(
        config: const LayoutConfig(
          padding: 50,
          velocityDecay: 1.0,
          manyBodyStrength: 0.0,
          linkStrength: 0.0,
          gravityLinkStrength: 0.0,
          collisionRadius: collisionRadius,
        ),
      );

      final nodes = [
        UyavaNode(rawData: {'id': 'a'}),
        UyavaNode(rawData: {'id': 'b'}),
      ];

      // Large viewport to avoid clamping interfering.
      engine.initialize(
        nodes: nodes,
        edges: const [],
        size: const Size2D(1000, 1000),
      );

      engine.step();

      final p1 = engine.positions['a']!;
      final q1 = engine.positions['b']!;
      final distance = (p1 - q1).distance;
      expect(distance, greaterThanOrEqualTo(collisionRadius * 2 - 1e-6));
    });

    test('centering aligns centroid with viewport center', () {
      final engine = ForceDirectedLayout(
        config: const LayoutConfig(
          padding: 10,
          velocityDecay: 1.0,
          manyBodyStrength: 0.0,
          linkStrength: 0.0,
          gravityLinkStrength: 0.0,
          collisionRadius: 1.0,
        ),
      );

      final nodes = [
        UyavaNode(rawData: {'id': 'a'}),
        UyavaNode(rawData: {'id': 'b'}),
        UyavaNode(rawData: {'id': 'c'}),
      ];

      const size = Size2D(800, 600);
      engine.initialize(nodes: nodes, edges: const [], size: size);

      engine.step();

      // Compute centroid of positions after a step.
      final positions = engine.positions;
      final cx =
          positions.values.map((v) => v.dx).reduce((a, b) => a + b) /
          positions.length;
      final cy =
          positions.values.map((v) => v.dy).reduce((a, b) => a + b) /
          positions.length;

      expect(cx, closeTo(size.width / 2, 1e-6));
      expect(cy, closeTo(size.height / 2, 1e-6));
    });
  });

  group('ForceDirectedLayout - alpha decay', () {
    test('alpha decays monotonically over steps', () {
      final engine = ForceDirectedLayout(
        config: const LayoutConfig(
          padding: 10,
          velocityDecay: 1.0,
          // Keep defaults for alphaDecay/alphaMin as behavior under test.
        ),
      );

      final nodes = [
        UyavaNode(rawData: {'id': 'a'}),
        UyavaNode(rawData: {'id': 'b'}),
      ];
      engine.initialize(
        nodes: nodes,
        edges: const [],
        size: const Size2D(500, 400),
      );

      final alphas = <double>[];
      // Capture alpha for several steps.
      for (var i = 0; i < 10; i++) {
        alphas.add(engine.alpha);
        engine.step();
      }

      for (var i = 0; i < alphas.length - 1; i++) {
        expect(alphas[i + 1], lessThan(alphas[i] + 1e-12));
      }
    });

    test('simulation reports convergence after sufficient steps', () {
      final engine = ForceDirectedLayout(
        config: const LayoutConfig(padding: 10),
      );
      final nodes = [
        UyavaNode(rawData: {'id': 'a'}),
        UyavaNode(rawData: {'id': 'b'}),
      ];

      engine.initialize(
        nodes: nodes,
        edges: const [],
        size: const Size2D(400, 300),
      );

      var safeguards = 0;
      while (!engine.isConverged && safeguards < 2000) {
        engine.step();
        safeguards++;
      }

      expect(engine.isConverged, isTrue);
      expect(engine.alpha, closeTo(engine.config.alphaMin, 1e-5));
    });
  });
}
