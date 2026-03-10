import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/src/journal/journal_diagnostics_list.dart';

void main() {
  testWidgets('shows formatted runtime context for diagnostics', (
    tester,
  ) async {
    final GraphDiagnosticRecord record = GraphDiagnosticRecord(
      source: GraphDiagnosticSource.app,
      code: 'logging.panic_tail_captured',
      level: UyavaDiagnosticLevel.warning,
      subjects: const <String>[],
      timestamp: DateTime.utc(2024, 1, 1),
      context: <String, Object?>{
        'message': 'panic tail',
        'stackTrace': 'sample-stack',
        'runtimeContext': <String, Object?>{'source': 'flutter', 'zoneId': 42},
      },
    );

    final ThemeData theme = ThemeData(colorSchemeSeed: Colors.indigo);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: GraphJournalDiagnosticsList(
            records: <GraphDiagnosticRecord>[record],
            scheme: theme.colorScheme,
            controller: ScrollController(),
            onUserScrollAway: () {},
            emptyMessage: 'No diagnostics',
          ),
        ),
      ),
    );

    expect(find.text('Runtime context'), findsOneWidget);
    expect(find.textContaining('"source": "flutter"'), findsOneWidget);
    expect(find.textContaining('"zoneId": 42'), findsOneWidget);
  });
}
