import 'package:flutter/material.dart';

class GraphJournalFilterField extends StatelessWidget {
  const GraphJournalFilterField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.disabledTooltip,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool hasQuery = controller.text.isNotEmpty;
    final OutlineInputBorder inactiveBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.7),
      ),
    );
    final OutlineInputBorder activeBorder = inactiveBorder.copyWith(
      borderSide: BorderSide(color: scheme.primary, width: 1.4),
    );
    Widget field = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 60, maxWidth: 130),
      child: TextField(
        key: const Key('uyava_journal_text_filter'),
        controller: controller,
        textInputAction: TextInputAction.search,
        enabled: enabled,
        style: theme.textTheme.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Filter log…',
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 34,
          ),
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: 'Clear filter',
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(Icons.close),
                  onPressed: enabled ? controller.clear : null,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: inactiveBorder,
          enabledBorder: inactiveBorder,
          focusedBorder: activeBorder,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
      ),
    );
    if (!enabled) {
      field = Tooltip(
        message: disabledTooltip ?? 'Requires Pro',
        preferBelow: false,
        child: field,
      );
    }
    return field;
  }
}
