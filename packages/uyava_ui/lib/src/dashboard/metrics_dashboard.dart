import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import '../theme.dart';
import 'metric_card_view_model.dart';
import 'metrics_dashboard_view_model.dart';
import 'sparkline_painter.dart';

part 'metric_card.dart';

/// Shared dashboard panel rendering aggregated graph metrics with
/// live-updating cards and sparklines.
class UyavaMetricsDashboard extends StatefulWidget {
  const UyavaMetricsDashboard({
    super.key,
    required this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    this.maxHistoryPoints = 120,
    this.historyRetention = const Duration(minutes: 5),
    this.applyFilters = false,
    this.compactMode,
    this.onCompactModeChanged,
    this.pinnedMetrics = const <String>{},
    this.onPinnedMetricsChanged,
  }) : assert(maxHistoryPoints > 0, 'maxHistoryPoints must be positive');

  /// Graph controller supplying metric definitions and samples.
  final GraphController controller;

  /// Scroll padding applied around the grid of cards.
  final EdgeInsetsGeometry padding;

  /// Maximum number of sparkline points retained per metric.
  final int maxHistoryPoints;

  /// Optional retention window for sparkline points. Older entries are dropped
  /// when the timestamp falls outside this window. Pass `null` to keep all
  /// points up to [maxHistoryPoints].
  final Duration? historyRetention;

  /// Whether to use the controller's filtered metrics instead of the full set.
  final bool applyFilters;

  /// When provided, overrides the compact-mode state for rendering.
  /// If omitted, the widget manages the toggle locally.
  final bool? compactMode;

  /// Callback invoked whenever the compact-mode toggle changes.
  final ValueChanged<bool>? onCompactModeChanged;

  /// Metrics that should appear at the top of the dashboard.
  final Set<String> pinnedMetrics;

  /// Notifies listeners whenever the pinned metric set changes.
  final ValueChanged<Set<String>>? onPinnedMetricsChanged;

  @override
  State<UyavaMetricsDashboard> createState() => _UyavaMetricsDashboardState();
}

class _UyavaMetricsDashboardState extends State<UyavaMetricsDashboard> {
  late MetricsDashboardViewModel _viewModel;
  bool _compactMode = false;
  Set<String> _lastPinned = const <String>{};

  @override
  void initState() {
    super.initState();
    _compactMode = widget.compactMode ?? false;
    _viewModel = _createViewModel();
    _lastPinned = _viewModel.pinnedMetricIds;
    _viewModel.addListener(_handleViewModelChanged);
  }

  MetricsDashboardViewModel _createViewModel() {
    return MetricsDashboardViewModel(
      controller: widget.controller,
      applyFilters: widget.applyFilters,
      maxHistoryPoints: widget.maxHistoryPoints,
      historyRetention: widget.historyRetention,
      pinnedMetrics: widget.pinnedMetrics,
    );
  }

  @override
  void didUpdateWidget(UyavaMetricsDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      _replaceViewModel();
    } else {
      if (widget.applyFilters != oldWidget.applyFilters) {
        _viewModel.setApplyFilters(widget.applyFilters);
      }
      if (widget.maxHistoryPoints != oldWidget.maxHistoryPoints ||
          widget.historyRetention != oldWidget.historyRetention) {
        _viewModel.updateHistoryOptions(
          maxHistoryPoints: widget.maxHistoryPoints,
          historyRetention: widget.historyRetention,
        );
      }
      if (!setEquals(widget.pinnedMetrics, oldWidget.pinnedMetrics)) {
        _viewModel.setPinnedMetrics(widget.pinnedMetrics);
      }
    }
    if (widget.compactMode != oldWidget.compactMode &&
        widget.compactMode != null) {
      setState(() {
        _compactMode = widget.compactMode!;
      });
    }
  }

  void _replaceViewModel() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    _viewModel = _createViewModel();
    _lastPinned = _viewModel.pinnedMetricIds;
    _viewModel.addListener(_handleViewModelChanged);
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    final Set<String> pins = _viewModel.pinnedMetricIds;
    if (!setEquals(_lastPinned, pins)) {
      _lastPinned = Set<String>.of(pins);
      widget.onPinnedMetricsChanged?.call(_lastPinned);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleCompactMode() {
    final bool next = !_compactMode;
    widget.onCompactModeChanged?.call(next);
    setState(() {
      _compactMode = next;
    });
  }

  void _handleResetAll() {
    _viewModel.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final List<MetricCardViewData> cards = _viewModel.cards;
    if (cards.isEmpty) {
      return Center(
        child: Text(
          'No metrics',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        const double horizontalSpacing = 12;
        const double verticalSpacing = 0;
        final double targetWidth = _compactMode ? 240 : 360;
        final int metricCount = cards.length;

        int crossAxisCount = math.max(1, (width / targetWidth).floor());
        if (crossAxisCount > metricCount && metricCount > 0) {
          crossAxisCount = metricCount;
        }

        final int rowCount = (metricCount / crossAxisCount).ceil();
        return SingleChildScrollView(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(
                compactMode: _compactMode,
                hasMetricData: _viewModel.hasAnyMetricData,
                onToggleCompactMode: _toggleCompactMode,
                onResetAll: _handleResetAll,
              ),
              const SizedBox(height: 2),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rowCount,
                separatorBuilder: (_, index) =>
                    const SizedBox(height: verticalSpacing),
                itemBuilder: (context, rowIndex) {
                  final int start = rowIndex * crossAxisCount;
                  final int end = math.min(start + crossAxisCount, metricCount);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int column = 0; column < crossAxisCount; column++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: column == 0 ? 0 : horizontalSpacing / 2,
                              right: column == crossAxisCount - 1
                                  ? 0
                                  : horizontalSpacing / 2,
                            ),
                            child: start + column < end
                                ? _MetricCard(
                                    key: ValueKey<String>(
                                      'metric-card-${cards[start + column].snapshot.id}',
                                    ),
                                    data: cards[start + column],
                                    compactMode: _compactMode,
                                    onReset: () => _viewModel.resetMetric(
                                      cards[start + column].snapshot.id,
                                    ),
                                    onPinToggle: () => _viewModel.togglePin(
                                      cards[start + column].snapshot.id,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.compactMode,
    required this.hasMetricData,
    required this.onToggleCompactMode,
    required this.onResetAll,
  });

  final bool compactMode;
  final bool hasMetricData;
  final VoidCallback onToggleCompactMode;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonStyle actionStyle = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      minimumSize: const Size(0, 28),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: theme.textTheme.labelSmall,
    );
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Tooltip(
            message: compactMode
                ? 'Switch to detailed view'
                : 'Switch to compact view',
            waitDuration: const Duration(milliseconds: 300),
            child: IconButton(
              icon: const Icon(Icons.view_agenda_outlined, size: 18),
              selectedIcon: const Icon(Icons.view_list, size: 18),
              isSelected: compactMode,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              visualDensity: VisualDensity.compact,
              onPressed: onToggleCompactMode,
            ),
          ),
          TextButton.icon(
            onPressed: hasMetricData ? onResetAll : null,
            style: actionStyle,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset all'),
          ),
        ],
      ),
    );
  }
}
