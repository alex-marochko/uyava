import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  test('repository covers every UyavaGraphIntegrityCode', () {
    final Set<UyavaGraphIntegrityCode> documented = diagnosticDocRepository
        .entries
        .map((entry) => entry.code)
        .toSet();
    for (final UyavaGraphIntegrityCode code in UyavaGraphIntegrityCode.values) {
      expect(
        documented.contains(code),
        isTrue,
        reason: 'Missing documentation for $code',
      );
    }
  });

  testWidgets('dialog surfaces built-in documentation', (tester) async {
    final GraphDiagnosticRecord record = GraphDiagnosticRecord(
      source: GraphDiagnosticSource.core,
      code: UyavaGraphIntegrityCode.nodesMissingId.toWireString(),
      level: UyavaGraphIntegrityCode.nodesMissingId.defaultLevel,
      subjects: const <String>['nodeA'],
      codeEnum: UyavaGraphIntegrityCode.nodesMissingId,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () =>
                  showDiagnosticDocsDialog(context: context, record: record),
              child: const Text('Open docs'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open docs'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Node is missing a stable id'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('dialog falls back for app-defined codes', (tester) async {
    final GraphDiagnosticRecord record = GraphDiagnosticRecord(
      source: GraphDiagnosticSource.app,
      code: 'custom.missing_docs',
      level: UyavaDiagnosticLevel.warning,
      subjects: const <String>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () =>
                  showDiagnosticDocsDialog(context: context, record: record),
              child: const Text('Open fallback'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open fallback'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Documentation in progress'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
}
