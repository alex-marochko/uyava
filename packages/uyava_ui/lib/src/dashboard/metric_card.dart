part of 'metrics_dashboard.dart';

const MetricCardViewModel _metricCardViewModel = MetricCardViewModel();

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.data,
    required this.compactMode,
    required this.onReset,
    required this.onPinToggle,
  });

  final MetricCardViewData data;
  final bool compactMode;
  final VoidCallback onReset;
  final VoidCallback onPinToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MetricCardState state = _metricCardViewModel.build(data);
    final Color cardColor = theme.colorScheme.surfaceContainerHighest;
    final Color borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.7 : 0.55,
    );

    final List<Widget> actions = <Widget>[
      Tooltip(
        message: state.pinned ? 'Unpin metric' : 'Pin metric',
        waitDuration: const Duration(milliseconds: 300),
        child: IconButton(
          icon: const Icon(Icons.push_pin_outlined),
          selectedIcon: const Icon(Icons.push_pin),
          iconSize: 18,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          splashRadius: 16,
          visualDensity: VisualDensity.compact,
          isSelected: state.pinned,
          onPressed: onPinToggle,
        ),
      ),
      if (state.hasInfo)
        Tooltip(
          message: state.infoTooltip,
          waitDuration: const Duration(milliseconds: 300),
          child: IconButton(
            icon: const Icon(Icons.help_outline),
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            splashRadius: 16,
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                _showMetricDetails(context, state.title, state.infoTooltip),
          ),
        ),
      Tooltip(
        message: 'Reset history',
        waitDuration: const Duration(milliseconds: 300),
        child: IconButton(
          icon: const Icon(Icons.refresh),
          iconSize: 18,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          splashRadius: 16,
          visualDensity: VisualDensity.compact,
          onPressed: state.canReset ? onReset : null,
        ),
      ),
    ];

    return Card(
      color: cardColor,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricCardHeader(
              title: state.title,
              id: state.id,
              actions: actions,
            ),
            if (compactMode)
              _CompactAggregateList(aggregates: state.aggregates)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final MetricAggregateState aggregate
                        in state.aggregates)
                      _MetricAggregateChip(aggregate: aggregate),
                  ],
                ),
              ),
            if (!compactMode)
              state.hasSparkline
                  ? SizedBox(
                      height: 80,
                      child: _MetricSparkline(
                        key: ValueKey<String>('sparkline-${state.id}'),
                        values: state.sparklineValues,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _SparklinePlaceholder(
                      color: theme.colorScheme.surfaceContainerHighest,
                      text: state.sparklinePlaceholder,
                    ),
            const SizedBox(height: 12),
            _MetricFooter(
              samplesLabel: state.samplesLabel,
              timestampLabel: state.timestampLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCardHeader extends StatelessWidget {
  const _MetricCardHeader({
    required this.title,
    required this.id,
    required this.actions,
  });

  final String title;
  final String id;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                id,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(spacing: 2, runSpacing: 2, children: actions),
          ],
        ),
      ],
    );
  }
}

class _CompactAggregateList extends StatelessWidget {
  const _CompactAggregateList({required this.aggregates});

  final List<MetricAggregateState> aggregates;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle labelStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    final TextStyle valueBaseStyle =
        theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    return Column(
      children: [
        for (final MetricAggregateState aggregate in aggregates)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(child: Text('${aggregate.label}:', style: labelStyle)),
                const SizedBox(width: 8),
                Text(
                  aggregate.valueText,
                  style: aggregate.tintable && aggregate.severity != null
                      ? valueBaseStyle.copyWith(
                          color: colorForSeverity(aggregate.severity!),
                        )
                      : valueBaseStyle,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetricAggregateChip extends StatelessWidget {
  const _MetricAggregateChip({required this.aggregate});

  final MetricAggregateState aggregate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool tintable = aggregate.tintable && aggregate.severity != null;
    final Color backgroundColor = tintable
        ? _severityChipColor(theme, aggregate.severity!)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final Color borderColor = tintable
        ? _severityChipBorderColor(theme, aggregate.severity!)
        : theme.colorScheme.outline.withValues(alpha: 0.3);
    final TextStyle? valueStyle = tintable
        ? theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          )
        : theme.textTheme.titleMedium;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            aggregate.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(aggregate.valueText, style: valueStyle),
        ],
      ),
    );
  }
}

class _MetricFooter extends StatelessWidget {
  const _MetricFooter({
    required this.samplesLabel,
    required this.timestampLabel,
  });

  final String samplesLabel;
  final String? timestampLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? samplesStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Expanded(child: Text(samplesLabel, style: samplesStyle)),
        if (timestampLabel != null) Text(timestampLabel!, style: samplesStyle),
      ],
    );
  }
}

class _MetricSparkline extends StatelessWidget {
  const _MetricSparkline({
    super.key,
    required this.values,
    required this.color,
  });

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SparklinePainter(values: values, color: color),
      size: Size.infinite,
    );
  }
}

class _SparklinePlaceholder extends StatelessWidget {
  const _SparklinePlaceholder({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      height: 60,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }
}

Color _severityChipColor(ThemeData theme, UyavaSeverity severity) {
  final Color surface = theme.colorScheme.surfaceContainerHighest;
  final double overlayAlpha = theme.brightness == Brightness.dark ? 0.45 : 0.3;
  return Color.alphaBlend(
    colorForSeverity(severity).withValues(alpha: overlayAlpha),
    surface,
  );
}

Color _severityChipBorderColor(ThemeData theme, UyavaSeverity severity) {
  final Color outline = theme.colorScheme.outline;
  final double overlayAlpha = theme.brightness == Brightness.dark ? 0.6 : 0.4;
  return Color.alphaBlend(
    colorForSeverity(severity).withValues(alpha: overlayAlpha),
    outline,
  );
}

void _showMetricDetails(
  BuildContext context,
  String title,
  String tooltipText,
) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SelectableText(tooltipText),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
