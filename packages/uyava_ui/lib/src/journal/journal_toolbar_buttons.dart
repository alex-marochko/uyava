part of 'journal_toolbar.dart';

class _JournalToolbarDivider extends StatelessWidget {
  const _JournalToolbarDivider();

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.6);
    return Container(
      height: 26,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
    );
  }
}

class _JournalGraphFilterButton extends StatelessWidget {
  const _JournalGraphFilterButton({
    required this.respectsGraphFilter,
    required this.onPressed,
    this.disabledTooltip,
  });

  final bool respectsGraphFilter;
  final VoidCallback? onPressed;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.7);
    return Tooltip(
      message: onPressed == null
          ? (disabledTooltip ?? 'Requires Pro')
          : (respectsGraphFilter
                ? 'Journal follows primary graph filter'
                : 'Journal ignores primary graph filter'),
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: respectsGraphFilter
              ? scheme.primary
              : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          foregroundColor: respectsGraphFilter
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
          minimumSize: _kJournalToolbarButtonSize,
          padding: _kJournalToolbarButtonPadding,
          side: BorderSide(
            color: respectsGraphFilter ? Colors.transparent : borderColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.timeline, size: 18),
      ),
    );
  }
}

class _JournalRawToggleButton extends StatelessWidget {
  const _JournalRawToggleButton({
    super.key,
    required this.isEventsTab,
    required this.isActive,
    required this.onPressed,
    this.disabledTooltip,
  });

  final bool isEventsTab;
  final bool isActive;
  final VoidCallback? onPressed;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.7);
    final Color background = isActive
        ? scheme.primary
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final Color foreground = isActive
        ? scheme.onPrimary
        : scheme.onSurfaceVariant;
    final String tooltip = onPressed == null
        ? (disabledTooltip ?? 'Requires Pro')
        : (isEventsTab
              ? 'Show event details'
              : (isActive
                    ? 'Show formatted diagnostics'
                    : 'Show raw diagnostic JSON'));

    return Container(
      margin: const EdgeInsets.only(right: 2),
      child: IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: _kJournalToolbarButtonSize,
          padding: _kJournalToolbarButtonPadding,
          side: BorderSide(
            color: isActive ? Colors.transparent : borderColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.data_object, size: 18),
      ),
    );
  }
}

class _AutoScrollButton extends StatelessWidget {
  const _AutoScrollButton({
    required this.isEventsTab,
    required this.enabled,
    required this.onPressed,
    this.disabledTooltip,
  });

  final bool isEventsTab;
  final bool enabled;
  final VoidCallback? onPressed;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.7);
    final Color background = enabled
        ? scheme.primary
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final Color foreground = enabled
        ? scheme.onPrimary
        : scheme.onSurfaceVariant;
    final String tooltip = onPressed == null
        ? (disabledTooltip ?? 'Requires Pro')
        : (enabled
              ? 'Disable auto-scroll'
              : 'Jump to latest and enable auto-scroll');

    return Container(
      margin: const EdgeInsets.only(left: 2),
      child: IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: _kJournalToolbarButtonSize,
          padding: _kJournalToolbarButtonPadding,
          side: BorderSide(
            color: enabled ? Colors.transparent : borderColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(Icons.arrow_downward, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}

class _CopyLogButton extends StatelessWidget {
  const _CopyLogButton({
    required this.enabled,
    required this.onPressed,
    this.disabledTooltip,
  });

  final bool enabled;
  final VoidCallback? onPressed;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.7);
    final Color background = enabled
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final Color foreground = enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurfaceVariant.withValues(alpha: 0.5);

    return IconButton(
      tooltip: enabled
          ? 'Copy current tab'
          : (disabledTooltip ?? 'Requires Pro'),
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: _kJournalToolbarButtonSize,
        padding: _kJournalToolbarButtonPadding,
        side: BorderSide(
          color: enabled ? borderColor : borderColor.withValues(alpha: 0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: const Icon(Icons.copy_all_outlined, size: 18),
      onPressed: onPressed,
    );
  }
}

class _ClearLogButton extends StatelessWidget {
  const _ClearLogButton({
    required this.enabled,
    required this.onPressed,
    this.disabledTooltip,
  });

  final bool enabled;
  final VoidCallback? onPressed;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.7);
    final Color background = enabled
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
        : scheme.surface.withValues(alpha: 0.35);
    final Color foreground = enabled
        ? scheme.onSurface
        : scheme.onSurfaceVariant.withValues(alpha: 0.7);
    return IconButton(
      tooltip: enabled ? 'Clear log' : (disabledTooltip ?? 'Requires Pro'),
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: _kJournalToolbarButtonSize,
        padding: _kJournalToolbarButtonPadding,
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline, size: 18),
    );
  }
}
