import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  group('EdgeAggregationPolicy', () {
    test('mapToVisibleAncestor maps to collapsed parent', () {
      final collapsed = {'p1'};
      final prog = <String, double>{'p1': 0.2};
      final parentById = <String, String?>{'c1': 'p1', 'p1': null};

      final policy = EdgeAggregationPolicy(
        collapsedParents: collapsed,
        collapseProgress: prog,
        parentById: parentById,
      );

      expect(policy.mapToVisibleAncestor('c1'), 'p1');
      expect(policy.mapToVisibleAncestor('p1'), 'p1');
    });

    test('mapToVisibleAncestor maps by progress threshold', () {
      final collapsed = <String>{};
      final prog = <String, double>{'p1': 1.0};
      final parentById = <String, String?>{'c1': 'p1', 'p1': null};

      final policy = EdgeAggregationPolicy(
        collapsedParents: collapsed,
        collapseProgress: prog,
        parentById: parentById,
      );

      expect(policy.mapToVisibleAncestor('c1'), 'p1');
    });

    test('remapAndAggregateEdges prefers direct edge', () {
      final collapsed = {'p1', 'p2'}; // ensure children map to parents
      final prog = <String, double>{};
      final parentById = <String, String?>{
        'c1': 'p1',
        'c2': 'p2',
        'p1': null,
        'p2': null,
      };

      final policy = EdgeAggregationPolicy(
        collapsedParents: collapsed,
        collapseProgress: prog,
        parentById: parentById,
      );

      final childEdge = UyavaEdge(
        data: {'id': 'e-child', 'source': 'c1', 'target': 'c2'},
      );
      final directEdge = UyavaEdge(
        data: {'id': 'e-direct', 'source': 'p1', 'target': 'p2'},
      );

      final result = policy.remapAndAggregateEdges([childEdge, directEdge]);
      expect(result.length, 1);
      expect(result.first.id, 'e-direct');
      expect(result.first.source, 'p1');
      expect(result.first.target, 'p2');
    });
  });
}
