import 'package:test/test.dart';
import 'package:uyava_protocol/validation.dart';

class _SampleEntry {
  const _SampleEntry(this.id, this.value);

  final String? id;
  final String value;
}

void main() {
  group('normalizeTags', () {
    test('returns shared empty result for null input', () {
      final result = normalizeTags(null);

      expect(result, same(UyavaTagNormalizationResult.empty));
      expect(result.hasValues, isFalse);
    });

    test('flags non-iterable input while signaling it was provided', () {
      final result = normalizeTags('tag');

      expect(result.values, isEmpty);
      expect(result.normalized, isEmpty);
      expect(result.hadInput, isTrue);
      expect(result.hasValues, isFalse);
    });

    test('trims, dedupes case-insensitively, and preserves order', () {
      final result = normalizeTags([
        'Tag',
        ' tag ',
        'Another',
        'TAG',
        '',
        'third',
        42,
        'Third',
      ]);

      expect(result.values, equals(['Tag', 'Another', 'third']));
      expect(result.normalized, equals(['tag', 'another', 'third']));
      expect(result.hadInput, isTrue);
      expect(result.hasValues, isTrue);
    });
  });

  group('normalizeColor', () {
    test('treats null as no input without errors', () {
      final result = normalizeColor(null);

      expect(result.value, isNull);
      expect(result.hadInput, isFalse);
      expect(result.isValid, isTrue);
      expect(result.shouldReportInvalid, isFalse);
    });

    test('uppercases valid hex color values', () {
      final result = normalizeColor('  #ff12ab  ');

      expect(result.value, equals('#FF12AB'));
      expect(result.isValid, isTrue);
      expect(result.hadInput, isTrue);
      expect(result.shouldReportInvalid, isFalse);
    });

    test('rejects invalid color payloads', () {
      final invalidString = normalizeColor('#123');
      final invalidType = normalizeColor(123);

      expect(invalidString.value, isNull);
      expect(invalidString.isValid, isFalse);
      expect(invalidString.shouldReportInvalid, isTrue);

      expect(invalidType.value, isNull);
      expect(invalidType.isValid, isFalse);
      expect(invalidType.hadInput, isTrue);
    });
  });

  group('normalizeShape', () {
    test('accepts null without reporting an error', () {
      final result = normalizeShape(null);

      expect(result.value, isNull);
      expect(result.hadInput, isFalse);
      expect(result.isValid, isTrue);
      expect(result.shouldReportInvalid, isFalse);
    });

    test('lowercases valid identifiers', () {
      final result = normalizeShape('  Node_Main  ');

      expect(result.value, equals('node_main'));
      expect(result.isValid, isTrue);
      expect(result.shouldReportInvalid, isFalse);
    });

    test('rejects invalid characters', () {
      final result = normalizeShape('bad shape!');

      expect(result.value, isNull);
      expect(result.isValid, isFalse);
      expect(result.shouldReportInvalid, isTrue);
    });
  });

  group('dedupeById', () {
    test('applies last-writer-wins policy and tracks conflicts', () {
      final entries = <_SampleEntry>[
        const _SampleEntry('a', 'firstA'),
        const _SampleEntry('b', 'firstB'),
        const _SampleEntry(null, 'skipped'),
        const _SampleEntry('a', 'secondA'),
        const _SampleEntry('c', 'onlyC'),
        const _SampleEntry('b', 'secondB'),
        const _SampleEntry('', 'ignored'),
      ];

      final result = dedupeById<_SampleEntry>(entries, (entry) => entry.id);

      expect(result.hasDuplicates, isTrue);
      expect(result.latestById.keys, unorderedEquals(['a', 'b', 'c']));
      expect(result.latestById['a']!.value.value, equals('secondA'));
      expect(result.latestById['a']!.index, equals(3));
      expect(result.latestById['b']!.value.value, equals('secondB'));
      expect(result.latestById['b']!.index, equals(5));
      expect(result.latestById['c']!.value.value, equals('onlyC'));
      expect(result.latestById['c']!.index, equals(4));

      expect(result.duplicates.length, equals(2));
      expect(result.duplicates[0].id, equals('a'));
      expect(result.duplicates[0].previousIndex, equals(0));
      expect(result.duplicates[0].nextIndex, equals(3));
      expect(result.duplicates[1].id, equals('b'));
      expect(result.duplicates[1].previousIndex, equals(1));
      expect(result.duplicates[1].nextIndex, equals(5));
    });

    test('exposes unmodifiable collections', () {
      final result = dedupeById<_SampleEntry>(const <_SampleEntry>[
        _SampleEntry('a', 'value'),
      ], (entry) => entry.id);

      expect(
        () =>
            result.latestById['b'] = const UyavaDeduplicatedEntry<_SampleEntry>(
              value: _SampleEntry('b', 'v'),
              index: 1,
            ),
        throwsUnsupportedError,
      );

      expect(
        () => result.duplicates.add(
          const UyavaDuplicateRecord(id: 'x', previousIndex: 0, nextIndex: 1),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
