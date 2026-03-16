import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  group('computeGroupingLevels', () {
    test('returns mutable baseline levels for empty graph', () {
      final List<int> levels = computeGroupingLevels(const <UyavaNode>[]);
      expect(levels, equals(<int>[0]));

      levels.add(1);
      expect(levels, equals(<int>[0, 1]));
    });
  });
}
