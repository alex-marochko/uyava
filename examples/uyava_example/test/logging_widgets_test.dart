import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava/uyava.dart';

import 'package:uyava_example/src/logging_widgets.dart';
import 'support/logging_test_utils.dart';

void main() {
  group('ArchiveEventSection', () {
    testWidgets('shows guidance when stream unavailable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArchiveEventSection(
              loggingAvailable: true,
              streamAvailable: false,
              events: <UyavaLogArchiveEvent>[],
            ),
          ),
        ),
      );

      expect(
        find.text('Archive streaming is not available on this platform.'),
        findsOneWidget,
      );
    });

    testWidgets('renders archive rows when events arrive', (tester) async {
      final UyavaLogArchiveEvent event = buildArchiveEvent(
        archive: buildArchive(fileName: 'panic-tail.uyava', sizeBytes: 2048),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    ArchiveEventSection(
                      loggingAvailable: true,
                      streamAvailable: true,
                      events: <UyavaLogArchiveEvent>[event],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Rotation — file sealed'), findsOneWidget);
      expect(find.textContaining('panic-tail.uyava'), findsWidgets);
      expect(find.textContaining('2.0 KB'), findsOneWidget);
    });
  });

  group('ArchiveActionButtons', () {
    testWidgets('invokes callbacks when enabled', (tester) async {
      int cloneCalls = 0;
      int exportCalls = 0;

      Future<void> handleClone(BuildContext context) async {
        cloneCalls += 1;
      }

      Future<void> handleExport(BuildContext context) async {
        exportCalls += 1;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArchiveActionButtons(
              loggingAvailable: true,
              isCloning: false,
              isSending: false,
              onClone: handleClone,
              onExport: handleExport,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Clone active log'));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Send log via email'),
      );
      await tester.pump();

      expect(cloneCalls, 1);
      expect(exportCalls, 1);
    });

    testWidgets('disables buttons when logging unavailable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArchiveActionButtons(
              loggingAvailable: false,
              isCloning: false,
              isSending: false,
              onClone: (_) async {},
              onExport: (_) async {},
            ),
          ),
        ),
      );

      final Finder cloneButton = find.widgetWithText(
        ElevatedButton,
        'Clone active log',
      );
      final Finder exportButton = find.widgetWithText(
        ElevatedButton,
        'Send log via email',
      );

      expect(tester.widget<ElevatedButton>(cloneButton).onPressed, isNull);
      expect(tester.widget<ElevatedButton>(exportButton).onPressed, isNull);
    });
  });

  group('DiscardStatsSummary', () {
    testWidgets('shows disabled message when logging off', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscardStatsSummary(
              loggingAvailable: false,
              discardStats: null,
            ),
          ),
        ),
      );

      expect(
        find.text('File logging is disabled, so counters are unavailable.'),
        findsOneWidget,
      );
    });

    testWidgets('renders hint when stats not available yet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscardStatsSummary(
              loggingAvailable: true,
              discardStats: null,
            ),
          ),
        ),
      );

      expect(
        find.textContaining('No events have been dropped yet'),
        findsOneWidget,
      );
    });

    testWidgets('shows totals and reasons when stats exist', (tester) async {
      final UyavaDiscardStats stats = buildDiscardStats(
        total: 7,
        lastReason: 'max_rate',
        reasons: const {'max_rate': 5, 'realtime_sampling': 2},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscardStatsSummary(
              loggingAvailable: true,
              discardStats: stats,
            ),
          ),
        ),
      );

      expect(find.text('Total drops: 7'), findsOneWidget);
      expect(find.textContaining('Last reason: max_rate'), findsOneWidget);
      expect(find.textContaining('- max_rate: 5'), findsOneWidget);
      expect(find.textContaining('- realtime_sampling: 2'), findsOneWidget);
    });
  });
}
