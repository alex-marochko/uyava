import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:uyava_core/uyava_core.dart';

/// Provides aggregated dashboard state derived from [GraphController] metrics.
class MetricsDashboardViewModel extends ChangeNotifier {
  MetricsDashboardViewModel({
    required GraphController controller,
    bool applyFilters = false,
    int maxHistoryPoints = 120,
    Duration? historyRetention = const Duration(minutes: 5),
    Set<String> pinnedMetrics = const <String>{},
  }) : _controller = controller,
       _applyFilters = applyFilters,
       _maxHistoryPoints = maxHistoryPoints,
       _historyRetention = historyRetention,
       _pinnedMetricIds = Set<String>.of(pinnedMetrics) {
    _metrics = _currentMetrics();
    _seedHistory(_metrics);
    _metricsSub = _controller.metricsStream.listen(_handleMetricsUpdate);
    _filtersSub = _controller.filtersStream.listen(_handleFiltersChange);
  }

  final GraphController _controller;
  final Map<String, MetricHistorySeries> _historyById =
      <String, MetricHistorySeries>{};

  bool _applyFilters;
  int _maxHistoryPoints;
  Duration? _historyRetention;
  late List<GraphMetricSnapshot> _metrics;
  Set<String> _pinnedMetricIds;

  StreamSubscription<List<GraphMetricSnapshot>>? _metricsSub;
  StreamSubscription<GraphFilterResult>? _filtersSub;

  /// Ordered cards rendered by the dashboard.
  UnmodifiableListView<MetricCardViewData> get cards {
    final List<GraphMetricSnapshot> ordered = _orderedMetrics();
    final List<MetricCardViewData> views = <MetricCardViewData>[
      for (final GraphMetricSnapshot snapshot in ordered)
        MetricCardViewData(
          snapshot: snapshot,
          series: _historyById.putIfAbsent(
            snapshot.id,
            () => MetricHistorySeries(),
          ),
          pinned: _pinnedMetricIds.contains(snapshot.id),
        ),
    ];
    return UnmodifiableListView<MetricCardViewData>(views);
  }

  /// Captures pinned metric ids after sorting/pruning.
  Set<String> get pinnedMetricIds => Set.unmodifiable(_pinnedMetricIds);

  bool get hasMetrics => _metrics.isNotEmpty;

  bool get hasHistory => _historyById.values.any(
    (MetricHistorySeries series) => series.hasHistory,
  );

  bool get hasAnyMetricData =>
      hasHistory ||
      _metrics.any((GraphMetricSnapshot snapshot) => snapshot.sampleCount > 0);

  void togglePin(String metricId) {
    if (_pinnedMetricIds.contains(metricId)) {
      _pinnedMetricIds.remove(metricId);
    } else {
      _pinnedMetricIds.add(metricId);
    }
    notifyListeners();
  }

  void setPinnedMetrics(Set<String> pinned) {
    if (setEquals(_pinnedMetricIds, pinned)) return;
    _pinnedMetricIds = Set<String>.of(pinned);
    notifyListeners();
  }

  void setApplyFilters(bool applyFilters) {
    if (_applyFilters == applyFilters) return;
    _applyFilters = applyFilters;
    _refreshMetrics(resetHistory: true);
  }

  void updateHistoryOptions({
    required int maxHistoryPoints,
    Duration? historyRetention,
  }) {
    final bool boundsChanged =
        _maxHistoryPoints != maxHistoryPoints ||
        _historyRetention != historyRetention;
    if (!boundsChanged) return;
    _maxHistoryPoints = maxHistoryPoints;
    _historyRetention = historyRetention;
    _reseedHistory(_metrics);
    notifyListeners();
  }

  void resetMetric(String metricId) {
    _controller.resetMetricAggregates(metricId);
    _historyById[metricId]?.reset();
    notifyListeners();
  }

  void resetAll() {
    _controller.resetAllMetricAggregates();
    for (final MetricHistorySeries series in _historyById.values) {
      series.reset();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _metricsSub?.cancel();
    _filtersSub?.cancel();
    super.dispose();
  }

  void _handleMetricsUpdate(List<GraphMetricSnapshot> snapshots) {
    _metrics = _applyFilters ? _controller.filteredMetrics : snapshots;
    _updateHistory(_metrics);
    _prunePinnedMetricsLocked();
    notifyListeners();
  }

  void _handleFiltersChange(GraphFilterResult _) {
    if (!_applyFilters) return;
    _refreshMetrics(resetHistory: false);
  }

  void _refreshMetrics({required bool resetHistory}) {
    _metrics = _currentMetrics();
    if (resetHistory) {
      _reseedHistory(_metrics);
    }
    _prunePinnedMetricsLocked();
    notifyListeners();
  }

  void _reseedHistory(List<GraphMetricSnapshot> snapshots) {
    _historyById.clear();
    _seedHistory(snapshots);
  }

  void _seedHistory(List<GraphMetricSnapshot> snapshots) {
    if (snapshots.isEmpty) return;
    _updateHistory(snapshots);
  }

  void _updateHistory(List<GraphMetricSnapshot> snapshots) {
    final Set<String> liveIds = <String>{};
    final DateTime now = DateTime.now().toUtc();
    for (final GraphMetricSnapshot snapshot in snapshots) {
      liveIds.add(snapshot.id);
      final MetricHistorySeries series = _historyById.putIfAbsent(
        snapshot.id,
        () => MetricHistorySeries(),
      );
      series.update(
        snapshot,
        maxPoints: _maxHistoryPoints,
        retention: _historyRetention,
        now: now,
      );
    }
    if (_historyById.length != liveIds.length) {
      final List<String> stale = <String>[
        for (final String id in _historyById.keys)
          if (!liveIds.contains(id)) id,
      ];
      for (final String id in stale) {
        _historyById.remove(id);
      }
    }
  }

  bool _prunePinnedMetricsLocked() {
    final Set<String> liveMetricIds = _controller.metrics
        .map((GraphMetricSnapshot metric) => metric.id)
        .toSet();
    final int before = _pinnedMetricIds.length;
    _pinnedMetricIds.removeWhere((String id) => !liveMetricIds.contains(id));
    return _pinnedMetricIds.length != before;
  }

  List<GraphMetricSnapshot> _orderedMetrics() {
    if (_pinnedMetricIds.isEmpty) {
      return _metrics;
    }
    final List<GraphMetricSnapshot> pinned = <GraphMetricSnapshot>[];
    final List<GraphMetricSnapshot> others = <GraphMetricSnapshot>[];
    for (final GraphMetricSnapshot snapshot in _metrics) {
      if (_pinnedMetricIds.contains(snapshot.id)) {
        pinned.add(snapshot);
      } else {
        others.add(snapshot);
      }
    }
    return <GraphMetricSnapshot>[...pinned, ...others];
  }

  List<GraphMetricSnapshot> _currentMetrics() {
    return _applyFilters ? _controller.filteredMetrics : _controller.metrics;
  }
}

/// Render data for a single metric card.
class MetricCardViewData {
  const MetricCardViewData({
    required this.snapshot,
    required this.series,
    required this.pinned,
  });

  final GraphMetricSnapshot snapshot;
  final MetricHistorySeries series;
  final bool pinned;
}

/// Maintains sparkline samples for a metric definition.
class MetricHistorySeries {
  int lastSampleCount = 0;
  double? lastValue;
  final List<MetricHistorySample> _points = <MetricHistorySample>[];

  List<MetricHistorySample> get points =>
      UnmodifiableListView<MetricHistorySample>(_points);

  bool get hasHistory => _points.isNotEmpty;

  void update(
    GraphMetricSnapshot snapshot, {
    required int maxPoints,
    required Duration? retention,
    required DateTime now,
  }) {
    if (snapshot.sampleCount < lastSampleCount) {
      reset();
    }

    lastSampleCount = snapshot.sampleCount;

    num? lastAggregate = snapshot.valueFor(UyavaMetricAggregator.last);
    lastAggregate ??= _fallbackTrendValue(snapshot);
    if (lastAggregate == null) {
      if (snapshot.sampleCount == 0) {
        reset();
      }
      return;
    }

    final double value = lastAggregate.toDouble();
    final DateTime timestamp = (snapshot.lastTimestamp ?? now).toUtc();

    final bool countChanged =
        _points.isEmpty || snapshot.sampleCount != _points.last.sampleCount;
    final bool valueChanged = lastValue == null || lastValue != value;

    if (countChanged || valueChanged) {
      _points.add(
        MetricHistorySample(
          timestamp: timestamp,
          value: value,
          sampleCount: snapshot.sampleCount,
        ),
      );
    } else if (_points.isNotEmpty) {
      _points[_points.length - 1] = _points.last.copyWith(timestamp: timestamp);
    }

    lastValue = value;

    if (retention != null) {
      final DateTime cutoff = timestamp.subtract(retention);
      _points.removeWhere((MetricHistorySample sample) {
        return sample.timestamp.isBefore(cutoff);
      });
    }

    final int overflow = _points.length - maxPoints;
    if (overflow > 0) {
      _points.removeRange(0, overflow);
    }
  }

  void reset() {
    _points.clear();
    lastValue = null;
    lastSampleCount = 0;
  }

  num? _fallbackTrendValue(GraphMetricSnapshot snapshot) {
    for (final UyavaMetricAggregator aggregator
        in snapshot.definition.aggregators) {
      final num? value = snapshot.valueFor(aggregator);
      if (value != null) {
        return value;
      }
    }
    return null;
  }
}

/// Immutable value representing an entry on a metric sparkline.
class MetricHistorySample {
  const MetricHistorySample({
    required this.timestamp,
    required this.value,
    required this.sampleCount,
  });

  final DateTime timestamp;
  final double value;
  final int sampleCount;

  MetricHistorySample copyWith({DateTime? timestamp}) {
    return MetricHistorySample(
      timestamp: timestamp ?? this.timestamp,
      value: value,
      sampleCount: sampleCount,
    );
  }
}
