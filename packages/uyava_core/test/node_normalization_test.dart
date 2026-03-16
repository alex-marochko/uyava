import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('UyavaNode canonicalization', () {
    test('normalizes and deduplicates tags while preserving order', () {
      final integrity = GraphIntegrity();
      final node = UyavaNode(
        rawData: {
          'id': 'foo',
          'label': ' Foo ',
          'tags': [' auth ', '', 'Auth', 'beta', 'Beta', 42],
        },
        integrity: integrity,
      );

      expect(node.label, 'Foo');
      expect(node.data['tags'], ['auth', 'beta']);
      expect(node.data['tagsNormalized'], ['auth', 'beta']);
      expect(node.data['tagsCatalog'], ['auth']);
      expect(integrity.hasIssues, isFalse);
    });

    test('uppercases valid hex colors and records invalid ones', () {
      final okIntegrity = GraphIntegrity();
      final okNode = UyavaNode(
        rawData: {'id': 'n1', 'color': '#ff00aa'},
        integrity: okIntegrity,
      );
      expect(okNode.data['color'], '#FF00AA');
      expect(okNode.data.containsKey('colorPriorityIndex'), isFalse);
      expect(okIntegrity.hasIssues, isFalse);
      expect(
        okIntegrity.issues,
        isEmpty,
        reason: 'unexpected issues: ${okIntegrity.issues}',
      );

      final badIntegrity = GraphIntegrity();
      final badNode = UyavaNode(
        rawData: {'id': 'n2', 'color': '#GGHHII'},
        integrity: badIntegrity,
      );
      expect(badNode.data.containsKey('color'), isFalse);
      expect(badNode.data.containsKey('colorPriorityIndex'), isFalse);
      expect(badIntegrity.hasIssues, isTrue);
      expect(
        badIntegrity.issues
            .singleWhere(
              (issue) =>
                  issue.code == UyavaGraphIntegrityCode.nodesInvalidColor,
            )
            .nodeId,
        'n2',
      );
    });

    test('captures priority color palette index when applicable', () {
      final integrity = GraphIntegrity();
      final node = UyavaNode(
        rawData: {'id': 'n3', 'color': '#FF7B72'},
        integrity: integrity,
      );

      expect(node.data['color'], '#FF7B72');
      expect(node.data['colorPriorityIndex'], 4);
      expect(integrity.hasIssues, isFalse);
    });

    test('normalizes shape identifiers and drops invalid ones', () {
      final okIntegrity = GraphIntegrity();
      final okNode = UyavaNode(
        rawData: {'id': 'n1', 'shape': 'Hexagon'},
        integrity: okIntegrity,
      );
      expect(okNode.data['shape'], 'hexagon');
      expect(okIntegrity.hasIssues, isFalse);

      final badIntegrity = GraphIntegrity();
      final badNode = UyavaNode(
        rawData: {'id': 'n2', 'shape': 'weird shape'},
        integrity: badIntegrity,
      );
      expect(badNode.data.containsKey('shape'), isFalse);
      expect(
        badIntegrity.issues
            .singleWhere(
              (issue) =>
                  issue.code == UyavaGraphIntegrityCode.nodesInvalidShape,
            )
            .nodeId,
        'n2',
      );
    });
  });

  group('GraphController integrity tracking', () {
    test('records conflicts when newer payload overrides color/tags', () {
      final controller = GraphController();
      controller.replaceGraph({
        'nodes': [
          {
            'id': 'foo',
            'color': '#112233',
            'tags': ['alpha'],
          },
        ],
        'edges': const [],
      }, const Size2D(100, 100));
      expect(controller.integrity.hasIssues, isFalse);

      controller.replaceGraph({
        'nodes': [
          {
            'id': 'foo',
            'color': '#445566',
            'tags': ['alpha', 'beta'],
          },
        ],
        'edges': const [],
      }, const Size2D(100, 100));

      expect(controller.nodes.single.data['color'], '#445566');
      expect(controller.integrity.hasIssues, isTrue);
      final codes = controller.integrity.issues
          .map((issue) => issue.code)
          .toSet();
      expect(
        codes.contains(UyavaGraphIntegrityCode.nodesConflictingColor),
        isTrue,
      );
      expect(
        codes.contains(UyavaGraphIntegrityCode.nodesConflictingTags),
        isTrue,
      );
    });
  });
}
