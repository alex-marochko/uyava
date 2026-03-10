import 'dart:async';

import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('GraphController metrics', () {
    late GraphController controller;
    late StreamSubscription<List<GraphMetricSnapshot>> subscription;
    final List<List<GraphMetricSnapshot>> emissions =
        <List<GraphMetricSnapshot>>[];

    setUp(() {
      controller = GraphController();
      subscription = controller.metricsStream.listen(emissions.add);
      emissions.clear();
    });

    tearDown(() async {
      await subscription.cancel();
      controller.dispose();
    });

    test('registerMetricDefinition stores snapshot and emits update', () async {
      final result = controller.registerMetricDefinition(<String, dynamic>{
        'id': 'fps',
        'label': 'Frames',
        'aggregators': <String>['last', 'max'],
      });

      expect(result.updated, isTrue);
      expect(controller.metrics, hasLength(1));
      final snapshot = controller.metricFor('fps');
      expect(snapshot, isNotNull);
      expect(snapshot!.definition.label, 'Frames');

      // Drain microtask queue so stream listeners capture the emission.
      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);
      expect(emissions.last.single.id, 'fps');
    });

    test('recordMetricSample updates aggregates', () {
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'cpu',
        'aggregators': <String>['last', 'sum', 'count'],
      });

      final sampleResult = controller.recordMetricSample(<String, dynamic>{
        'id': 'cpu',
        'value': 12.5,
        'timestamp': '2024-01-01T12:00:00Z',
        'severity': 'warn',
      });

      expect(sampleResult.applied, isTrue);
      final snapshot = controller.metricFor('cpu');
      expect(snapshot, isNotNull);
      expect(snapshot!.aggregates[UyavaMetricAggregator.last], 12.5);
      expect(snapshot.aggregates[UyavaMetricAggregator.sum], 12.5);
      expect(snapshot.aggregates[UyavaMetricAggregator.count], 1);
      expect(snapshot.sampleCount, 1);
      expect(
        snapshot.lastTimestamp?.toIso8601String(),
        '2024-01-01T12:00:00.000Z',
      );
      expect(
        snapshot.severityFor(UyavaMetricAggregator.last),
        UyavaSeverity.warn,
      );
      expect(snapshot.severityFor(UyavaMetricAggregator.sum), isNull);
      expect(snapshot.severityFor(UyavaMetricAggregator.count), isNull);
    });

    test(
      'recordMetricSample uses explicit severity override when provided',
      () {
        controller.registerMetricDefinition(<String, dynamic>{
          'id': 'latency',
          'aggregators': <String>['last'],
        });

        controller.recordMetricSample(<String, dynamic>{
          'id': 'latency',
          'value': 99,
          'timestamp': '2024-01-01T12:00:00Z',
          'severity': 'trace',
        }, severity: UyavaSeverity.error);

        final snapshot = controller.metricFor('latency');
        expect(snapshot, isNotNull);
        expect(
          snapshot!.severityFor(UyavaMetricAggregator.last),
          UyavaSeverity.error,
        );
      },
    );

    test('recordMetricSample emits diagnostic for unknown metric id', () async {
      controller.recordMetricSample(<String, dynamic>{
        'id': 'missing',
        'value': 5,
      });

      await Future<void>.delayed(Duration.zero);
      expect(controller.diagnostics.records, isNotEmpty);
      final last = controller.diagnostics.records.last;
      expect(last.code, 'metrics.unknown_id');
      expect(last.context?['metricId'], 'missing');
    });

    test(
      'resetMetricAggregates clears aggregates and emits snapshot',
      () async {
        controller.registerMetricDefinition(<String, dynamic>{
          'id': 'cpu',
          'aggregators': <String>['last', 'sum', 'count'],
        });
        controller.recordMetricSample(<String, dynamic>{
          'id': 'cpu',
          'value': 42,
          'timestamp': '2024-01-01T12:00:00Z',
          'severity': 'warn',
        });
        await Future<void>.delayed(Duration.zero);
        emissions.clear();

        final bool reset = controller.resetMetricAggregates('cpu');
        expect(reset, isTrue);
        await Future<void>.delayed(Duration.zero);

        final snapshot = controller.metricFor('cpu');
        expect(snapshot, isNotNull);
        expect(snapshot!.sampleCount, 0);
        expect(snapshot.aggregates[UyavaMetricAggregator.sum], 0);
        expect(snapshot.aggregates[UyavaMetricAggregator.count], 0);
        expect(snapshot.aggregates[UyavaMetricAggregator.last], isNull);
        expect(snapshot.lastTimestamp, isNull);
        expect(snapshot.severityFor(UyavaMetricAggregator.last), isNull);
        expect(emissions, isNotEmpty);
        expect(emissions.last.single.id, 'cpu');
        expect(emissions.last.single.sampleCount, 0);
      },
    );

    test('resetAllMetricAggregates refreshes every metric snapshot', () async {
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'cpu',
        'aggregators': <String>['last', 'sum'],
      });
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'mem',
        'aggregators': <String>['last'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'cpu',
        'value': 12,
        'severity': 'error',
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'mem',
        'value': 256,
      });
      await Future<void>.delayed(Duration.zero);
      emissions.clear();

      controller.resetAllMetricAggregates();
      await Future<void>.delayed(Duration.zero);

      final cpu = controller.metricFor('cpu')!;
      final mem = controller.metricFor('mem')!;
      expect(cpu.sampleCount, 0);
      expect(mem.sampleCount, 0);
      expect(cpu.aggregates[UyavaMetricAggregator.sum], 0);
      expect(cpu.severityFor(UyavaMetricAggregator.last), isNull);
      expect(mem.severityFor(UyavaMetricAggregator.last), isNull);
      expect(emissions, isNotEmpty);
      final ids = emissions.last.map((snapshot) => snapshot.id).toList();
      expect(ids, containsAll(<String>['cpu', 'mem']));
      expect(
        emissions.last.every((snapshot) => snapshot.sampleCount == 0),
        isTrue,
      );
    });

    test('clearMetricDefinitions removes all metric snapshots', () async {
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'cpu',
        'aggregators': <String>['last'],
      });
      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'mem',
        'aggregators': <String>['last'],
      });
      await Future<void>.delayed(Duration.zero);
      emissions.clear();

      controller.clearMetricDefinitions();
      await Future<void>.delayed(Duration.zero);

      expect(controller.metrics, isEmpty);
      expect(controller.metricFor('cpu'), isNull);
      expect(controller.metricFor('mem'), isNull);
      expect(emissions, isNotEmpty);
      expect(emissions.last, isEmpty);
    });
  });
}
