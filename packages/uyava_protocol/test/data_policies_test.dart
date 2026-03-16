import 'package:test/test.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('UyavaDataPolicies', () {
    test('catalogMatches returns canonical, deduplicated values', () {
      final matches = UyavaDataPolicies.catalogMatches(const [
        ' UI ',
        'Auth',
        'legacy',
        'auth',
        'unknown',
      ]);

      expect(matches, ['ui', 'auth', 'legacy']);
    });

    test('priorityColorIndex resolves palette membership', () {
      final index = UyavaDataPolicies.priorityColorIndex('#ff7b72');
      final missing = UyavaDataPolicies.priorityColorIndex('#123456');

      expect(index, 4);
      expect(missing, isNull);
    });

    test('priorityColorPalette values are normalized uppercase hex', () {
      final RegExp matcher = RegExp(r'^#[0-9A-F]{6}(?:[0-9A-F]{2})?');

      for (final color in UyavaDataPolicies.priorityColorPalette) {
        expect(matcher.hasMatch(color), isTrue, reason: 'color: $color');
      }
    });
  });
}
