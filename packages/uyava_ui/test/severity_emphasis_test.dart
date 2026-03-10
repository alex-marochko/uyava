import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/src/theme.dart';

void main() {
  group('Severity comparison', () {
    test('severityRank ordering', () {
      expect(
        severityRank(UyavaSeverity.trace) < severityRank(UyavaSeverity.debug),
        isTrue,
      );
      expect(
        severityRank(UyavaSeverity.debug) < severityRank(UyavaSeverity.info),
        isTrue,
      );
      expect(
        severityRank(UyavaSeverity.info) < severityRank(UyavaSeverity.warn),
        isTrue,
      );
      expect(
        severityRank(UyavaSeverity.warn) < severityRank(UyavaSeverity.error),
        isTrue,
      );
      expect(
        severityRank(UyavaSeverity.error) < severityRank(UyavaSeverity.fatal),
        isTrue,
      );
    });

    test('severityMeets threshold', () {
      expect(severityMeets(UyavaSeverity.warn, UyavaSeverity.warn), isTrue);
      expect(severityMeets(UyavaSeverity.error, UyavaSeverity.warn), isTrue);
      expect(severityMeets(UyavaSeverity.fatal, UyavaSeverity.warn), isTrue);
      expect(severityMeets(UyavaSeverity.info, UyavaSeverity.warn), isFalse);
      // Null maps to info by default, so should fail warn threshold.
      expect(severityMeets(null, UyavaSeverity.warn), isFalse);
      expect(severityMeets(UyavaSeverity.fatal, UyavaSeverity.fatal), isTrue);
      expect(severityMeets(UyavaSeverity.error, UyavaSeverity.fatal), isFalse);
    });
  });
}
