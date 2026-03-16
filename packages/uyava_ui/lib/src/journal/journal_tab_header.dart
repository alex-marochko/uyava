part of 'journal_toolbar.dart';

class GraphJournalTabBar extends StatelessWidget {
  const GraphJournalTabBar({
    super.key,
    required this.controller,
    required this.eventsCount,
    this.totalEventsCount,
    required this.diagnosticsAttentionCount,
    required this.warnCount,
    required this.criticalCount,
    this.totalWarnCount,
    this.totalCriticalCount,
    this.hasActiveFilters = false,
  });

  final TabController controller;
  final int eventsCount;
  final int? totalEventsCount;
  final int diagnosticsAttentionCount;
  final int warnCount;
  final int criticalCount;
  final int? totalWarnCount;
  final int? totalCriticalCount;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final bool useTotals = !hasActiveFilters;
    final int displayEventsCount = useTotals && totalEventsCount != null
        ? totalEventsCount!
        : eventsCount;
    final int displayWarnCount = useTotals && totalWarnCount != null
        ? totalWarnCount!
        : warnCount;
    final int displayCriticalCount = useTotals && totalCriticalCount != null
        ? totalCriticalCount!
        : criticalCount;
    final String diagnosticsLabel = diagnosticsAttentionCount > 0
        ? 'Diagnostics ($diagnosticsAttentionCount)'
        : 'Diagnostics';

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelStyle: labelStyle,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      indicatorPadding: EdgeInsets.zero,
      indicatorSize: TabBarIndicatorSize.label,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      dividerColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicator: BoxDecoration(
        border: Border(bottom: BorderSide(width: 2, color: scheme.primary)),
      ),
      tabs: [
        Tab(
          child: _EventsTabLabel(
            eventsCount: displayEventsCount,
            warnCount: displayWarnCount,
            criticalCount: displayCriticalCount,
          ),
        ),
        Tab(text: diagnosticsLabel),
      ],
    );
  }
}

class _EventsTabLabel extends StatelessWidget {
  const _EventsTabLabel({
    required this.eventsCount,
    required this.warnCount,
    required this.criticalCount,
  });

  final int eventsCount;
  final int warnCount;
  final int criticalCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base = DefaultTextStyle.of(context).style;
    final TextStyle numericStyle = base.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final Color warningColor = colorForSeverity(UyavaSeverity.warn);
    final Color criticalColor = theme.colorScheme.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Events ($eventsCount)', style: numericStyle),
        const SizedBox(width: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('('),
            _SeverityCountSummary(
              icon: Icons.warning_amber_rounded,
              color: warningColor,
              count: warnCount,
              style: numericStyle.copyWith(color: warningColor),
            ),
            const Text(' · '),
            _SeverityCountSummary(
              icon: Icons.error_outline,
              color: criticalColor,
              count: criticalCount,
              style: numericStyle.copyWith(color: criticalColor),
            ),
            const Text(')'),
          ],
        ),
      ],
    );
  }
}

class _SeverityCountSummary extends StatelessWidget {
  const _SeverityCountSummary({
    required this.icon,
    required this.color,
    required this.count,
    required this.style,
  });

  final IconData icon;
  final Color color;
  final int count;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text('$count', style: style),
      ],
    );
  }
}
