import 'package:collection/collection.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

/// Snapshot of a metric definition and its aggregated values.
class GraphMetricSnapshot {
  GraphMetricSnapshot({
    required this.definition,
    required Map<UyavaMetricAggregator, num> aggregates,
    required Map<UyavaMetricAggregator, UyavaSeverity> severities,
    required this.sampleCount,
    required this.lastTimestamp,
  }) : _aggregates = Map<UyavaMetricAggregator, num>.unmodifiable(aggregates),
       _severities = Map<UyavaMetricAggregator, UyavaSeverity>.unmodifiable(
         severities,
       );

  /// Metric definition captured from the latest registration.
  final UyavaMetricDefinitionPayload definition;

  final Map<UyavaMetricAggregator, num> _aggregates;

  /// Aggregated values keyed by requested aggregator.
  Map<UyavaMetricAggregator, num> get aggregates => _aggregates;

  final Map<UyavaMetricAggregator, UyavaSeverity> _severities;

  /// Aggregated severities keyed by the aggregator that produced them.
  Map<UyavaMetricAggregator, UyavaSeverity> get severities => _severities;

  /// Total number of samples applied to this metric.
  final int sampleCount;

  /// Timestamp of the most recent sample (UTC).
  final DateTime? lastTimestamp;

  /// Convenience accessor for the metric identifier.
  String get id => definition.id;

  /// Returns the aggregated value for [aggregator] when available.
  num? valueFor(UyavaMetricAggregator aggregator) => _aggregates[aggregator];

  /// Returns the severity associated with [aggregator], if recorded.
  UyavaSeverity? severityFor(UyavaMetricAggregator aggregator) =>
      _severities[aggregator];
}

/// Structured diagnostic emitted while processing metric payloads.
class GraphMetricDiagnostic {
  const GraphMetricDiagnostic({required this.code, this.context});

  final UyavaGraphIntegrityCode code;
  final Map<String, Object?>? context;
}

/// Result of registering or re-registering a metric definition.
class GraphMetricRegistrationResult {
  const GraphMetricRegistrationResult({
    required this.snapshot,
    required this.updated,
    required this.diagnostics,
  });

  /// Latest snapshot for the metric, if available.
  final GraphMetricSnapshot? snapshot;

  /// Whether the registration modified the underlying metric state.
  final bool updated;

  /// Diagnostics surfaced while applying the definition.
  final List<GraphMetricDiagnostic> diagnostics;
}

/// Result of applying a metric sample.
class GraphMetricSampleResult {
  const GraphMetricSampleResult({
    required this.snapshot,
    required this.applied,
    required this.diagnostics,
  });

  /// Latest snapshot for the metric, if available.
  final GraphMetricSnapshot? snapshot;

  /// Whether the sample affected stored aggregates.
  final bool applied;

  /// Diagnostics surfaced while processing the sample.
  final List<GraphMetricDiagnostic> diagnostics;
}

/// In-memory store for metric definitions and aggregated values.
class GraphMetricsStore {
  final Map<String, _MetricState> _metrics = <String, _MetricState>{};
  final SetEquality<UyavaMetricAggregator> _aggregatorEquality =
      const SetEquality<UyavaMetricAggregator>();

  /// Registers a metric definition and returns the resulting snapshot.
  GraphMetricRegistrationResult register(UyavaMetricDefinitionPayload payload) {
    final _MetricState? existing = _metrics[payload.id];
    if (existing == null) {
      final _MetricState state = _MetricState(payload);
      _metrics[payload.id] = state;
      return GraphMetricRegistrationResult(
        snapshot: state.toSnapshot(),
        updated: true,
        diagnostics: const <GraphMetricDiagnostic>[],
      );
    }

    final Set<UyavaMetricAggregator> previousAggregators = existing.aggregators;
    final Set<UyavaMetricAggregator> nextAggregators = payload.aggregators
        .toSet();

    if (!_aggregatorEquality.equals(previousAggregators, nextAggregators)) {
      final Map<String, Object?> context = <String, Object?>{
        'metricId': payload.id,
        'previousAggregators': previousAggregators
            .map((mode) => mode.name)
            .toList(growable: false),
        'nextAggregators': nextAggregators
            .map((mode) => mode.name)
            .toList(growable: false),
      };
      existing.resetWithDefinition(payload, resetAggregates: true);
      return GraphMetricRegistrationResult(
        snapshot: existing.toSnapshot(),
        updated: true,
        diagnostics: <GraphMetricDiagnostic>[
          GraphMetricDiagnostic(
            code: UyavaGraphIntegrityCode.metricsConflictingDefinition,
            context: context,
          ),
        ],
      );
    }

    final bool updated = existing.updateDefinition(payload);
    return GraphMetricRegistrationResult(
      snapshot: existing.toSnapshot(),
      updated: updated,
      diagnostics: const <GraphMetricDiagnostic>[],
    );
  }

  /// Applies a metric sample, updating aggregates when the metric exists.
  GraphMetricSampleResult applySample(
    UyavaMetricSamplePayload payload, {
    required DateTime timestamp,
    required UyavaSeverity? severity,
  }) {
    final _MetricState? state = _metrics[payload.id];
    if (state == null) {
      return GraphMetricSampleResult(
        snapshot: null,
        applied: false,
        diagnostics: <GraphMetricDiagnostic>[
          GraphMetricDiagnostic(
            code: UyavaGraphIntegrityCode.metricsUnknownId,
            context: <String, Object?>{'metricId': payload.id},
          ),
        ],
      );
    }

    final bool changed = state.applySample(
      payload.value,
      timestamp: timestamp,
      severity: severity,
    );
    return GraphMetricSampleResult(
      snapshot: state.toSnapshot(),
      applied: changed,
      diagnostics: const <GraphMetricDiagnostic>[],
    );
  }

  /// Returns an immutable list of metric snapshots.
  List<GraphMetricSnapshot> allSnapshots() {
    return _metrics.values
        .map((state) => state.toSnapshot())
        .toList(growable: false);
  }

  /// Returns a snapshot for the provided [metricId], if available.
  GraphMetricSnapshot? snapshotFor(String metricId) {
    final _MetricState? state = _metrics[metricId];
    return state?.toSnapshot();
  }

  /// Exposes the current metric ids tracked by the store.
  Iterable<String> get metricIds => _metrics.keys;

  /// Resets aggregates for the metric with [metricId].
  bool reset(String metricId) {
    final _MetricState? state = _metrics[metricId];
    if (state == null) return false;
    state.resetAggregatesValues();
    return true;
  }

  /// Resets aggregates for all registered metrics.
  bool resetAll() {
    if (_metrics.isEmpty) return false;
    for (final _MetricState state in _metrics.values) {
      state.resetAggregatesValues();
    }
    return true;
  }

  /// Removes all metric definitions and aggregated values.
  bool clear() {
    if (_metrics.isEmpty) return false;
    _metrics.clear();
    return true;
  }
}

class _MetricState {
  _MetricState(this.definition)
    : _aggregators = Set<UyavaMetricAggregator>.from(definition.aggregators);

  UyavaMetricDefinitionPayload definition;
  Set<UyavaMetricAggregator> _aggregators;
  double? _lastValue;
  UyavaSeverity? _lastSeverity;
  double? _minValue;
  UyavaSeverity? _minSeverity;
  double? _maxValue;
  UyavaSeverity? _maxSeverity;
  double _sumValue = 0;
  int _countValue = 0;
  int _sampleCount = 0;
  DateTime? _lastTimestamp;

  Set<UyavaMetricAggregator> get aggregators =>
      Set<UyavaMetricAggregator>.unmodifiable(_aggregators);

  void resetWithDefinition(
    UyavaMetricDefinitionPayload next, {
    required bool resetAggregates,
  }) {
    definition = next;
    _aggregators = Set<UyavaMetricAggregator>.from(next.aggregators);
    if (resetAggregates) {
      resetAggregatesValues();
    }
  }

  bool updateDefinition(UyavaMetricDefinitionPayload next) {
    if (definition == next) {
      return false;
    }
    definition = next;
    _aggregators = Set<UyavaMetricAggregator>.from(next.aggregators);
    return true;
  }

  bool applySample(
    double value, {
    required DateTime timestamp,
    required UyavaSeverity? severity,
  }) {
    bool changed = false;
    _sampleCount += 1;

    if (_aggregators.contains(UyavaMetricAggregator.last)) {
      if (_lastValue != value) {
        changed = true;
      }
      _lastValue = value;
      if (_lastSeverity != severity) {
        _lastSeverity = severity;
        changed = true;
      }
    }

    if (_aggregators.contains(UyavaMetricAggregator.min)) {
      final bool shouldUpdateMin =
          _minValue == null ||
          value < _minValue! ||
          (value == _minValue! && _minSeverity != severity);
      if (shouldUpdateMin) {
        changed = true;
        _minValue = value;
        if (_minSeverity != severity) {
          _minSeverity = severity;
        }
      }
    }

    if (_aggregators.contains(UyavaMetricAggregator.max)) {
      final bool shouldUpdateMax =
          _maxValue == null ||
          value > _maxValue! ||
          (value == _maxValue! && _maxSeverity != severity);
      if (shouldUpdateMax) {
        changed = true;
        _maxValue = value;
        if (_maxSeverity != severity) {
          _maxSeverity = severity;
        }
      }
    }

    if (_aggregators.contains(UyavaMetricAggregator.sum)) {
      _sumValue += value;
      changed = true;
    }

    if (_aggregators.contains(UyavaMetricAggregator.count)) {
      _countValue += 1;
      changed = true;
    }

    if (_lastTimestamp != timestamp) {
      _lastTimestamp = timestamp;
      changed = true;
    }

    return changed;
  }

  GraphMetricSnapshot toSnapshot() {
    final Map<UyavaMetricAggregator, num> aggregates =
        <UyavaMetricAggregator, num>{};
    if (_aggregators.contains(UyavaMetricAggregator.last) &&
        _lastValue != null) {
      aggregates[UyavaMetricAggregator.last] = _lastValue!;
    }
    if (_aggregators.contains(UyavaMetricAggregator.min) && _minValue != null) {
      aggregates[UyavaMetricAggregator.min] = _minValue!;
    }
    if (_aggregators.contains(UyavaMetricAggregator.max) && _maxValue != null) {
      aggregates[UyavaMetricAggregator.max] = _maxValue!;
    }
    if (_aggregators.contains(UyavaMetricAggregator.sum)) {
      aggregates[UyavaMetricAggregator.sum] = _sumValue;
    }
    if (_aggregators.contains(UyavaMetricAggregator.count)) {
      aggregates[UyavaMetricAggregator.count] = _countValue;
    }

    final Map<UyavaMetricAggregator, UyavaSeverity> severities =
        <UyavaMetricAggregator, UyavaSeverity>{};
    if (_aggregators.contains(UyavaMetricAggregator.last) &&
        _lastValue != null &&
        _lastSeverity != null) {
      severities[UyavaMetricAggregator.last] = _lastSeverity!;
    }
    if (_aggregators.contains(UyavaMetricAggregator.min) &&
        _minValue != null &&
        _minSeverity != null) {
      severities[UyavaMetricAggregator.min] = _minSeverity!;
    }
    if (_aggregators.contains(UyavaMetricAggregator.max) &&
        _maxValue != null &&
        _maxSeverity != null) {
      severities[UyavaMetricAggregator.max] = _maxSeverity!;
    }

    return GraphMetricSnapshot(
      definition: definition,
      aggregates: aggregates,
      severities: severities,
      sampleCount: _sampleCount,
      lastTimestamp: _lastTimestamp,
    );
  }

  void resetAggregatesValues() {
    _lastValue = null;
    _lastSeverity = null;
    _minValue = null;
    _minSeverity = null;
    _maxValue = null;
    _maxSeverity = null;
    _sumValue = 0;
    _countValue = 0;
    _sampleCount = 0;
    _lastTimestamp = null;
  }
}
