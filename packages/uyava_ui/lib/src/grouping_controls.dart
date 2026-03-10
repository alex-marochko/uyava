import 'package:flutter/material.dart';

/// Compact controls for selecting graph grouping depth.
class GraphGroupingControls extends StatelessWidget {
  const GraphGroupingControls({
    super.key,
    required this.availableLevels,
    required this.selectedLevel,
    required this.onLevelSelected,
    required this.onClearGrouping,
  });

  /// Depth levels that can be selected. The list should already be sorted.
  final List<int> availableLevels;

  /// Currently selected depth level, or `null` when grouping is disabled.
  final int? selectedLevel;

  /// Invoked when a depth level is selected.
  final ValueChanged<int> onLevelSelected;

  /// Invoked when grouping should be disabled.
  final VoidCallback onClearGrouping;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[
      Tooltip(
        message: 'Cancel grouping',
        child: _GroupingButton.icon(
          icon: Icons.cancel,
          selected: selectedLevel == null,
          onPressed: onClearGrouping,
        ),
      ),
      for (final int level in availableLevels)
        Tooltip(
          message: 'Collapse to depth $level',
          child: _GroupingButton.text(
            label: '$level',
            selected: selectedLevel == level,
            onPressed: () => onLevelSelected(level),
          ),
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: buttons,
    );
  }
}

class _GroupingButton extends StatelessWidget {
  const _GroupingButton.text({
    required String label,
    required this.onPressed,
    required this.selected,
  }) : _label = label,
       _icon = null;

  const _GroupingButton.icon({
    required IconData icon,
    required this.onPressed,
    required this.selected,
  }) : _icon = icon,
       _label = null;

  final VoidCallback onPressed;
  final bool selected;
  final String? _label;
  final IconData? _icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonStyle style =
        OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 0),
          visualDensity: VisualDensity.compact,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            final Color highlight = theme.colorScheme.primary.withValues(
              alpha: 0.08,
            );
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            return selected ? highlight : null;
          }),
        );

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: _icon != null
          ? Icon(_icon, size: 18)
          : Text(_label!, style: theme.textTheme.bodySmall),
    );
  }
}
