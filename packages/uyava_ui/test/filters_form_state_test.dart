import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/src/filters/filters_form_state.dart';

void main() {
  group('FiltersFormState', () {
    test(
      'fromGraphFilterState respects fallback when not forcing defaults',
      () {
        const FiltersFormState base = FiltersFormState(
          pattern: 'auth',
          searchMode: UyavaFilterSearchMode.mask,
          caseSensitive: true,
          tagsMode: UyavaFilterTagsMode.exclude,
          tagsLogic: UyavaFilterTagLogic.all,
          selectableTagsLogic: UyavaFilterTagLogic.all,
          selectedTags: <String>['a'],
          nodeMode: FiltersNodeMode.exclude,
          selectedNodeIds: <String>['n'],
          severityOperator: UyavaFilterSeverityOperator.atMost,
          selectedSeverity: UyavaSeverity.warn,
        );

        const GraphFilterState state = GraphFilterState();

        final FiltersFormState result = FiltersFormState.fromGraphFilterState(
          state,
          fallback: base,
          forceDefaults: false,
        );

        expect(result.pattern, isEmpty);
        expect(result.searchMode, base.searchMode);
        expect(result.caseSensitive, base.caseSensitive);
        expect(result.tagsMode, base.tagsMode);
        expect(result.tagsLogic, base.tagsLogic);
        expect(result.nodeMode, base.nodeMode);
        expect(result.selectedNodeIds, isEmpty);
        expect(result.selectedTags, isEmpty);
        expect(result.severityOperator, base.severityOperator);
        expect(result.selectedSeverity, isNull);
      },
    );

    test('cycleTagsLogic is a no-op for exact mode', () {
      const FiltersFormState base = FiltersFormState(
        tagsMode: UyavaFilterTagsMode.exact,
        tagsLogic: UyavaFilterTagLogic.all,
      );

      final FiltersFormState next = base.cycleTagsLogic();
      expect(identical(base, next), isTrue);
    });

    test('toGraphFilterState builds expected GraphFilterState', () {
      const FiltersFormState state = FiltersFormState(
        pattern: 'auth',
        searchMode: UyavaFilterSearchMode.regex,
        caseSensitive: true,
        selectedTags: <String>['Foo', 'bar'],
        tagsMode: UyavaFilterTagsMode.include,
        tagsLogic: UyavaFilterTagLogic.all,
        nodeMode: FiltersNodeMode.exclude,
        selectedNodeIds: <String>['root'],
        severityOperator: UyavaFilterSeverityOperator.atLeast,
        selectedSeverity: UyavaSeverity.error,
      );

      final GraphFilterState result = state.toGraphFilterState();
      expect(result.search?.pattern, 'auth');
      expect(result.search?.mode, UyavaFilterSearchMode.regex);
      expect(result.search?.caseSensitive, isTrue);
      expect(result.tags?.values, equals(<String>['Foo', 'bar']));
      expect(result.tags?.logic, UyavaFilterTagLogic.all);
      expect(result.nodes?.exclude, equals(<String>['root']));
      expect(result.severity?.level, UyavaSeverity.error);
      expect(result.severity?.operator, UyavaFilterSeverityOperator.atLeast);
    });

    test('pruneSelections removes invalid entries and grouping depth', () {
      const FiltersFormState base = FiltersFormState(
        selectedNodeIds: <String>['one', 'two'],
        selectedTags: <String>['alpha', 'beta'],
        groupingMode: UyavaFilterGroupingMode.level,
        groupingDepth: 3,
      );

      final FiltersFormState pruned = base.pruneSelections(
        validNodeIds: <String>{'two'},
        validTags: <String>{'beta'},
        validGroupingDepths: <int>{1, 2},
      );

      expect(pruned.selectedNodeIds, equals(<String>['two']));
      expect(pruned.selectedTags, equals(<String>['beta']));
      expect(pruned.groupingMode, UyavaFilterGroupingMode.none);
      expect(pruned.groupingDepth, isNull);
    });

    test('pruneSelections keeps selections when valid sets empty', () {
      const FiltersFormState base = FiltersFormState(
        selectedNodeIds: <String>['one'],
        selectedTags: <String>['alpha'],
      );

      final FiltersFormState pruned = base.pruneSelections(
        validNodeIds: const <String>{},
        validTags: const <String>{},
      );

      expect(pruned.selectedNodeIds, equals(<String>['one']));
      expect(pruned.selectedTags, equals(<String>['alpha']));
    });
  });
}
