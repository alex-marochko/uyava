import 'package:flutter/material.dart';

class FiltersButtonGroupEntry {
  const FiltersButtonGroupEntry({
    required this.label,
    this.onPressed,
    this.tooltip,
    this.selected = false,
    this.enabled = true,
    this.highlightSelection = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool selected;
  final bool enabled;
  final bool highlightSelection;
}

class FiltersButtonGroup extends StatelessWidget {
  const FiltersButtonGroup({super.key, required this.entries});

  final List<FiltersButtonGroupEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final Color borderColor = theme.colorScheme.outlineVariant;
    final BorderRadius baseRadius = BorderRadius.circular(6);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: baseRadius,
          side: BorderSide(color: borderColor),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < entries.length; i++) ...[
              if (i != 0)
                Container(width: 1, color: borderColor.withValues(alpha: 0.6)),
              _FiltersButtonGroupSegment(
                entry: entries[i],
                radius: BorderRadius.only(
                  topLeft: i == 0 ? baseRadius.topLeft : Radius.zero,
                  bottomLeft: i == 0 ? baseRadius.bottomLeft : Radius.zero,
                  topRight: i == entries.length - 1
                      ? baseRadius.topRight
                      : Radius.zero,
                  bottomRight: i == entries.length - 1
                      ? baseRadius.bottomRight
                      : Radius.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FiltersButtonGroupSegment extends StatelessWidget {
  const _FiltersButtonGroupSegment({required this.entry, required this.radius});

  final FiltersButtonGroupEntry entry;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle baseStyle =
        theme.textTheme.labelSmall ??
        theme.textTheme.bodySmall ??
        const TextStyle(fontSize: 12);
    final bool enabled = entry.enabled && entry.onPressed != null;
    Color foreground;
    Color background;
    if (!enabled) {
      background = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
      foreground =
          baseStyle.color?.withValues(alpha: 0.38) ??
          scheme.onSurfaceVariant.withValues(alpha: 0.38);
    } else if (entry.selected && entry.highlightSelection) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else {
      background = scheme.surfaceContainerHighest.withValues(alpha: 0.55);
      foreground = scheme.onSurfaceVariant;
    }

    Widget child = Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(color: background, borderRadius: radius),
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? entry.onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              entry.label,
              style: baseStyle.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
    if (entry.tooltip != null) {
      child = Tooltip(message: entry.tooltip!, child: child);
    }
    return child;
  }
}
