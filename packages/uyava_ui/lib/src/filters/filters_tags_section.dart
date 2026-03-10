import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'filters_controls.dart';
import 'filters_multi_select_field.dart';
import 'filters_options_controller.dart';
import 'filters_section_utils.dart';

class FiltersTagsSection extends StatelessWidget {
  const FiltersTagsSection({
    super.key,
    required this.options,
    required this.lookup,
    required this.selectedTags,
    required this.tagsMode,
    required this.tagsLogic,
    required this.onSelectionChanged,
    required this.onClear,
    required this.onToggleMode,
    required this.onToggleLogic,
  });

  final List<TagFilterOption> options;
  final Map<String, TagFilterOption> lookup;
  final List<String> selectedTags;
  final UyavaFilterTagsMode tagsMode;
  final UyavaFilterTagLogic tagsLogic;
  final ValueChanged<List<String>> onSelectionChanged;
  final VoidCallback onClear;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleLogic;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle fieldStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final bool disableLogic = tagsMode == UyavaFilterTagsMode.exact;
    final List<FiltersButtonGroupEntry> buttons = <FiltersButtonGroupEntry>[
      FiltersButtonGroupEntry(
        label: 'X',
        tooltip: 'Clear tag filter',
        enabled: selectedTags.isNotEmpty,
        onPressed: selectedTags.isNotEmpty ? onClear : null,
      ),
      FiltersButtonGroupEntry(
        label: _tagsModeLabel(tagsMode),
        tooltip: 'Toggle tag filter mode',
        onPressed: onToggleMode,
      ),
      FiltersButtonGroupEntry(
        label: _tagsLogicLabel(tagsLogic),
        tooltip: disableLogic
            ? 'Exact mode always requires all tags'
            : 'Toggle tag match logic',
        selected: !disableLogic && tagsLogic == UyavaFilterTagLogic.all,
        enabled: !disableLogic,
        highlightSelection: false,
        onPressed: disableLogic ? null : onToggleLogic,
      ),
    ];
    final Widget buttonGroup = FiltersButtonGroup(entries: buttons);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size screen = MediaQuery.sizeOf(context);
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : math.min(screen.width, 560);
        const double trailingWidth = 170;
        final String summary = selectedTags.isEmpty
            ? 'Tags'
            : _selectionSummary(selectedTags, lookup);
        final double fieldWidth = adaptiveFieldWidth(
          availableWidth: availableWidth,
          trailingWidth: trailingWidth,
          minWidth: 90,
          maxWidth: 320,
          horizontalPadding: 40,
          text: summary.isEmpty ? 'Tags' : summary,
          style: fieldStyle,
        );
        final Widget field = FiltersMultiSelectField<String>(
          options: options,
          selectedValues: selectedTags,
          onChanged: onSelectionChanged,
          hintText: 'Tags',
          searchHintText: 'Filter tags',
          emptyLabel: options.isEmpty
              ? 'No tags available'
              : 'No matching tags',
          leadingIcon: const Icon(Icons.sell_outlined, size: 16),
          selectionSummaryBuilder: _selectionSummary,
          menuWidth: math.max(fieldWidth, 320),
        );
        final Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: fieldWidth, child: field),
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

String _selectionSummary(
  List<String> selection,
  Map<String, FiltersMultiSelectOption<String>> lookup,
) {
  if (selection.isEmpty) return '';
  if (selection.length == 1) {
    final FiltersMultiSelectOption<String>? option = lookup[selection.first];
    return option?.chipLabel ?? selection.first;
  }
  return '(${selection.length} tags)';
}

String _tagsModeLabel(UyavaFilterTagsMode mode) {
  switch (mode) {
    case UyavaFilterTagsMode.include:
      return 'Include';
    case UyavaFilterTagsMode.exclude:
      return 'Exclude';
    case UyavaFilterTagsMode.exact:
      return 'Exact';
  }
}

String _tagsLogicLabel(UyavaFilterTagLogic logic) {
  switch (logic) {
    case UyavaFilterTagLogic.any:
      return 'Any';
    case UyavaFilterTagLogic.all:
      return 'All';
  }
}
