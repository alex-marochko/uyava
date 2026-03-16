import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  group('Parent pulse routing when groups are collapsed', () {
    test(
      'child-to-child intra-group event triggers parent pulse when collapsed',
      () {
        final parentById = <String, String?>{'c1': 'p', 'c2': 'p', 'p': null};
        final collapsedParents = {'p'};
        final collapseProgress = <String, double>{'p': 1.0};

        final policy = EdgeAggregationPolicy(
          collapsedParents: collapsedParents,
          collapseProgress: collapseProgress,
          parentById: parentById,
        );

        // Both children map to the same visible ancestor (parent 'p').
        expect(policy.mapToVisibleAncestor('c1'), equals('p'));
        expect(policy.mapToVisibleAncestor('c2'), equals('p'));

        // The helper should deem this an intra-collapsed-group event.
        expect(policy.isIntraCollapsedGroupEvent('c1', 'c2'), isTrue);
      },
    );

    test('no parent pulse when group is expanded', () {
      final parentById = <String, String?>{'c1': 'p', 'c2': 'p', 'p': null};
      final collapsedParents = <String>{};
      final collapseProgress = <String, double>{'p': 0.0};

      final policy = EdgeAggregationPolicy(
        collapsedParents: collapsedParents,
        collapseProgress: collapseProgress,
        parentById: parentById,
      );

      // When expanded, visible ancestor is each child itself.
      expect(policy.mapToVisibleAncestor('c1'), equals('c1'));
      expect(policy.mapToVisibleAncestor('c2'), equals('c2'));
      expect(policy.isIntraCollapsedGroupEvent('c1', 'c2'), isFalse);
    });

    test('inter-group traffic does not count as intra-group pulse', () {
      final parentById = <String, String?>{
        'a1': 'pA',
        'b1': 'pB',
        'pA': null,
        'pB': null,
      };
      final collapsedParents = {'pA', 'pB'};
      final collapseProgress = <String, double>{'pA': 1.0, 'pB': 1.0};

      final policy = EdgeAggregationPolicy(
        collapsedParents: collapsedParents,
        collapseProgress: collapseProgress,
        parentById: parentById,
      );

      // Visible endpoints differ => inter-group, no parent pulse.
      expect(policy.mapToVisibleAncestor('a1'), equals('pA'));
      expect(policy.mapToVisibleAncestor('b1'), equals('pB'));
      expect(policy.isIntraCollapsedGroupEvent('a1', 'b1'), isFalse);
    });

    test('self-edge on a child is not treated as intra-group', () {
      final parentById = <String, String?>{'c1': 'p', 'p': null};
      // Parent is collapsed but event is a self-edge on child; guard should skip.
      final collapsedParents = {'p'};
      final collapseProgress = <String, double>{'p': 1.0};

      final policy = EdgeAggregationPolicy(
        collapsedParents: collapsedParents,
        collapseProgress: collapseProgress,
        parentById: parentById,
      );

      expect(policy.mapToVisibleAncestor('c1'), equals('p'));
      expect(policy.isIntraCollapsedGroupEvent('c1', 'c1'), isFalse);
    });
  });
}
