import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'filters_controls.dart';
import 'filters_section_utils.dart';

class FiltersSeveritySection extends StatelessWidget {
  const FiltersSeveritySection({
    super.key,
    required this.selectedSeverity,
    required this.severityOperator,
    required this.onChanged,
    required this.onClear,
    required this.onCycleOperator,
  });

  final UyavaSeverity? selectedSeverity;
  final UyavaFilterSeverityOperator severityOperator;
  final ValueChanged<UyavaSeverity?> onChanged;
  final VoidCallback onClear;
  final VoidCallback onCycleOperator;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dropdownTextStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final bool hasSelection = selectedSeverity != null;
    final List<FiltersButtonGroupEntry> buttons = <FiltersButtonGroupEntry>[
      FiltersButtonGroupEntry(
        label: 'X',
        tooltip: 'Clear severity filter',
        enabled: hasSelection,
        onPressed: hasSelection ? onClear : null,
      ),
      FiltersButtonGroupEntry(
        label: _severityOperatorLabel(severityOperator),
        tooltip: 'Toggle severity comparison',
        onPressed: onCycleOperator,
      ),
    ];
    final Widget buttonGroup = FiltersButtonGroup(entries: buttons);
    final Widget dropdown = DropdownButtonFormField<UyavaSeverity>(
      key: ValueKey(selectedSeverity),
      initialValue: selectedSeverity,
      items: [
        for (final severity in UyavaSeverity.values)
          DropdownMenuItem<UyavaSeverity>(
            value: severity,
            child: Text(
              _severityLabel(severity),
              style: dropdownTextStyle,
              maxLines: 1,
              overflow: TextOverflow.fade,
            ),
          ),
      ],
      isExpanded: true,
      style: dropdownTextStyle,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Severity',
        hintStyle: dropdownTextStyle.copyWith(color: theme.hintColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onChanged: onChanged,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size screen = MediaQuery.sizeOf(context);
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : math.min(screen.width, 520);
        const double trailingWidth = 120;
        final String displayLabel = hasSelection
            ? _severityLabel(selectedSeverity!)
            : 'Severity';
        final double fieldWidth = adaptiveFieldWidth(
          availableWidth: availableWidth,
          trailingWidth: trailingWidth,
          minWidth: 110,
          maxWidth: 220,
          horizontalPadding: 40,
          text: displayLabel,
          style: dropdownTextStyle,
        );
        final Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: fieldWidth, child: dropdown),
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

String _severityOperatorLabel(UyavaFilterSeverityOperator operator) {
  switch (operator) {
    case UyavaFilterSeverityOperator.atLeast:
      return '>=';
    case UyavaFilterSeverityOperator.atMost:
      return '<=';
    case UyavaFilterSeverityOperator.exact:
      return '==';
  }
}

String _severityLabel(UyavaSeverity severity) {
  switch (severity) {
    case UyavaSeverity.trace:
      return 'Trace';
    case UyavaSeverity.debug:
      return 'Debug';
    case UyavaSeverity.info:
      return 'Info';
    case UyavaSeverity.warn:
      return 'Warn';
    case UyavaSeverity.error:
      return 'Error';
    case UyavaSeverity.fatal:
      return 'Fatal';
  }
}
