part of 'package:uyava_example/main.dart';

mixin _MetricsTabMixin on _ExampleAppStateBase, _MetricsLogicMixin {
  Widget _buildMetricsTab() {
    final theme = Theme.of(context);
    final List<DropdownMenuItem<String>> nodeItems = _eventableNodeIds
        .map(
          (id) => DropdownMenuItem<String>(
            value: id,
            child: Text(_nodeLabels[id] ?? id),
          ),
        )
        .toList(growable: false);
    final bool hasNodes = nodeItems.isNotEmpty;
    final Iterable<_RegisteredMetric> registered = _registeredMetrics.values;

    return ListView(
      key: const ValueKey('metrics-list'),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Register metric', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _metricIdController,
                  decoration: const InputDecoration(
                    labelText: 'Metric id',
                    hintText: 'e.g. latency',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _metricLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (optional)',
                    hintText: 'Latency (ms)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _metricDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _metricUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit (optional)',
                    hintText: 'ms, req/s, ...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _metricTagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'perf, backend',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Aggregators', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final aggregator in UyavaMetricAggregator.values)
                      FilterChip(
                        label: Text(_metricAggregatorLabel(aggregator)),
                        selected: _selectedAggregators.contains(aggregator),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAggregators.add(aggregator);
                            } else if (_selectedAggregators.length > 1) {
                              _selectedAggregators.remove(aggregator);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    key: const ValueKey('register-metric-button'),
                    onPressed: _registerMetric,
                    icon: const Icon(Icons.library_add_check_outlined),
                    label: const Text('Register metric'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emit metric sample', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                if (_registeredMetrics.isEmpty) ...[
                  Text(
                    'No metrics',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  DropdownButtonFormField<String>(
                    initialValue:
                        _registeredMetrics.containsKey(
                          _sampleMetricIdController.text.trim(),
                        )
                        ? _sampleMetricIdController.text.trim()
                        : null,
                    items: _registeredMetrics.keys
                        .map(
                          (id) => DropdownMenuItem<String>(
                            value: id,
                            child: Text(_registeredMetrics[id]?.label ?? id),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _sampleMetricIdController.text = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Registered metric',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _sampleMetricIdController,
                  decoration: const InputDecoration(
                    labelText: 'Metric id',
                    hintText: 'latency',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sampleValueController,
                  decoration: const InputDecoration(
                    labelText: 'Metric value',
                    hintText: 'e.g. 24.5',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _metricSampleSeverity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: UyavaSeverity.values
                      .map(
                        (severity) => DropdownMenuItem<String>(
                          value: severity.name,
                          child: Text(_severityLabel(severity)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _metricSampleSeverity = value);
                  },
                ),
                const SizedBox(height: 12),
                if (!hasNodes)
                  Text(
                    'Enable at least one feature to target a node.',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMetricNodeId,
                    items: nodeItems,
                    onChanged: (value) {
                      setState(() => _selectedMetricNodeId = value);
                    },
                    decoration: const InputDecoration(labelText: 'Target node'),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    key: const ValueKey('send-metric-sample-button'),
                    onPressed: hasNodes ? _emitMetricSample : null,
                    icon: const Icon(Icons.trending_up_outlined),
                    label: const Text('Send sample'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (registered.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registered metrics',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final metric in registered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMetricSummaryTile(metric),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricSummaryTile(_RegisteredMetric metric) {
    final theme = Theme.of(context);
    final String displayTitle = metric.label ?? metric.id;
    final String aggregatorSummary = metric.aggregators
        .map(_metricAggregatorLabel)
        .join(', ');
    final List<Widget> subtitleLines = <Widget>[
      Text('Aggregators: $aggregatorSummary'),
    ];
    if (metric.unit != null && metric.unit!.isNotEmpty) {
      subtitleLines.add(
        Text('Unit: ${metric.unit}', style: theme.textTheme.bodySmall),
      );
    }
    if (metric.description != null && metric.description!.isNotEmpty) {
      subtitleLines.add(
        Text(metric.description!, style: theme.textTheme.bodySmall),
      );
    }
    if (metric.tags.isNotEmpty) {
      subtitleLines.add(
        Text(
          'Tags: ${metric.tags.join(', ')}',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(displayTitle, style: theme.textTheme.titleSmall),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtitleLines,
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
