import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/src/dashboard/metric_card_view_model.dart';
import 'package:uyava_ui/src/dashboard/metrics_dashboard_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetricCardViewModel', () {
    test('build formats aggregates, sparkline, and tooltip metadata', () {
      const UyavaMetricDefinitionPayload definition =
          UyavaMetricDefinitionPayload(
            id: 'latency',
            label: 'Latency',
            description: 'Request latency',
            unit: 'ms',
            tags: <String>['Perf'],
            tagsNormalized: <String>['perf'],
            aggregators: <UyavaMetricAggregator>[
              UyavaMetricAggregator.last,
              UyavaMetricAggregator.min,
              UyavaMetricAggregator.max,
              UyavaMetricAggregator.sum,
              UyavaMetricAggregator.count,
            ],
          );

      final GraphMetricSnapshot firstSnapshot = GraphMetricSnapshot(
        definition: definition,
        aggregates: <UyavaMetricAggregator, num>{
          UyavaMetricAggregator.last: 8,
          UyavaMetricAggregator.min: 8,
          UyavaMetricAggregator.max: 8,
          UyavaMetricAggregator.sum: 8,
          UyavaMetricAggregator.count: 1,
        },
        severities: const <UyavaMetricAggregator, UyavaSeverity>{
          UyavaMetricAggregator.last: UyavaSeverity.info,
        },
        sampleCount: 1,
        lastTimestamp: DateTime.utc(2024, 1, 1, 12, 0, 0, 100),
      );

      final GraphMetricSnapshot snapshot = GraphMetricSnapshot(
        definition: definition,
        aggregates: <UyavaMetricAggregator, num>{
          UyavaMetricAggregator.last: 12.345,
          UyavaMetricAggregator.min: 8,
          UyavaMetricAggregator.max: 20,
          UyavaMetricAggregator.sum: 42,
          UyavaMetricAggregator.count: 3,
        },
        severities: const <UyavaMetricAggregator, UyavaSeverity>{
          UyavaMetricAggregator.last: UyavaSeverity.warn,
          UyavaMetricAggregator.min: UyavaSeverity.info,
          UyavaMetricAggregator.max: UyavaSeverity.error,
        },
        sampleCount: 3,
        lastTimestamp: DateTime.utc(2024, 1, 1, 12, 0, 1, 250),
      );

      final MetricHistorySeries series = MetricHistorySeries();
      series.update(
        firstSnapshot,
        maxPoints: 10,
        retention: null,
        now: firstSnapshot.lastTimestamp!,
      );
      series.update(
        snapshot,
        maxPoints: 10,
        retention: null,
        now: snapshot.lastTimestamp!,
      );

      final MetricCardState state = const MetricCardViewModel().build(
        MetricCardViewData(snapshot: snapshot, series: series, pinned: true),
      );

      expect(state.title, 'Latency');
      expect(state.pinned, isTrue);
      expect(state.samplesLabel, 'Samples: 3');
      expect(state.hasSparkline, isTrue);
      expect(state.sparklineValues, equals(<double>[8, 12.345]));
      expect(state.sparklinePlaceholder, 'Not enough samples for trend');
      expect(state.canReset, isTrue);
      expect(
        state.timestampLabel,
        matches(RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3}$')),
      );
      expect(
        state.infoTooltip.split('\n'),
        containsAll(<String>[
          'Metric id: latency',
          'Request latency',
          'Unit: ms',
          'Tags: perf',
        ]),
      );

      MetricAggregateState aggregateFor(String label) {
        return state.aggregates.firstWhere(
          (MetricAggregateState aggregate) => aggregate.label == label,
        );
      }

      final MetricAggregateState lastAggregate = aggregateFor('Last');
      expect(lastAggregate.valueText, '12.35 ms');
      expect(lastAggregate.severity, UyavaSeverity.warn);
      expect(lastAggregate.tintable, isTrue);

      final MetricAggregateState minAggregate = aggregateFor('Min');
      expect(minAggregate.valueText, '8 ms');
      expect(minAggregate.severity, UyavaSeverity.info);

      final MetricAggregateState maxAggregate = aggregateFor('Max');
      expect(maxAggregate.valueText, '20 ms');
      expect(maxAggregate.severity, UyavaSeverity.error);

      final MetricAggregateState sumAggregate = aggregateFor('Sum');
      expect(sumAggregate.valueText, '42 ms');
      expect(sumAggregate.severity, isNull);
      expect(sumAggregate.tintable, isFalse);

      final MetricAggregateState countAggregate = aggregateFor('Count');
      expect(countAggregate.valueText, '3');
      expect(countAggregate.severity, isNull);
      expect(countAggregate.tintable, isFalse);

      final MetricAggregateState avgAggregate = aggregateFor('Avg');
      expect(avgAggregate.valueText, '14 ms');
      expect(avgAggregate.tintable, isFalse);
      expect(avgAggregate.severity, isNull);
    });

    test('build handles empty series and missing labels', () {
      const UyavaMetricDefinitionPayload definition =
          UyavaMetricDefinitionPayload(
            id: 'throughput',
            label: '',
            aggregators: <UyavaMetricAggregator>[UyavaMetricAggregator.last],
          );

      final GraphMetricSnapshot snapshot = GraphMetricSnapshot(
        definition: definition,
        aggregates: const <UyavaMetricAggregator, num>{},
        severities: const <UyavaMetricAggregator, UyavaSeverity>{},
        sampleCount: 0,
        lastTimestamp: null,
      );

      final MetricCardState state = const MetricCardViewModel().build(
        MetricCardViewData(
          snapshot: snapshot,
          series: MetricHistorySeries(),
          pinned: false,
        ),
      );

      expect(state.title, 'throughput');
      expect(state.sparklineValues, isEmpty);
      expect(state.hasSparkline, isFalse);
      expect(state.sparklinePlaceholder, 'No samples yet');
      expect(state.timestampLabel, isNull);
      expect(state.canReset, isFalse);
      expect(
        state.aggregates
            .singleWhere(
              (MetricAggregateState aggregate) => aggregate.label == 'Last',
            )
            .valueText,
        '—',
      );
      expect(state.infoTooltip.trim(), 'Metric id: throughput');
    });
  });
}
