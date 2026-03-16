import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  const codec = GraphFilterStateCodec();

  test('encode returns null for empty state', () {
    expect(codec.encode(GraphFilterState.empty), isNull);
  });

  test('round-trips populated filter state', () {
    final state = GraphFilterState(
      search: GraphFilterSearch(
        mode: UyavaFilterSearchMode.substring,
        pattern: 'Service',
        caseSensitive: true,
      ),
      tags: GraphFilterTags(
        mode: UyavaFilterTagsMode.include,
        values: const ['Core', 'Backend'],
        valuesNormalized: const ['core', 'backend'],
        logic: UyavaFilterTagLogic.all,
      ),
      nodes: GraphFilterNodeSet(
        include: const ['serviceA'],
        exclude: const ['serviceZ'],
      ),
      parent: const GraphFilterParent(rootId: 'root', depth: 2),
      grouping: const GraphFilterGrouping(
        mode: UyavaFilterGroupingMode.level,
        levelDepth: 1,
      ),
      severity: const GraphFilterSeverity(
        operator: UyavaFilterSeverityOperator.atLeast,
        level: UyavaSeverity.warn,
      ),
    );

    final encoded = codec.encode(state);
    expect(encoded, isNotNull);

    final decoded = codec.decode(encoded);
    expect(decoded, equals(state));
  });

  test('decode gracefully handles non-map payload', () {
    expect(codec.decode('filters'), isNull);
  });

  test('decode restores severity-only payload', () {
    final decoded = codec.decode({
      'severity': {'operator': 'exact', 'level': 'error'},
    });
    expect(
      decoded,
      equals(
        const GraphFilterState(
          severity: GraphFilterSeverity(
            operator: UyavaFilterSeverityOperator.exact,
            level: UyavaSeverity.error,
          ),
        ),
      ),
    );
  });
}
