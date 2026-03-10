import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  group('Visible-ancestor badge aggregation', () {
    test(
      'aggregates child arrivals into a single visible pair when both parents collapsed',
      () {
        // Graph: pA->{a1,a2}, pB->{b1}; all children communicate to b1.
        final parentById = <String, String?>{
          'a1': 'pA',
          'a2': 'pA',
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

        String key(String from, String to) =>
            '${policy.mapToVisibleAncestor(from)}->${policy.mapToVisibleAncestor(to)}';

        // Two child events should map to the same visible key pA->pB.
        final k1 = key('a1', 'b1');
        final k2 = key('a2', 'b1');
        expect(k1, equals('pA->pB'));
        expect(k2, equals('pA->pB'));

        // Aggregated counts used for badges.
        final counts = <String, int>{};
        for (final k in [k1, k2]) {
          counts[k] = (counts[k] ?? 0) + 1;
        }
        expect(counts['pA->pB'], equals(2));
      },
    );

    test('mixed collapse state maps to partially collapsed visible pair', () {
      // Only pA collapsed, pB expanded.
      final parentById = <String, String?>{
        'a1': 'pA',
        'b1': 'pB',
        'pA': null,
        'pB': null,
      };
      final collapsedParents = {'pA'};
      final collapseProgress = <String, double>{'pA': 1.0, 'pB': 0.0};

      final policy = EdgeAggregationPolicy(
        collapsedParents: collapsedParents,
        collapseProgress: collapseProgress,
        parentById: parentById,
      );

      final visFrom = policy.mapToVisibleAncestor('a1');
      final visTo = policy.mapToVisibleAncestor('b1');
      expect(visFrom, equals('pA'));
      expect(visTo, equals('b1'));
    });

    test('thresholded badges would show only after aggregated count >= min', () {
      // This test simulates label decision (host logic) using queueLabelMinCountToShow
      // and aggregated visible keys computed via the policy.
      final parentById = <String, String?>{
        'a1': 'pA',
        'a2': 'pA',
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

      String visKey(String from, String to) =>
          '${policy.mapToVisibleAncestor(from)}->${policy.mapToVisibleAncestor(to)}';

      final arrivals = <String, int>{};
      void add(String f, String t) {
        final k = visKey(f, t);
        arrivals[k] = (arrivals[k] ?? 0) + 1;
      }

      // Emit two arrivals on child edges mapping to the same visible pair.
      add('a1', 'b1');
      add('a2', 'b1');

      final minToShow =
          const RenderConfig().queueLabelMinCountToShow; // defaults to 2
      final visibleLabels = {
        for (final e in arrivals.entries)
          if (e.value >= minToShow) e.key: e.value,
      };
      expect(visibleLabels, contains('pA->pB'));
      expect(visibleLabels['pA->pB'], equals(2));
    });
  });
}
