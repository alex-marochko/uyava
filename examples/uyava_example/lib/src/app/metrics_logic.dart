part of 'package:uyava_example/main.dart';

mixin _MetricsLogicMixin on _ExampleAppStateBase {
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

  Map<String, List<_MetricTemplate>> _buildDefaultFeatureMetrics() {
    double roundTo(double value, int digits) =>
        double.parse(value.toStringAsFixed(digits));

    return <String, List<_MetricTemplate>>{
      'Authentication': [
        _MetricTemplate(
          id: 'auth_login_latency_ms',
          label: 'Login Latency',
          unit: 'ms',
          description: 'Round-trip time for the login flow',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.min,
            UyavaMetricAggregator.max,
            UyavaMetricAggregator.sum,
            UyavaMetricAggregator.count,
          ],
          tags: const [
            'feature-authentication',
            'auth',
            'metric-login-latency',
          ],
          sample: (rng) => roundTo(_randomRange(rng, 120, 420), 1),
        ),
        _MetricTemplate(
          id: 'auth_login_success_rate_pct',
          label: 'Login Success Rate',
          unit: '%',
          description: 'Successful logins within the last interval',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.min,
            UyavaMetricAggregator.max,
          ],
          tags: const ['feature-authentication', 'auth'],
          sample: (rng) => roundTo(_randomRange(rng, 92.0, 99.5), 2),
        ),
      ],
      'Restaurant Feed': [
        _MetricTemplate(
          id: 'feed_fetch_latency_ms',
          label: 'Feed Fetch Latency',
          unit: 'ms',
          description: 'Network latency for home feed requests',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.min,
            UyavaMetricAggregator.max,
            UyavaMetricAggregator.sum,
            UyavaMetricAggregator.count,
          ],
          tags: const ['feature-restaurant-feed', 'restaurants', 'feed'],
          sample: (rng) => roundTo(_randomRange(rng, 80, 240), 1),
        ),
        _MetricTemplate(
          id: 'feed_items_per_fetch',
          label: 'Items per Fetch',
          description: 'Number of restaurants returned per request',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.min,
            UyavaMetricAggregator.max,
            UyavaMetricAggregator.sum,
            UyavaMetricAggregator.count,
          ],
          tags: const ['feature-restaurant-feed', 'restaurants', 'feed'],
          sample: (rng) => _randomRange(rng, 12, 36).roundToDouble(),
        ),
      ],
      'Order & Checkout': [
        _MetricTemplate(
          id: 'checkout_duration_ms',
          label: 'Checkout Duration',
          unit: 'ms',
          description: 'Elapsed time from cart review to payment confirmation',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.min,
            UyavaMetricAggregator.max,
            UyavaMetricAggregator.sum,
            UyavaMetricAggregator.count,
          ],
          tags: const ['feature-order-checkout', 'orders', 'checkout'],
          sample: (rng) => roundTo(_randomRange(rng, 1500, 4200), 0),
        ),
        _MetricTemplate(
          id: 'payment_success_rate_pct',
          label: 'Payment Success Rate',
          unit: '%',
          description: 'Share of successful payments in the last batch',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.min,
            UyavaMetricAggregator.max,
          ],
          tags: const ['feature-order-checkout', 'orders', 'checkout'],
          sample: (rng) => roundTo(_randomRange(rng, 94.5, 99.2), 2),
        ),
      ],
      'Profile & Settings': [
        _MetricTemplate(
          id: 'profile_save_latency_ms',
          label: 'Profile Save Latency',
          unit: 'ms',
          description: 'Time to persist updated profile settings',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.min,
            UyavaMetricAggregator.max,
            UyavaMetricAggregator.sum,
            UyavaMetricAggregator.count,
          ],
          tags: const ['feature-profile-settings', 'profile', 'settings'],
          sample: (rng) => roundTo(_randomRange(rng, 90, 260), 1),
        ),
      ],
      'Real-time Tracking': [
        _MetricTemplate(
          id: 'tracking_gap_seconds',
          label: 'Tracking Gap',
          unit: 's',
          description: 'Largest gap between position updates',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.max,
          ],
          tags: const ['feature-real-time-tracking', 'tracking', 'realtime'],
          sample: (rng) => roundTo(_randomRange(rng, 0.0, 3.5), 2),
        ),
        _MetricTemplate(
          id: 'eta_drift_seconds',
          label: 'ETA Drift',
          unit: 's',
          description: 'Absolute delta between predicted and actual ETA',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.max,
          ],
          tags: const ['feature-real-time-tracking', 'tracking', 'realtime'],
          sample: (rng) => roundTo(_randomRange(rng, 10, 180), 0),
        ),
      ],
      'Customer Support': [
        _MetricTemplate(
          id: 'support_response_latency_sec',
          label: 'First Response Latency',
          unit: 's',
          description: 'Time until an agent replies in chat',
          aggregators: const [
            UyavaMetricAggregator.last,
            UyavaMetricAggregator.min,
            UyavaMetricAggregator.max,
            UyavaMetricAggregator.sum,
            UyavaMetricAggregator.count,
          ],
          tags: const ['feature-customer-support', 'support', 'chat'],
          sample: (rng) => roundTo(_randomRange(rng, 5, 45), 1),
        ),
      ],
    };
  }

  void _initializeDefaultMetrics() {
    if (_defaultFeatureMetrics.isEmpty) {
      return;
    }
    for (final entry in _defaultFeatureMetrics.entries) {
      for (final _MetricTemplate template in entry.value) {
        Uyava.defineMetric(
          id: template.id,
          label: template.label,
          description: template.description,
          unit: template.unit,
          tags: template.tags.isNotEmpty ? template.tags : null,
          aggregators: template.aggregators,
        );
        _registeredMetrics[template.id] = _RegisteredMetric(
          id: template.id,
          label: template.label,
          description: template.description,
          unit: template.unit,
          aggregators: template.aggregators,
          tags: template.tags,
        );
      }
    }
    if (_registeredMetrics.isNotEmpty &&
        _sampleMetricIdController.text.trim().isEmpty) {
      _sampleMetricIdController.text = _registeredMetrics.keys.first;
    }
  }

  void _emitAutomaticMetricSample() {
    if (_registeredMetrics.isEmpty) return;
    if (_rng.nextDouble() < 0.35) {
      return;
    }
    final List<String> enabledFeatures = _features.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .where(
          (feature) => _defaultFeatureMetrics[feature]?.isNotEmpty ?? false,
        )
        .toList(growable: false);
    if (enabledFeatures.isEmpty) {
      return;
    }
    final String feature =
        enabledFeatures[_rng.nextInt(enabledFeatures.length)];
    final List<_MetricTemplate>? templates = _defaultFeatureMetrics[feature];
    if (templates == null || templates.isEmpty) {
      return;
    }
    final _MetricTemplate template = templates[_rng.nextInt(templates.length)];
    if (!_registeredMetrics.containsKey(template.id)) {
      return;
    }
    final String? preferredNodeId = _featureMetricNodeTargets[feature];
    String? nodeId =
        (preferredNodeId != null && _nodeLabels.containsKey(preferredNodeId))
        ? preferredNodeId
        : null;
    nodeId ??= _eventableNodeIds.isNotEmpty ? _eventableNodeIds.first : null;
    if (nodeId == null) {
      return;
    }
    final double value = template.sample(_rng);
    final UyavaSeverity severity = _pickAutomaticSeverity();
    final String formattedValue = value.toStringAsFixed(2);
    final String unitLabel = (template.unit == null || template.unit!.isEmpty)
        ? ''
        : ' ${template.unit}';
    final String eventMessage =
        '${template.label} reported $formattedValue$unitLabel while $feature was active';
    Uyava.emitNodeEvent(
      nodeId: nodeId,
      message: eventMessage,
      severity: severity,
      payload: <String, dynamic>{
        'metric': <String, dynamic>{
          'id': template.id,
          'value': value,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'severity': severity.name,
        },
      },
    );
  }

  UyavaSeverity _pickAutomaticSeverity() {
    final double roll = _rng.nextDouble();
    if (roll < 0.15) return UyavaSeverity.trace;
    if (roll < 0.3) return UyavaSeverity.debug;
    if (roll < 0.65) return UyavaSeverity.info;
    if (roll < 0.85) return UyavaSeverity.warn;
    if (roll < 0.95) return UyavaSeverity.error;
    return UyavaSeverity.fatal;
  }

  double _randomRange(math.Random rng, double min, double max) =>
      min + rng.nextDouble() * (max - min);

  void _registerMetric() {
    final String id = _metricIdController.text.trim();
    if (id.isEmpty) {
      _showSnack('Metric id is required');
      return;
    }
    if (_selectedAggregators.isEmpty) {
      _showSnack('Select at least one aggregator');
      return;
    }

    final String label = _metricLabelController.text.trim();
    final String description = _metricDescriptionController.text.trim();
    final String unit = _metricUnitController.text.trim();
    final List<String> tags = _metricTagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    try {
      Uyava.defineMetric(
        id: id,
        label: label.isNotEmpty ? label : null,
        description: description.isNotEmpty ? description : null,
        unit: unit.isNotEmpty ? unit : null,
        tags: tags.isNotEmpty ? tags : null,
        aggregators: _selectedAggregators.toList(),
      );
      setState(() {
        _registeredMetrics[id] = _RegisteredMetric(
          id: id,
          label: label.isNotEmpty ? label : null,
          description: description.isNotEmpty ? description : null,
          unit: unit.isNotEmpty ? unit : null,
          tags: tags,
          aggregators: _selectedAggregators.toList(),
        );
      });
      if (_sampleMetricIdController.text.trim().isEmpty) {
        _sampleMetricIdController.text = id;
      }
      _showSnack('Registered metric "$id"');
    } catch (error) {
      _showSnack('Failed to register metric: $error');
    }
  }

  void _emitMetricSample() {
    final String metricId = _sampleMetricIdController.text.trim();
    if (metricId.isEmpty) {
      _showSnack('Metric id is required to emit a sample');
      return;
    }
    final String valueText = _sampleValueController.text.trim();
    final double? value = double.tryParse(valueText);
    if (value == null) {
      _showSnack('Metric value must be a number');
      return;
    }
    final String? nodeId = _selectedMetricNodeId;
    if (nodeId == null) {
      _showSnack('Select a target node for the metric sample');
      return;
    }

    final String displayValue = value.toStringAsFixed(2);
    final _RegisteredMetric? metricMeta = _registeredMetrics[metricId];
    final String? metaUnit = metricMeta?.unit;
    final String unitLabel = (metaUnit == null || metaUnit.isEmpty)
        ? ''
        : ' $metaUnit';
    final Map<String, dynamic> metricPayload = <String, dynamic>{
      'id': metricId,
      'value': value,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    final UyavaSeverity? severity = _severityFromName(_metricSampleSeverity);
    if (severity != null) {
      metricPayload['severity'] = severity.name;
    }

    Uyava.emitNodeEvent(
      nodeId: nodeId,
      message:
          'Manual $metricId sample is $displayValue$unitLabel on ${_nodeLabels[nodeId] ?? nodeId}',
      severity: severity,
      payload: <String, dynamic>{'metric': metricPayload},
    );

    _showSnack('Emitted $displayValue for metric "$metricId"');
  }
}
