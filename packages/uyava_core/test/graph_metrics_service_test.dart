import 'dart:async';

import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('GraphMetricsService', () {
    late GraphDiagnosticsService diagnostics;
    late GraphMetricsService service;
    late List<List<GraphMetricSnapshot>> emissions;
    late StreamSubscription<List<GraphMetricSnapshot>> subscription;

    setUp(() {
      diagnostics = GraphDiagnosticsService();
      service = GraphMetricsService(diagnosticsService: diagnostics);
      emissions = <List<GraphMetricSnapshot>>[];
      subscription = service.stream.listen(emissions.add);
    });

    tearDown(() async {
      await subscription.cancel();
      service.dispose();
      diagnostics.dispose();
    });

    test('registerDefinition stores snapshot and emits', () async {
      final result = service.registerDefinition({
        'id': 'fps',
        'label': 'Frames',
        'aggregators': <String>['last', 'max'],
      });

      expect(result.updated, isTrue);
      expect(service.snapshots, hasLength(1));
      expect(service.snapshotFor('fps')?.definition.label, 'Frames');

      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);
      expect(emissions.last.single.id, 'fps');
    });

    test('recordSample aggregates values and respects fallback timestamp', () {
      service.registerDefinition({
        'id': 'latency',
        'aggregators': <String>['last', 'sum', 'count'],
      });

      final DateTime fallback = DateTime.utc(2024, 1, 1, 12);
      final result = service.recordSample(
        <String, Object?>{'id': 'latency', 'value': 12.5},
        fallbackTimestamp: fallback,
        severity: UyavaSeverity.error,
      );

      expect(result.applied, isTrue);
      final snapshot = service.snapshotFor('latency')!;
      expect(snapshot.aggregates[UyavaMetricAggregator.last], 12.5);
      expect(snapshot.aggregates[UyavaMetricAggregator.sum], 12.5);
      expect(snapshot.aggregates[UyavaMetricAggregator.count], 1);
      expect(snapshot.lastTimestamp, fallback.toUtc());
      expect(
        snapshot.severityFor(UyavaMetricAggregator.last),
        UyavaSeverity.error,
      );
    });

    test('recordSample emits diagnostic for unknown metric id', () async {
      service.recordSample(<String, Object?>{'id': 'missing', 'value': 5});
      await Future<void>.delayed(Duration.zero);

      expect(diagnostics.diagnostics.records, isNotEmpty);
      final GraphDiagnosticRecord last = diagnostics.diagnostics.records.last;
      expect(
        last.code,
        UyavaGraphIntegrityCode.metricsUnknownId.toWireString(),
      );
      expect(last.context?['metricId'], 'missing');
    });

    test('resetAggregates refreshes snapshots and emits', () async {
      service.registerDefinition({
        'id': 'cpu',
        'aggregators': <String>['last', 'sum'],
      });
      service.recordSample(<String, Object?>{'id': 'cpu', 'value': 42});
      await Future<void>.delayed(Duration.zero);
      emissions.clear();

      final bool reset = service.resetAggregates('cpu');
      expect(reset, isTrue);
      await Future<void>.delayed(Duration.zero);

      final snapshot = service.snapshotFor('cpu')!;
      expect(snapshot.sampleCount, 0);
      expect(snapshot.aggregates[UyavaMetricAggregator.last], isNull);
      expect(snapshot.aggregates[UyavaMetricAggregator.sum], 0);
      expect(emissions, isNotEmpty);
      expect(emissions.last.single.sampleCount, 0);
    });

    test('resetAllAggregates resets every metric snapshot', () async {
      service.registerDefinition({
        'id': 'cpu',
        'aggregators': <String>['last', 'sum'],
      });
      service.registerDefinition({
        'id': 'mem',
        'aggregators': <String>['last'],
      });
      service.recordSample(<String, Object?>{'id': 'cpu', 'value': 10});
      service.recordSample(<String, Object?>{'id': 'mem', 'value': 20});
      await Future<void>.delayed(Duration.zero);
      emissions.clear();

      service.resetAllAggregates();
      await Future<void>.delayed(Duration.zero);

      final cpu = service.snapshotFor('cpu')!;
      final mem = service.snapshotFor('mem')!;
      expect(cpu.sampleCount, 0);
      expect(mem.sampleCount, 0);
      expect(cpu.aggregates[UyavaMetricAggregator.last], isNull);
      expect(mem.aggregates[UyavaMetricAggregator.last], isNull);
      expect(cpu.aggregates[UyavaMetricAggregator.sum], 0);
      expect(emissions, isNotEmpty);
      final ids = emissions.last.map((snapshot) => snapshot.id).toList();
      expect(ids, containsAll(<String>['cpu', 'mem']));
      expect(
        emissions.last.every((snapshot) => snapshot.sampleCount == 0),
        isTrue,
      );
    });
  });
}
