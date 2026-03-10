import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/src/theme.dart';

void main() {
  group('colorForSeverity', () {
    test('returns info-style blue for null', () {
      expect(colorForSeverity(null), equals(Colors.blue));
    });

    test('returns mapped colors for known severities', () {
      expect(colorForSeverity(UyavaSeverity.trace), equals(Colors.grey));
      expect(colorForSeverity(UyavaSeverity.debug), equals(Colors.blueGrey));
      expect(colorForSeverity(UyavaSeverity.info), equals(Colors.blue));
      expect(colorForSeverity(UyavaSeverity.warn), equals(Colors.amber));
      expect(colorForSeverity(UyavaSeverity.error), equals(Colors.redAccent));
      expect(colorForSeverity(UyavaSeverity.fatal), equals(Colors.red));
    });
  });
}
