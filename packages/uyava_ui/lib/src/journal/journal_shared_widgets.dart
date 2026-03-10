import 'package:flutter/material.dart';

class GraphJournalEmptyState extends StatelessWidget {
  const GraphJournalEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.padding = const EdgeInsets.symmetric(vertical: 24),
  });

  final IconData icon;
  final String message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final TextStyle text =
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    final Color color = Theme.of(context).disabledColor;
    return Center(
      child: Padding(
        padding: padding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GraphJournalOverflowNotice extends StatelessWidget {
  const GraphJournalOverflowNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle style =
        theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: style.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class GraphJournalLinkText extends StatelessWidget {
  const GraphJournalLinkText({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = onPressed != null;
    final TextStyle style = base.copyWith(
      color: enabled ? scheme.primary : scheme.onSurfaceVariant,
      decoration: enabled ? TextDecoration.underline : TextDecoration.none,
      fontWeight: FontWeight.w600,
    );
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Text(label, style: style),
          ),
        ),
      ),
    );
  }
}

class GraphJournalMetadataChip extends StatelessWidget {
  const GraphJournalMetadataChip({
    super.key,
    required this.icon,
    required this.label,
    required this.scheme,
    this.tooltip,
    this.onPressed,
    this.interactionKey,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Key? interactionKey;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        Theme.of(context).textTheme.labelSmall ??
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
    final bool enabled = onPressed != null;
    final Color foreground = enabled ? scheme.primary : scheme.onSurfaceVariant;
    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.all(Radius.circular(40)),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
    final Widget content = enabled
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: interactionKey,
              behavior: HitTestBehavior.translucent,
              onTap: onPressed,
              child: chip,
            ),
          )
        : interactionKey == null
        ? chip
        : KeyedSubtree(key: interactionKey, child: chip);
    if (tooltip == null) {
      return content;
    }
    return Tooltip(message: tooltip, child: content);
  }
}

class GraphJournalActionDivider extends StatelessWidget {
  const GraphJournalActionDivider({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: color.withValues(alpha: 0.4),
    );
  }
}

class GraphJournalRawToggleButton extends StatelessWidget {
  const GraphJournalRawToggleButton({
    super.key,
    required this.scheme,
    required this.active,
    required this.tooltip,
    this.onPressed,
  });

  final ColorScheme scheme;
  final bool active;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.7);
    final Color background = active
        ? scheme.primary
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final Color foreground = active
        ? scheme.onPrimary
        : scheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.5),
          disabledForegroundColor: foreground.withValues(alpha: 0.6),
          side: BorderSide(
            color: active ? Colors.transparent : borderColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.data_object),
      ),
    );
  }
}
