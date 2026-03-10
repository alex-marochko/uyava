import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'metrics_dashboard_view_model.dart';

/// Aggregates metric card render state outside of the widget tree.
class MetricCardViewModel {
  const MetricCardViewModel();

  MetricCardState build(MetricCardViewData data) {
    final GraphMetricSnapshot snapshot = data.snapshot;
    final UyavaMetricDefinitionPayload definition = snapshot.definition;
    final String title = (definition.label ?? '').isNotEmpty
        ? definition.label!
        : snapshot.id;

    final List<MetricAggregateState> aggregates = _buildAggregates(
      definition,
      snapshot,
    );

    final List<double> sparklineValues = data.series.points
        .map((MetricHistorySample sample) => sample.value)
        .toList(growable: false);
    final bool hasSparkline = sparklineValues.length >= 2;
    final bool hasSamples = snapshot.sampleCount > 0;

    return MetricCardState(
      id: snapshot.id,
      title: title,
      aggregates: aggregates,
      sparklineValues: sparklineValues,
      hasSparkline: hasSparkline,
      sparklinePlaceholder: hasSamples
          ? 'Not enough samples for trend'
          : 'No samples yet',
      samplesLabel: 'Samples: ${snapshot.sampleCount}',
      timestampLabel: snapshot.lastTimestamp != null
          ? _formatTimestamp(snapshot.lastTimestamp!)
          : null,
      canReset: hasSamples || data.series.hasHistory,
      infoTooltip: _buildInfoTooltip(definition),
      pinned: data.pinned,
    );
  }

  List<MetricAggregateState> _buildAggregates(
    UyavaMetricDefinitionPayload definition,
    GraphMetricSnapshot snapshot,
  ) {
    final List<MetricAggregateState> aggregates = <MetricAggregateState>[
      for (final UyavaMetricAggregator aggregator
          in definition.aggregators) ...[
        _aggregateStateFor(aggregator, definition.unit, snapshot),
      ],
    ];

    final num? sum = snapshot.valueFor(UyavaMetricAggregator.sum);
    final num? count = snapshot.valueFor(UyavaMetricAggregator.count);
    if (sum != null && count != null && count > 0) {
      aggregates.add(
        MetricAggregateState(
          label: 'Avg',
          valueText: _formatAggregateValue(sum / count, unit: definition.unit),
          tintable: false,
          severity: null,
        ),
      );
    }

    return aggregates;
  }

  MetricAggregateState _aggregateStateFor(
    UyavaMetricAggregator aggregator,
    String? unit,
    GraphMetricSnapshot snapshot,
  ) {
    final num? value = snapshot.valueFor(aggregator);
    final UyavaSeverity? severity = _supportsSeverity(aggregator)
        ? snapshot.severityFor(aggregator)
        : null;
    return MetricAggregateState(
      label: _metricAggregatorLabel(aggregator),
      valueText: value == null
          ? '—'
          : _formatAggregateValue(value, unit: unit, aggregator: aggregator),
      severity: severity,
      tintable: severity != null,
    );
  }

  bool _supportsSeverity(UyavaMetricAggregator aggregator) {
    switch (aggregator) {
      case UyavaMetricAggregator.last:
      case UyavaMetricAggregator.min:
      case UyavaMetricAggregator.max:
        return true;
      case UyavaMetricAggregator.sum:
      case UyavaMetricAggregator.count:
        return false;
    }
  }

  String _metricAggregatorLabel(UyavaMetricAggregator aggregator) {
    switch (aggregator) {
      case UyavaMetricAggregator.last:
        return 'Last';
      case UyavaMetricAggregator.min:
        return 'Min';
      case UyavaMetricAggregator.max:
        return 'Max';
      case UyavaMetricAggregator.sum:
        return 'Sum';
      case UyavaMetricAggregator.count:
        return 'Count';
    }
  }

  String _formatAggregateValue(
    num value, {
    String? unit,
    UyavaMetricAggregator? aggregator,
  }) {
    final double doubleValue = value.toDouble();
    String formatted;
    if (doubleValue.isNaN || doubleValue.isInfinite) {
      formatted = doubleValue.toString();
    } else if ((doubleValue - doubleValue.roundToDouble()).abs() < 0.0001) {
      formatted = doubleValue.toStringAsFixed(0);
    } else if (doubleValue.abs() >= 1000) {
      formatted = doubleValue.toStringAsFixed(0);
    } else if (doubleValue.abs() >= 100) {
      formatted = doubleValue.toStringAsFixed(1);
    } else {
      formatted = doubleValue.toStringAsFixed(2);
    }

    final bool shouldAppendUnit =
        unit != null &&
        unit.isNotEmpty &&
        aggregator != UyavaMetricAggregator.count;
    return shouldAppendUnit ? '$formatted $unit' : formatted;
  }

  String _formatTimestamp(DateTime timestamp) {
    final DateTime local = timestamp.toLocal();
    String twoDigits(int v) => v.toString().padLeft(2, '0');
    String threeDigits(int v) => v.toString().padLeft(3, '0');
    return '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}.${threeDigits(local.millisecond)}';
  }

  String _buildInfoTooltip(UyavaMetricDefinitionPayload definition) {
    final List<String> lines = <String>['Metric id: ${definition.id}'];
    if (definition.description != null && definition.description!.isNotEmpty) {
      lines.add(definition.description!);
    }
    if (definition.unit != null && definition.unit!.isNotEmpty) {
      lines.add('Unit: ${definition.unit}');
    }
    if (definition.tagsNormalized.isNotEmpty) {
      lines.add('Tags: ${definition.tagsNormalized.join(', ')}');
    }
    return lines.join('\n');
  }
}

class MetricCardState {
  const MetricCardState({
    required this.id,
    required this.title,
    required this.aggregates,
    required this.sparklineValues,
    required this.hasSparkline,
    required this.sparklinePlaceholder,
    required this.samplesLabel,
    required this.timestampLabel,
    required this.canReset,
    required this.infoTooltip,
    required this.pinned,
  });

  final String id;
  final String title;
  final List<MetricAggregateState> aggregates;
  final List<double> sparklineValues;
  final bool hasSparkline;
  final String sparklinePlaceholder;
  final String samplesLabel;
  final String? timestampLabel;
  final bool canReset;
  final String infoTooltip;
  final bool pinned;

  bool get hasInfo => infoTooltip.isNotEmpty;
}

class MetricAggregateState {
  const MetricAggregateState({
    required this.label,
    required this.valueText,
    required this.tintable,
    this.severity,
  });

  final String label;
  final String valueText;
  final UyavaSeverity? severity;
  final bool tintable;
}
