import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'filters_controls.dart';
import 'filters_section_utils.dart';

class FiltersSearchSection extends StatelessWidget {
  const FiltersSearchSection({
    super.key,
    required this.controller,
    required this.searchMode,
    required this.caseSensitive,
    required this.hasPattern,
    required this.onClear,
    required this.onCycleMode,
    required this.onToggleCaseSensitive,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final UyavaFilterSearchMode searchMode;
  final bool caseSensitive;
  final bool hasPattern;
  final VoidCallback onClear;
  final VoidCallback onCycleMode;
  final VoidCallback onToggleCaseSensitive;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle fieldStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final Color hintBase =
        fieldStyle.color ?? theme.colorScheme.onSurfaceVariant;
    final List<FiltersButtonGroupEntry> buttons = <FiltersButtonGroupEntry>[
      FiltersButtonGroupEntry(
        label: 'X',
        tooltip: 'Clear pattern filter',
        enabled: hasPattern,
        onPressed: hasPattern ? onClear : null,
      ),
      FiltersButtonGroupEntry(
        label: _searchModeLabel(searchMode),
        tooltip: 'Toggle search mode',
        onPressed: onCycleMode,
      ),
      FiltersButtonGroupEntry(
        label: 'Aa',
        tooltip: caseSensitive
            ? 'Case-sensitive search enabled'
            : 'Case-sensitive search disabled',
        selected: caseSensitive,
        onPressed: onToggleCaseSensitive,
      ),
    ];
    final Widget buttonGroup = FiltersButtonGroup(entries: buttons);
    final Widget textField = TextField(
      controller: controller,
      textAlignVertical: TextAlignVertical.center,
      style: fieldStyle,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Pattern',
        hintStyle: fieldStyle.copyWith(color: hintBase.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        suffixIcon: null,
      ),
      onSubmitted: (_) => onSubmitted(),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size screen = MediaQuery.sizeOf(context);
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : math.min(screen.width, 520);
        const double trailingWidth = 150;
        final double fieldWidth = adaptiveFieldWidth(
          availableWidth: availableWidth,
          trailingWidth: trailingWidth,
          minWidth: 140,
          maxWidth: 320,
          horizontalPadding: 48,
          text: controller.text.isEmpty ? 'Pattern' : controller.text,
          style: fieldStyle,
        );
        final Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: fieldWidth, child: textField),
            const SizedBox(width: 6),
            buttonGroup,
          ],
        );
        final double rowWidth = fieldWidth + trailingWidth;
        if (availableWidth < rowWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: row,
          );
        }
        return row;
      },
    );
  }
}

String _searchModeLabel(UyavaFilterSearchMode mode) {
  switch (mode) {
    case UyavaFilterSearchMode.substring:
      return 'Substr';
    case UyavaFilterSearchMode.mask:
      return 'Mask';
    case UyavaFilterSearchMode.regex:
      return 'Regex';
  }
}
