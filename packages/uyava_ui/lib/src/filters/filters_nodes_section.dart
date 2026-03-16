import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'filters_controls.dart';
import 'filters_form_state.dart';
import 'filters_multi_select_field.dart';
import 'filters_options_controller.dart';
import 'filters_section_utils.dart';

class FiltersNodesSection extends StatelessWidget {
  const FiltersNodesSection({
    super.key,
    required this.options,
    required this.lookup,
    required this.descendants,
    required this.selectedNodeIds,
    required this.mode,
    required this.onSelectionChanged,
    required this.onClear,
    required this.onToggleMode,
  });

  final List<NodeFilterOption> options;
  final Map<String, NodeFilterOption> lookup;
  final Map<String, List<String>> descendants;
  final List<String> selectedNodeIds;
  final FiltersNodeMode mode;
  final ValueChanged<List<String>> onSelectionChanged;
  final VoidCallback onClear;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle fieldStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final Widget modeButton = FiltersButtonGroup(
      entries: <FiltersButtonGroupEntry>[
        FiltersButtonGroupEntry(
          label: 'X',
          tooltip: 'Clear node filter',
          enabled: selectedNodeIds.isNotEmpty,
          onPressed: selectedNodeIds.isNotEmpty ? onClear : null,
        ),
        FiltersButtonGroupEntry(
          label: _nodeModeLabel(mode),
          tooltip: 'Toggle node filter mode',
          onPressed: onToggleMode,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size screen = MediaQuery.sizeOf(context);
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : math.min(screen.width, 520);
        const double trailingWidth = 130;
        final String summary = selectedNodeIds.isEmpty
            ? 'Nodes'
            : _selectionSummary(selectedNodeIds, lookup);
        final double fieldWidth = adaptiveFieldWidth(
          availableWidth: availableWidth,
          trailingWidth: trailingWidth,
          minWidth: 120,
          maxWidth: 320,
          horizontalPadding: 40,
          text: summary.isEmpty ? 'Nodes' : summary,
          style: fieldStyle,
        );
        final Widget field = FiltersMultiSelectField<String>(
          options: options,
          selectedValues: selectedNodeIds,
          onChanged: onSelectionChanged,
          hintText: 'Nodes',
          searchHintText: 'Search nodes',
          emptyLabel: options.isEmpty
              ? 'No nodes available'
              : 'No matching nodes',
          leadingIcon: const Icon(Icons.account_tree, size: 16),
          selectionSummaryBuilder: _selectionSummary,
          cascadeChildren: descendants,
          menuWidth: math.max(fieldWidth, 360),
        );
        final Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: fieldWidth, child: field),
            const SizedBox(width: 6),
            modeButton,
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

String _selectionSummary(
  List<String> selection,
  Map<String, FiltersMultiSelectOption<String>> lookup,
) {
  if (selection.isEmpty) return '';
  if (selection.length == 1) {
    final FiltersMultiSelectOption<String>? option = lookup[selection.first];
    return option?.chipLabel ?? selection.first;
  }
  return '(${selection.length} nodes)';
}

String _nodeModeLabel(FiltersNodeMode mode) {
  return mode == FiltersNodeMode.include ? 'Include' : 'Exclude';
}
