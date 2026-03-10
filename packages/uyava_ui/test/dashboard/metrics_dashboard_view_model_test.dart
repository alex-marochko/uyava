import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetricsDashboardViewModel', () {
    test('orders pinned metrics and toggles pins', () async {
      final GraphController controller = GraphController();
      addTearDown(controller.dispose);

      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'latency',
        'label': 'Latency',
        'aggregators': <String>['last'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 12,
        'timestamp': '2024-01-01T00:00:01Z',
      });

      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'throughput',
        'label': 'Throughput',
        'aggregators': <String>['last'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'throughput',
        'value': 42,
        'timestamp': '2024-01-01T00:00:02Z',
      });

      final MetricsDashboardViewModel viewModel = MetricsDashboardViewModel(
        controller: controller,
        pinnedMetrics: const <String>{'throughput'},
      );
      addTearDown(viewModel.dispose);

      await pumpEventQueue();

      expect(viewModel.cards.first.snapshot.id, equals('throughput'));

      viewModel.togglePin('throughput');
      await pumpEventQueue();

      expect(viewModel.cards.first.snapshot.id, equals('latency'));
    });

    test('maintains sparkline history and resets series', () async {
      final GraphController controller = GraphController();
      addTearDown(controller.dispose);

      controller.registerMetricDefinition(<String, dynamic>{
        'id': 'latency',
        'label': 'Latency',
        'aggregators': <String>['last'],
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 12,
        'timestamp': '2024-01-01T00:00:01Z',
      });

      final MetricsDashboardViewModel viewModel = MetricsDashboardViewModel(
        controller: controller,
        maxHistoryPoints: 10,
      );
      addTearDown(viewModel.dispose);

      await pumpEventQueue();

      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 18,
        'timestamp': '2024-01-01T00:00:02Z',
      });
      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 20,
        'timestamp': '2024-01-01T00:00:03Z',
      });

      await pumpEventQueue();

      final MetricCardViewData card = viewModel.cards.first;
      expect(card.series.points.length, greaterThanOrEqualTo(2));

      viewModel.resetMetric('latency');
      expect(card.series.points, isEmpty);

      controller.recordMetricSample(<String, dynamic>{
        'id': 'latency',
        'value': 30,
        'timestamp': '2024-01-01T00:00:04Z',
      });
      await pumpEventQueue();

      expect(card.series.points.length, equals(1));
    });
  });

  test('builds history when last aggregator missing', () async {
    final GraphController controller = GraphController();
    addTearDown(controller.dispose);

    controller.registerMetricDefinition(<String, dynamic>{
      'id': 'throughput',
      'label': 'Throughput',
      'unit': 'req/s',
      'aggregators': <String>['sum', 'count'],
    });
    controller.recordMetricSample(<String, dynamic>{
      'id': 'throughput',
      'value': 5,
      'timestamp': '2024-01-01T00:00:01Z',
    });

    final MetricsDashboardViewModel viewModel = MetricsDashboardViewModel(
      controller: controller,
      maxHistoryPoints: 10,
    );
    addTearDown(viewModel.dispose);

    await pumpEventQueue();

    controller.recordMetricSample(<String, dynamic>{
      'id': 'throughput',
      'value': 7,
      'timestamp': '2024-01-01T00:00:02Z',
    });
    controller.recordMetricSample(<String, dynamic>{
      'id': 'throughput',
      'value': 9,
      'timestamp': '2024-01-01T00:00:03Z',
    });
    await pumpEventQueue();

    final MetricCardViewData card = viewModel.cards.first;
    expect(card.series.points.length, greaterThanOrEqualTo(2));
  });

  test('retains history when filters stream emits with applyFilters', () async {
    final GraphController controller = GraphController();
    addTearDown(controller.dispose);

    controller.registerMetricDefinition(<String, dynamic>{
      'id': 'latency',
      'label': 'Latency',
      'aggregators': <String>['last'],
    });

    final MetricsDashboardViewModel viewModel = MetricsDashboardViewModel(
      controller: controller,
      applyFilters: true,
      maxHistoryPoints: 10,
    );
    addTearDown(viewModel.dispose);

    controller.recordMetricSample(<String, dynamic>{
      'id': 'latency',
      'value': 10,
      'timestamp': '2024-01-01T00:00:01Z',
    });
    await pumpEventQueue();

    controller.recordMetricSample(<String, dynamic>{
      'id': 'latency',
      'value': 12,
      'timestamp': '2024-01-01T00:00:02Z',
    });
    await pumpEventQueue();

    final MetricCardViewData card = viewModel.cards.first;
    expect(card.series.points.length, greaterThanOrEqualTo(2));
  });

  test('keeps pinned metrics across temporary filter exclusion', () async {
    final GraphController controller = GraphController();
    addTearDown(controller.dispose);

    controller.registerMetricDefinition(<String, dynamic>{
      'id': 'latency',
      'label': 'Latency',
      'aggregators': <String>['last'],
    });
    controller.recordMetricSample(<String, dynamic>{
      'id': 'latency',
      'value': 10,
      'timestamp': '2024-01-01T00:00:01Z',
    });

    controller.registerMetricDefinition(<String, dynamic>{
      'id': 'throughput',
      'label': 'Throughput',
      'aggregators': <String>['last'],
    });
    controller.recordMetricSample(<String, dynamic>{
      'id': 'throughput',
      'value': 20,
      'timestamp': '2024-01-01T00:00:02Z',
    });

    final MetricsDashboardViewModel viewModel = MetricsDashboardViewModel(
      controller: controller,
      applyFilters: true,
      pinnedMetrics: const <String>{'throughput'},
    );
    addTearDown(viewModel.dispose);

    await pumpEventQueue();
    expect(viewModel.pinnedMetricIds, contains('throughput'));

    controller.updateFilters(
      GraphFilterState(
        search: GraphFilterSearch(
          mode: UyavaFilterSearchMode.substring,
          pattern: 'no-match',
          caseSensitive: false,
        ),
      ),
    );
    await pumpEventQueue();

    expect(viewModel.cards, isEmpty);
    expect(viewModel.pinnedMetricIds, contains('throughput'));

    controller.updateFilters(GraphFilterState.empty);
    await pumpEventQueue();

    expect(viewModel.pinnedMetricIds, contains('throughput'));
    expect(viewModel.cards.first.snapshot.id, equals('throughput'));
  });
}
