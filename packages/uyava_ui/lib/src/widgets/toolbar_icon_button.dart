import 'package:flutter/material.dart';

/// Shared tonal icon button used across toolbar surfaces (filters, focus panel).
class UyavaToolbarIconButton extends StatelessWidget {
  const UyavaToolbarIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    this.onPressed,
    this.isActive = false,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(6);
    final ButtonStyle baseStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(36, 36),
      shape: RoundedRectangleBorder(borderRadius: radius),
    );
    final ButtonStyle style = isActive
        ? baseStyle.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.disabled)) {
                return scheme.surfaceContainerHighest.withValues(alpha: 0.35);
              }
              return scheme.primary;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.disabled)) {
                return scheme.onSurfaceVariant.withValues(alpha: 0.38);
              }
              return scheme.onPrimary;
            }),
          )
        : baseStyle;
    return Tooltip(
      message: tooltip,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: style,
        child: icon,
      ),
    );
  }
}
