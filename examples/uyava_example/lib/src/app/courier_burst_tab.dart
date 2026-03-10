part of 'package:uyava_example/main.dart';

enum _CourierBurstMetricHint { none, trackingGap, etaDrift }

enum _CourierBurstPhase { warmup, steady }

class _CourierBurstStep {
  const _CourierBurstStep({
    required this.edgeId,
    required this.nodeId,
    required this.edgeNarrative,
    required this.nodeNarrative,
    required this.reason,
    this.metricHint = _CourierBurstMetricHint.none,
    this.severity = UyavaSeverity.info,
  });

  final String edgeId;
  final String nodeId;
  final String edgeNarrative;
  final String nodeNarrative;
  final String reason;
  final _CourierBurstMetricHint metricHint;
  final UyavaSeverity severity;
}

class _CourierBurstSelection {
  const _CourierBurstSelection({
    required this.step,
    required this.phase,
    required this.phaseIndex,
    required this.phaseTotal,
  });

  final _CourierBurstStep step;
  final _CourierBurstPhase phase;
  final int phaseIndex;
  final int phaseTotal;
}

mixin _CourierBurstTabMixin on _ExampleAppStateBase, _MetricsLogicMixin {
  static const List<_CourierBurstStep>
  _trackingWarmupScenario = <_CourierBurstStep>[
    _CourierBurstStep(
      edgeId: 'e33',
      nodeId: 'cubit_order',
      edgeNarrative: 'Tracking screen bootstrapped order status flow',
      nodeNarrative: 'Order status cubit accepted the initial tracking request',
      reason: 'bootstrap_tracking_state',
    ),
    _CourierBurstStep(
      edgeId: 'e34',
      nodeId: 'service_socket',
      edgeNarrative: 'Order status cubit opened courier live channel',
      nodeNarrative: 'Order websocket subscribed to courier updates',
      reason: 'subscribe_courier_channel',
    ),
    _CourierBurstStep(
      edgeId: 'e35',
      nodeId: 'service_location',
      edgeNarrative: 'Order status cubit requested location refresh',
      nodeNarrative: 'Location service queued active-order refresh',
      reason: 'refresh_location_state',
      metricHint: _CourierBurstMetricHint.trackingGap,
    ),
    _CourierBurstStep(
      edgeId: 'e89',
      nodeId: 'cubit_tracking_details',
      edgeNarrative: 'Tracking screen requested details snapshot',
      nodeNarrative: 'Tracking details cubit started courier snapshot workflow',
      reason: 'request_tracking_snapshot',
      severity: UyavaSeverity.debug,
    ),
    _CourierBurstStep(
      edgeId: 'e90',
      nodeId: 'repo_tracking',
      edgeNarrative: 'Tracking details cubit asked repository for snapshot',
      nodeNarrative: 'Tracking repository loaded latest courier frame',
      reason: 'load_tracking_snapshot',
    ),
    _CourierBurstStep(
      edgeId: 'e92',
      nodeId: 'model_courier',
      edgeNarrative: 'Tracking repository wrote fresh courier model',
      nodeNarrative: 'Courier model updated from newest GPS point',
      reason: 'refresh_courier_model',
      severity: UyavaSeverity.debug,
    ),
    _CourierBurstStep(
      edgeId: 'e93',
      nodeId: 'service_map_provider',
      edgeNarrative: 'Map view synchronized camera and map layers',
      nodeNarrative: 'Map provider applied latest courier viewport state',
      reason: 'sync_map_layers',
    ),
    _CourierBurstStep(
      edgeId: 'e94',
      nodeId: 'model_route',
      edgeNarrative: 'Location service recalculated route model',
      nodeNarrative: 'Route model recomputed from current courier position',
      reason: 'recompute_route_geometry',
      metricHint: _CourierBurstMetricHint.trackingGap,
    ),
    _CourierBurstStep(
      edgeId: 'e95',
      nodeId: 'util_eta_calculator',
      edgeNarrative: 'Order status cubit triggered ETA recalculation',
      nodeNarrative: 'ETA calculator queued new estimate computation',
      reason: 'recalculate_eta',
      metricHint: _CourierBurstMetricHint.etaDrift,
    ),
    _CourierBurstStep(
      edgeId: 'e96',
      nodeId: 'widget_estimated_delivery_time',
      edgeNarrative: 'ETA calculator published estimate to ETA widget',
      nodeNarrative: 'ETA widget rendered refreshed delivery estimate',
      reason: 'publish_eta_to_ui',
      metricHint: _CourierBurstMetricHint.etaDrift,
    ),
    _CourierBurstStep(
      edgeId: 'e137',
      nodeId: 'widget_courier_details_card',
      edgeNarrative: 'Courier details card requested detail refresh',
      nodeNarrative: 'Courier details card reflected latest courier state',
      reason: 'refresh_courier_card',
      severity: UyavaSeverity.debug,
    ),
    _CourierBurstStep(
      edgeId: 'e138',
      nodeId: 'widget_order_status_stepper',
      edgeNarrative: 'Order status stepper synchronized with status cubit',
      nodeNarrative: 'Order status stepper advanced one visible stage',
      reason: 'advance_status_stepper',
    ),
    _CourierBurstStep(
      edgeId: 'e36',
      nodeId: 'widget_map_view',
      edgeNarrative: 'Map view requested overlay refresh from location data',
      nodeNarrative: 'Map view started location-overlay repaint cycle',
      reason: 'request_map_overlay_refresh',
      metricHint: _CourierBurstMetricHint.trackingGap,
      severity: UyavaSeverity.trace,
    ),
    _CourierBurstStep(
      edgeId: 'e37',
      nodeId: 'util_polyline_decoder',
      edgeNarrative: 'Location service pushed route points to polyline decoder',
      nodeNarrative: 'Polyline decoder generated smoother courier path',
      reason: 'decode_polyline_update',
      metricHint: _CourierBurstMetricHint.trackingGap,
      severity: UyavaSeverity.debug,
    ),
  ];

  static const List<_CourierBurstStep>
  _trackingSteadyScenario = <_CourierBurstStep>[
    _CourierBurstStep(
      edgeId: 'e35',
      nodeId: 'service_location',
      edgeNarrative: 'Order status cubit requested location refresh',
      nodeNarrative: 'Location service queued active-order refresh',
      reason: 'steady_refresh_location_state',
      metricHint: _CourierBurstMetricHint.trackingGap,
    ),
    _CourierBurstStep(
      edgeId: 'e94',
      nodeId: 'model_route',
      edgeNarrative: 'Location service recalculated route model',
      nodeNarrative: 'Route model recomputed from current courier position',
      reason: 'steady_recompute_route_geometry',
      metricHint: _CourierBurstMetricHint.trackingGap,
    ),
    _CourierBurstStep(
      edgeId: 'e95',
      nodeId: 'util_eta_calculator',
      edgeNarrative: 'Order status cubit triggered ETA recalculation',
      nodeNarrative: 'ETA calculator queued new estimate computation',
      reason: 'steady_recalculate_eta',
      metricHint: _CourierBurstMetricHint.etaDrift,
    ),
    _CourierBurstStep(
      edgeId: 'e96',
      nodeId: 'widget_estimated_delivery_time',
      edgeNarrative: 'ETA calculator published estimate to ETA widget',
      nodeNarrative: 'ETA widget rendered refreshed delivery estimate',
      reason: 'steady_publish_eta_to_ui',
      metricHint: _CourierBurstMetricHint.etaDrift,
    ),
    _CourierBurstStep(
      edgeId: 'e137',
      nodeId: 'widget_courier_details_card',
      edgeNarrative: 'Courier details card requested detail refresh',
      nodeNarrative: 'Courier details card reflected latest courier state',
      reason: 'steady_refresh_courier_card',
      severity: UyavaSeverity.debug,
    ),
    _CourierBurstStep(
      edgeId: 'e90',
      nodeId: 'repo_tracking',
      edgeNarrative: 'Tracking details cubit asked repository for snapshot',
      nodeNarrative: 'Tracking repository loaded latest courier frame',
      reason: 'steady_load_tracking_snapshot',
    ),
    _CourierBurstStep(
      edgeId: 'e92',
      nodeId: 'model_courier',
      edgeNarrative: 'Tracking repository wrote fresh courier model',
      nodeNarrative: 'Courier model updated from newest GPS point',
      reason: 'steady_refresh_courier_model',
      severity: UyavaSeverity.debug,
    ),
    _CourierBurstStep(
      edgeId: 'e138',
      nodeId: 'widget_order_status_stepper',
      edgeNarrative: 'Order status stepper synchronized with status cubit',
      nodeNarrative: 'Order status stepper advanced one visible stage',
      reason: 'steady_advance_status_stepper',
    ),
    _CourierBurstStep(
      edgeId: 'e36',
      nodeId: 'widget_map_view',
      edgeNarrative: 'Map view requested overlay refresh from location data',
      nodeNarrative: 'Map view started location-overlay repaint cycle',
      reason: 'steady_request_map_overlay_refresh',
      metricHint: _CourierBurstMetricHint.trackingGap,
      severity: UyavaSeverity.trace,
    ),
    _CourierBurstStep(
      edgeId: 'e37',
      nodeId: 'util_polyline_decoder',
      edgeNarrative: 'Location service pushed route points to polyline decoder',
      nodeNarrative: 'Polyline decoder generated smoother courier path',
      reason: 'steady_decode_polyline_update',
      metricHint: _CourierBurstMetricHint.trackingGap,
      severity: UyavaSeverity.debug,
    ),
  ];

  bool get _isCourierBurstRunning => _courierBurstTimer?.isActive ?? false;

  bool get _isCourierTrackingContextReady =>
      _nodeLabels.containsKey('screen_tracking') &&
      _nodeLabels.containsKey('service_location') &&
      _animatableEdgeIds.any((String id) => id == 'e33');

  int get _plannedCourierBurstTicks =>
      (_courierBurstDurationSeconds * _courierBurstEventsPerSecond)
          .round()
          .clamp(1, 400);

  Widget _buildCourierBurstTab() {
    final bool ready = _isCourierTrackingContextReady;
    final String status = _isCourierBurstRunning
        ? 'Running: ${_courierBurstTick + 1}/$_plannedCourierBurstTicks ticks'
        : (ready ? 'Ready' : 'Enable Real-time Tracking in the Features tab');

    return ListView(
      key: const ValueKey('courier-burst-list'),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Courier Live Burst',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Generates a dense, realistic tracking stream for 6-8 second demos: '
                  'one warm-up pass, then steady tracking updates without restarting from the first step.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text('Status: $status'),
                const SizedBox(height: 4),
                Text('Emitted events: $_courierBurstEventsEmitted'),
                if (_courierBurstLastSummary != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _courierBurstLastSummary!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Events per second: ${_courierBurstEventsPerSecond.toStringAsFixed(1)}',
                ),
                Slider(
                  key: const ValueKey('courier-burst-eps-slider'),
                  value: _courierBurstEventsPerSecond,
                  min: 2.0,
                  max: 20.0,
                  divisions: 36,
                  onChanged: _isCourierBurstRunning
                      ? null
                      : (double value) {
                          setState(() => _courierBurstEventsPerSecond = value);
                        },
                ),
                Text(
                  'Duration: ${_courierBurstDurationSeconds.toStringAsFixed(1)} s',
                ),
                Slider(
                  key: const ValueKey('courier-burst-duration-slider'),
                  value: _courierBurstDurationSeconds,
                  min: 3.0,
                  max: 10.0,
                  divisions: 28,
                  onChanged: _isCourierBurstRunning
                      ? null
                      : (double value) {
                          setState(() => _courierBurstDurationSeconds = value);
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _courierBurstIncludeMetrics,
                  onChanged: _isCourierBurstRunning
                      ? null
                      : (bool value) {
                          setState(() => _courierBurstIncludeMetrics = value);
                        },
                  title: const Text('Include tracking metrics'),
                  subtitle: const Text(
                    'Adds tracking_gap_seconds and eta_drift_seconds samples during the burst.',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      key: const ValueKey('courier-burst-start-button'),
                      onPressed: ready && !_isCourierBurstRunning
                          ? _startCourierBurst
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start burst'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('courier-burst-stop-button'),
                      onPressed: _isCourierBurstRunning
                          ? () => _stopCourierBurst()
                          : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop burst'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('courier-burst-preset-button'),
                      onPressed: _isCourierBurstRunning
                          ? null
                          : _applyCourierBurstPreset,
                      icon: const Icon(Icons.tune),
                      label: const Text('Use 7s preset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _applyCourierBurstPreset() {
    setState(() {
      _courierBurstEventsPerSecond = 8.0;
      _courierBurstDurationSeconds = 7.0;
      _courierBurstIncludeMetrics = true;
    });
  }

  void _startCourierBurst() {
    if (_isCourierBurstRunning) return;
    if (!_isCourierTrackingContextReady) {
      _showSnack(
        'Enable the Real-time Tracking feature before starting burst.',
      );
      return;
    }

    final int intervalMs = (1000 / _courierBurstEventsPerSecond).round().clamp(
      50,
      1000,
    );
    final int targetTicks = _plannedCourierBurstTicks;

    setState(() {
      _courierBurstTick = 0;
      _courierBurstEventsEmitted = 0;
      _courierBurstLastSummary = null;
    });

    _courierBurstTimer = Timer.periodic(Duration(milliseconds: intervalMs), (
      Timer timer,
    ) {
      final bool emitted = _emitCourierBurstStep();
      _courierBurstTick += 1;
      if (!emitted || _courierBurstTick >= targetTicks) {
        _stopCourierBurst(completed: emitted);
      } else if (mounted) {
        setState(() {});
      }
    });
    setState(() {});
  }

  bool _emitCourierBurstStep() {
    final _CourierBurstSelection? selection = _resolveCourierBurstSelection();
    if (selection == null) {
      return false;
    }
    final _CourierBurstStep step = selection.step;
    final int sequence = _courierBurstTick + 1;
    final String phaseLabel = _phaseLabel(selection.phase);
    final String phaseProgress =
        '${selection.phaseIndex + 1}/${selection.phaseTotal}';
    final String edgeLabel = _edgeLabels[step.edgeId] ?? step.edgeId;
    final String nodeLabel = _nodeLabels[step.nodeId] ?? step.nodeId;
    final Map<String, dynamic> burstPayload = <String, dynamic>{
      'flow': 'courier_live_burst',
      'phase': selection.phase.name,
      'phaseStep': selection.phaseIndex + 1,
      'phaseTotal': selection.phaseTotal,
      'globalTick': sequence,
      'reason': step.reason,
      'edge': <String, dynamic>{'id': step.edgeId, 'label': edgeLabel},
      'node': <String, dynamic>{'id': step.nodeId, 'label': nodeLabel},
    };

    Uyava.emitEdgeEvent(
      edge: step.edgeId,
      message:
          '[Courier Burst][$phaseLabel $phaseProgress] ${step.edgeNarrative} ($edgeLabel)',
      severity: step.severity,
    );
    Uyava.emitNodeEvent(
      nodeId: step.nodeId,
      message:
          '[Courier Burst][$phaseLabel $phaseProgress] ${step.nodeNarrative} ($nodeLabel)',
      severity: step.severity,
      payload: <String, dynamic>{'burst': burstPayload},
    );
    _courierBurstEventsEmitted += 2;

    if (_courierBurstIncludeMetrics && sequence.isEven) {
      _emitCourierBurstMetricSample(selection: selection);
    }
    return true;
  }

  _CourierBurstSelection? _resolveCourierBurstSelection() {
    if (_courierBurstTick < _trackingWarmupScenario.length) {
      final _CourierBurstStep step = _trackingWarmupScenario[_courierBurstTick];
      if (!_edgeLabels.containsKey(step.edgeId) ||
          !_nodeLabels.containsKey(step.nodeId)) {
        return null;
      }
      return _CourierBurstSelection(
        step: step,
        phase: _CourierBurstPhase.warmup,
        phaseIndex: _courierBurstTick,
        phaseTotal: _trackingWarmupScenario.length,
      );
    }

    if (_trackingSteadyScenario.isEmpty) {
      return null;
    }
    final int steadyTick = _courierBurstTick - _trackingWarmupScenario.length;
    final int steadyIndex = steadyTick % _trackingSteadyScenario.length;
    final _CourierBurstStep step = _trackingSteadyScenario[steadyIndex];
    if (!_edgeLabels.containsKey(step.edgeId) ||
        !_nodeLabels.containsKey(step.nodeId)) {
      return null;
    }
    return _CourierBurstSelection(
      step: step,
      phase: _CourierBurstPhase.steady,
      phaseIndex: steadyIndex,
      phaseTotal: _trackingSteadyScenario.length,
    );
  }

  void _emitCourierBurstMetricSample({
    required _CourierBurstSelection selection,
  }) {
    final _CourierBurstMetricHint hint = selection.step.metricHint;
    final bool emitEta = hint == _CourierBurstMetricHint.etaDrift
        ? true
        : (hint == _CourierBurstMetricHint.trackingGap
              ? false
              : _rng.nextBool());
    final String metricId = emitEta
        ? 'eta_drift_seconds'
        : 'tracking_gap_seconds';
    final String nodeId = emitEta ? 'util_eta_calculator' : 'service_location';
    if (!_registeredMetrics.containsKey(metricId) ||
        !_nodeLabels.containsKey(nodeId)) {
      return;
    }

    final double value = emitEta
        ? double.parse(_randomRange(_rng, 12, 180).toStringAsFixed(0))
        : double.parse(_randomRange(_rng, 0.05, 3.2).toStringAsFixed(2));
    final UyavaSeverity severity = emitEta
        ? (value >= 120 ? UyavaSeverity.warn : UyavaSeverity.info)
        : (value >= 2.2 ? UyavaSeverity.warn : UyavaSeverity.debug);
    final String unit = emitEta ? 's' : 's';
    final String phaseLabel = _phaseLabel(selection.phase);
    final String phaseProgress =
        '${selection.phaseIndex + 1}/${selection.phaseTotal}';
    final String metricLabel = emitEta
        ? 'ETA drift recalculated'
        : 'Tracking update gap sampled';
    final Map<String, dynamic> burstPayload = <String, dynamic>{
      'flow': 'courier_live_burst',
      'phase': selection.phase.name,
      'phaseStep': selection.phaseIndex + 1,
      'phaseTotal': selection.phaseTotal,
      'globalTick': _courierBurstTick + 1,
      'reason': selection.step.reason,
    };

    Uyava.emitNodeEvent(
      nodeId: nodeId,
      message:
          '[Courier Burst][$phaseLabel $phaseProgress] $metricLabel: $value$unit (${selection.step.reason})',
      severity: severity,
      payload: <String, dynamic>{
        'burst': burstPayload,
        'metric': <String, dynamic>{
          'id': metricId,
          'value': value,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'severity': severity.name,
        },
      },
    );
    _courierBurstEventsEmitted += 1;
  }

  String _phaseLabel(_CourierBurstPhase phase) {
    switch (phase) {
      case _CourierBurstPhase.warmup:
        return 'Warm-up';
      case _CourierBurstPhase.steady:
        return 'Steady';
    }
  }

  void _stopCourierBurst({bool completed = false, bool silent = false}) {
    final Timer? activeTimer = _courierBurstTimer;
    _courierBurstTimer?.cancel();
    _courierBurstTimer = null;

    if (completed) {
      _courierBurstLastSummary =
          'Completed $_courierBurstTick ticks and emitted $_courierBurstEventsEmitted events.';
      if (!silent) {
        _showSnack('Courier burst completed.');
      }
    } else if (!silent && activeTimer != null) {
      _showSnack('Courier burst stopped.');
    }

    if (mounted && !silent) {
      setState(() {});
    }
  }
}
