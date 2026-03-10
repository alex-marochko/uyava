import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  group('UyavaMetricsDashboard', () {
    testWidgets('shows empty state when no metrics', (tester) async {
      final controller = GraphController();

      await tester.pumpWidget(
        MaterialApp(home: UyavaMetricsDashboard(controller: controller)),
      );

      expect(find.text('No metrics'), findsOneWidget);
    });

    testWidgets('renders metric aggregates after samples', (tester) async {
      final controller = GraphController();
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'latency',
        'label': 'Latency',
        'unit': 'ms',
        'aggregators': <String>['last', 'min', 'max', 'sum', 'count'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 12,
        'timestamp': '2024-01-01T00:00:01Z',
      });

      await tester.pumpWidget(
        MaterialApp(home: UyavaMetricsDashboard(controller: controller)),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('metric-card-latency')), findsOneWidget);
      expect(find.text('Last'), findsOneWidget);
      expect(find.text('Min'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);
      expect(find.text('Sum'), findsOneWidget);
      expect(find.text('Count'), findsOneWidget);
      expect(find.text('Avg'), findsOneWidget);
      expect(find.text('12 ms'), findsWidgets);
      expect(find.text('Samples: 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Reset history'));
      await tester.pumpAndSettle();

      expect(find.text('Samples: 0'), findsOneWidget);
      expect(find.text('Avg'), findsNothing);
      expect(find.text('0 ms'), findsWidgets);
    });

    testWidgets('renders sparkline once multiple samples arrive', (
      tester,
    ) async {
      final controller = GraphController();
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'throughput',
        'label': 'Throughput',
        'unit': 'req/s',
        'aggregators': <String>['last', 'sum', 'count'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'throughput',
        'value': 20,
        'timestamp': '2024-01-01T00:00:01Z',
      });

      await tester.pumpWidget(
        MaterialApp(home: UyavaMetricsDashboard(controller: controller)),
      );
      await tester.pump();

      expect(find.text('Not enough samples for trend'), findsOneWidget);
      expect(find.byKey(const ValueKey('sparkline-throughput')), findsNothing);

      controller.recordMetricSample(<String, dynamic>{
        'id': 'throughput',
        'value': 24,
        'timestamp': '2024-01-01T00:00:02Z',
      });

      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('sparkline-throughput')),
        findsOneWidget,
      );
    });

    testWidgets('omits sparkline while in compact mode', (tester) async {
      final controller = GraphController();
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'throughput',
        'label': 'Throughput',
        'unit': 'req/s',
        'aggregators': <String>['last', 'sum', 'count'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'throughput',
        'value': 20,
        'timestamp': '2024-01-01T00:00:01Z',
      });

      await tester.pumpWidget(
        MaterialApp(home: UyavaMetricsDashboard(controller: controller)),
      );
      await tester.pump();

      controller.recordMetricSample(<String, dynamic>{
        'id': 'throughput',
        'value': 24,
        'timestamp': '2024-01-01T00:00:02Z',
      });
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('sparkline-throughput')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Switch to compact view'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sparkline-throughput')), findsNothing);
    });

    testWidgets('global reset clears all metric aggregates', (tester) async {
      final controller = GraphController();
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'latency',
        'label': 'Latency',
        'unit': 'ms',
        'aggregators': <String>['last', 'sum', 'count'],
      });
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'throughput',
        'label': 'Throughput',
        'unit': 'req/s',
        'aggregators': <String>['last', 'sum', 'count'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 18,
        'timestamp': '2024-01-01T00:00:01Z',
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'throughput',
        'value': 42,
        'timestamp': '2024-01-01T00:00:02Z',
      });

      await tester.pumpWidget(
        MaterialApp(home: UyavaMetricsDashboard(controller: controller)),
      );
      await tester.pump();

      await tester.tap(find.text('Reset all'));
      await tester.pumpAndSettle();

      expect(find.text('Samples: 0'), findsNWidgets(2));
      expect(find.text('Avg'), findsNothing);
    });

    testWidgets('Pinned metrics stay at top and notify state changes', (
      tester,
    ) async {
      final controller = GraphController();
      addTearDown(controller.dispose);

      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'latency',
        'label': 'Latency',
        'aggregators': <String>['last'],
      });
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'throughput',
        'label': 'Throughput',
        'aggregators': <String>['last'],
      });

      Set<String> pinned = const <String>{};

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            child: UyavaMetricsDashboard(
              controller: controller,
              pinnedMetrics: const <String>{'throughput'},
              onPinnedMetricsChanged: (Set<String> pins) {
                pinned = pins;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final Offset throughputOffset = tester.getTopLeft(
        find.byKey(const ValueKey('metric-card-throughput')),
      );
      final Offset latencyOffset = tester.getTopLeft(
        find.byKey(const ValueKey('metric-card-latency')),
      );
      expect(throughputOffset.dy, lessThanOrEqualTo(latencyOffset.dy));

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('metric-card-throughput')),
          matching: find.byTooltip('Unpin metric'),
        ),
      );
      await tester.pumpAndSettle();
      expect(pinned.contains('throughput'), isFalse);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('metric-card-latency')),
          matching: find.byTooltip('Pin metric'),
        ),
      );
      await tester.pumpAndSettle();
      expect(pinned.contains('latency'), isTrue);
    });

    testWidgets('tints severity-aware aggregates', (tester) async {
      final controller = GraphController();
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'latency',
        'label': 'Latency',
        'unit': 'ms',
        'aggregators': <String>['last', 'max', 'sum', 'count'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 120,
        'timestamp': '2024-01-01T00:00:01Z',
        'severity': 'error',
      }, severity: UyavaSeverity.error);

      await tester.pumpWidget(
        MaterialApp(home: UyavaMetricsDashboard(controller: controller)),
      );
      await tester.pump();

      final BuildContext context = tester.element(
        find.byType(UyavaMetricsDashboard),
      );
      final ThemeData theme = Theme.of(context);

      Color chipColor(String label) {
        final Finder chipFinder = find
            .ancestor(of: find.text(label), matching: find.byType(Container))
            .first;
        final Container container = tester.widget<Container>(chipFinder);
        final BoxDecoration decoration = container.decoration! as BoxDecoration;
        return decoration.color!;
      }

      final Color lastColor = chipColor('Last');
      final Color maxColor = chipColor('Max');
      final Color expectedTint = Color.alphaBlend(
        colorForSeverity(UyavaSeverity.error).withValues(alpha: 0.3),
        theme.colorScheme.surfaceContainerHighest,
      );
      expect(lastColor, expectedTint);
      expect(maxColor, expectedTint);

      final Color sumColor = chipColor('Sum');
      final Color expectedNeutral = theme.colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.5);
      expect(sumColor, expectedNeutral);

      final Color countColor = chipColor('Count');
      expect(countColor, expectedNeutral);
    });

    testWidgets('switches between detailed and compact modes', (tester) async {
      final controller = GraphController();
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'latency',
        'label': 'Latency',
        'unit': 'ms',
        'aggregators': <String>['last', 'min', 'max', 'sum', 'count'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 48,
        'timestamp': '2024-01-01T00:00:01Z',
      });

      await tester.pumpWidget(
        MaterialApp(home: UyavaMetricsDashboard(controller: controller)),
      );
      await tester.pump();

      expect(find.text('Sum'), findsOneWidget);

      await tester.tap(find.byTooltip('Switch to compact view'));
      await tester.pumpAndSettle();

      expect(find.text('Sum'), findsNothing);
      expect(find.textContaining('Last:'), findsOneWidget);
      expect(find.textContaining('Min:'), findsOneWidget);
      expect(find.textContaining('Max:'), findsOneWidget);
      expect(find.textContaining('Sum:'), findsOneWidget);

      await tester.tap(find.byTooltip('Switch to detailed view'));
      await tester.pumpAndSettle();

      expect(find.text('Sum'), findsOneWidget);
    });

    testWidgets('notifies compact mode changes to parent', (tester) async {
      final controller = GraphController();
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'latency',
        'label': 'Latency',
        'unit': 'ms',
        'aggregators': <String>['last', 'min', 'max'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 12,
        'timestamp': '2024-01-01T00:00:02Z',
      });

      bool compact = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setHostState) {
            return MaterialApp(
              home: UyavaMetricsDashboard(
                controller: controller,
                compactMode: compact,
                onCompactModeChanged: (bool next) {
                  setHostState(() => compact = next);
                },
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(compact, isFalse);
      expect(find.text('Min'), findsOneWidget);

      await tester.tap(find.byTooltip('Switch to compact view'));
      await tester.pumpAndSettle();

      expect(compact, isTrue);
      expect(find.text('Min'), findsNothing);
      expect(find.textContaining('Min:'), findsOneWidget);
    });
  });
}
