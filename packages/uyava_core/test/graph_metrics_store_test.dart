import 'package:test/test.dart';
import 'package:uyava_core/src/models/graph_metrics.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('GraphMetricsStore', () {
    test('registers new metric and returns snapshot', () {
      final store = GraphMetricsStore();
      final payload = UyavaMetricDefinitionPayload(
        id: 'fps',
        label: 'Frames',
        aggregators: const <UyavaMetricAggregator>[
          UyavaMetricAggregator.last,
          UyavaMetricAggregator.max,
        ],
      );

      final result = store.register(payload);

      expect(result.updated, isTrue);
      expect(result.diagnostics, isEmpty);
      final snapshot = result.snapshot!;
      expect(snapshot.id, 'fps');
      expect(snapshot.definition.label, 'Frames');
      expect(snapshot.aggregates, isEmpty);
      expect(snapshot.sampleCount, 0);
      expect(snapshot.lastTimestamp, isNull);
    });

    test('emits conflict diagnostic when aggregators change', () {
      final store = GraphMetricsStore();
      final payload = UyavaMetricDefinitionPayload(
        id: 'latency',
        aggregators: const <UyavaMetricAggregator>[UyavaMetricAggregator.last],
      );

      store.register(payload);

      final updated = store.register(
        payload.copyWith(
          aggregators: const <UyavaMetricAggregator>[
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.sum,
          ],
        ),
      );

      expect(updated.updated, isTrue);
      expect(updated.diagnostics, hasLength(1));
      expect(
        updated.diagnostics.first.code,
        UyavaGraphIntegrityCode.metricsConflictingDefinition,
      );
      final snapshot = updated.snapshot!;
      expect(snapshot.aggregates[UyavaMetricAggregator.sum], 0);
      expect(snapshot.sampleCount, 0);
    });

    test('applies samples and updates aggregates', () {
      final store = GraphMetricsStore();
      final definition = UyavaMetricDefinitionPayload(
        id: 'cpu',
        aggregators: const <UyavaMetricAggregator>[
          UyavaMetricAggregator.last,
          UyavaMetricAggregator.min,
          UyavaMetricAggregator.max,
          UyavaMetricAggregator.sum,
          UyavaMetricAggregator.count,
        ],
      );
      store.register(definition);

      final timestamp = DateTime.utc(2024, 01, 01, 12);
      final sampleResult = store.applySample(
        UyavaMetricSamplePayload(id: 'cpu', value: 42.0, timestamp: timestamp),
        timestamp: timestamp,
        severity: UyavaSeverity.info,
      );

      expect(sampleResult.applied, isTrue);
      expect(sampleResult.diagnostics, isEmpty);
      final snapshot = sampleResult.snapshot!;
      expect(snapshot.aggregates[UyavaMetricAggregator.last], 42.0);
      expect(snapshot.aggregates[UyavaMetricAggregator.min], 42.0);
      expect(snapshot.aggregates[UyavaMetricAggregator.max], 42.0);
      expect(snapshot.aggregates[UyavaMetricAggregator.sum], 42.0);
      expect(snapshot.aggregates[UyavaMetricAggregator.count], 1);
      expect(snapshot.sampleCount, 1);
      expect(snapshot.lastTimestamp, equals(timestamp));
      expect(
        snapshot.severityFor(UyavaMetricAggregator.last),
        UyavaSeverity.info,
      );
      expect(
        snapshot.severityFor(UyavaMetricAggregator.min),
        UyavaSeverity.info,
      );
      expect(
        snapshot.severityFor(UyavaMetricAggregator.max),
        UyavaSeverity.info,
      );
      expect(snapshot.severityFor(UyavaMetricAggregator.sum), isNull);
    });

    test('returns diagnostic when applying sample for unknown metric', () {
      final store = GraphMetricsStore();
      final sampleResult = store.applySample(
        const UyavaMetricSamplePayload(id: 'missing', value: 1),
        timestamp: DateTime.utc(2024, 01, 01),
        severity: UyavaSeverity.warn,
      );

      expect(sampleResult.applied, isFalse);
      expect(sampleResult.snapshot, isNull);
      expect(sampleResult.diagnostics, hasLength(1));
      expect(
        sampleResult.diagnostics.first.code,
        UyavaGraphIntegrityCode.metricsUnknownId,
      );
    });

    test('updates severity when new extrema reuse same value', () {
      final store = GraphMetricsStore();
      final definition = UyavaMetricDefinitionPayload(
        id: 'latency',
        aggregators: const <UyavaMetricAggregator>[
          UyavaMetricAggregator.last,
          UyavaMetricAggregator.max,
          UyavaMetricAggregator.min,
        ],
      );
      store.register(definition);

      final DateTime first = DateTime.utc(2024, 01, 01, 12, 0);
      store.applySample(
        UyavaMetricSamplePayload(id: 'latency', value: 100, timestamp: first),
        timestamp: first,
        severity: UyavaSeverity.info,
      );

      final DateTime second = first.add(const Duration(seconds: 5));
      final sampleResult = store.applySample(
        UyavaMetricSamplePayload(id: 'latency', value: 100, timestamp: second),
        timestamp: second,
        severity: UyavaSeverity.error,
      );

      expect(sampleResult.applied, isTrue);
      final snapshot = sampleResult.snapshot!;
      expect(
        snapshot.severityFor(UyavaMetricAggregator.max),
        UyavaSeverity.error,
      );
      expect(
        snapshot.severityFor(UyavaMetricAggregator.min),
        UyavaSeverity.error,
      );
      expect(
        snapshot.severityFor(UyavaMetricAggregator.last),
        UyavaSeverity.error,
      );
    });

    test('resetAll clears aggregates and sample counters', () {
      final store = GraphMetricsStore();
      final definitionA = UyavaMetricDefinitionPayload(
        id: 'cpu',
        aggregators: const <UyavaMetricAggregator>[
          UyavaMetricAggregator.last,
          UyavaMetricAggregator.sum,
        ],
      );
      final definitionB = UyavaMetricDefinitionPayload(
        id: 'latency',
        aggregators: const <UyavaMetricAggregator>[UyavaMetricAggregator.last],
      );
      store.register(definitionA);
      store.register(definitionB);

      final DateTime ts = DateTime.utc(2024, 01, 01, 12);
      store.applySample(
        UyavaMetricSamplePayload(id: 'cpu', value: 10, timestamp: ts),
        timestamp: ts,
        severity: UyavaSeverity.error,
      );
      store.applySample(
        UyavaMetricSamplePayload(id: 'latency', value: 42, timestamp: ts),
        timestamp: ts,
        severity: UyavaSeverity.warn,
      );

      final bool reset = store.resetAll();
      expect(reset, isTrue);

      final snapshots = store.allSnapshots();
      expect(snapshots, hasLength(2));
      for (final GraphMetricSnapshot snapshot in snapshots) {
        expect(snapshot.sampleCount, 0);
        expect(snapshot.lastTimestamp, isNull);
        expect(snapshot.severities, isEmpty);
        if (snapshot.aggregates.containsKey(UyavaMetricAggregator.sum)) {
          expect(snapshot.aggregates[UyavaMetricAggregator.sum], 0);
        }
      }
    });

    test('resetAll returns false when no metrics are registered', () {
      final store = GraphMetricsStore();
      expect(store.resetAll(), isFalse);
    });
  });
}
