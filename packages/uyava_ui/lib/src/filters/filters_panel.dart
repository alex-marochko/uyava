import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import 'filters_nodes_section.dart';
import 'filters_search_section.dart';
import 'filters_severity_section.dart';
import 'filters_tags_section.dart';
import 'filters_view_model.dart';
import '../widgets/toolbar_icon_button.dart';

/// Shared panel with controls for configuring graph filters.
class UyavaFiltersPanel extends StatefulWidget {
  const UyavaFiltersPanel({
    super.key,
    required this.controller,
    this.initialFilters,
    this.onReset,
    this.filterAllPanels = true,
    this.onFilterAllPanelsChanged,
    this.autoCompactEnabled = true,
    this.onAutoCompactChanged,
  });

  /// Graph controller to read current filters from and apply updates to.
  final GraphController controller;

  /// Optional snapshot used to seed the form before any controller events.
  final GraphFilterState? initialFilters;

  /// Optional callback invoked after filters are reset to defaults.
  final VoidCallback? onReset;

  /// Whether filters should be applied to all panels (graph + dashboard).
  final bool filterAllPanels;

  /// Invoked when the "Filter all panels" toggle changes.
  final ValueChanged<bool>? onFilterAllPanelsChanged;

  /// Whether automatic compacting runs after filters apply.
  final bool autoCompactEnabled;

  /// Invoked when the auto-compact toggle changes.
  final ValueChanged<bool>? onAutoCompactChanged;

  @override
  State<UyavaFiltersPanel> createState() => _UyavaFiltersPanelState();
}

class _UyavaFiltersPanelState extends State<UyavaFiltersPanel> {
  late FiltersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final GraphFilterState seedFilters =
        widget.initialFilters ?? widget.controller.filters;
    _viewModel = FiltersViewModel(
      controller: widget.controller,
      initialFilters: seedFilters,
      filterAllPanels: widget.filterAllPanels,
      autoCompactEnabled: widget.autoCompactEnabled,
    );
    _viewModel.applyInitialFilters(seedFilters);
  }

  @override
  void didUpdateWidget(covariant UyavaFiltersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      _viewModel.replaceController(widget.controller);
    }
    _viewModel.syncPanelToggles(
      filterAllPanels: widget.filterAllPanels,
      autoCompactEnabled: widget.autoCompactEnabled,
    );
    if (widget.initialFilters != oldWidget.initialFilters ||
        !identical(widget.controller, oldWidget.controller)) {
      _viewModel.applyInitialFilters(
        widget.initialFilters ?? widget.controller.filters,
      );
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FiltersViewState>(
      initialData: _viewModel.state,
      stream: _viewModel.stream,
      builder:
          (BuildContext context, AsyncSnapshot<FiltersViewState> snapshot) {
            final FiltersViewState state = snapshot.data ?? _viewModel.state;
            return _buildContent(context, state);
          },
    );
  }

  Widget _buildContent(BuildContext context, FiltersViewState state) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ThemeData theme = Theme.of(context);
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : math.min(1024, MediaQuery.sizeOf(context).width);
        final Widget content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildActionsRow(theme, state),
                FiltersSearchSection(
                  controller: _viewModel.searchController,
                  searchMode: state.form.searchMode,
                  caseSensitive: state.form.caseSensitive,
                  hasPattern: state.form.hasPattern,
                  onClear: _viewModel.clearPattern,
                  onCycleMode: _viewModel.cycleSearchMode,
                  onToggleCaseSensitive: _viewModel.toggleCaseSensitive,
                  onSubmitted: _viewModel.applyNow,
                ),
                FiltersTagsSection(
                  options: state.tagOptions,
                  lookup: state.tagLookup,
                  selectedTags: state.form.selectedTags,
                  tagsMode: state.form.tagsMode,
                  tagsLogic: state.form.tagsLogic,
                  onSelectionChanged: _viewModel.updateSelectedTags,
                  onClear: _viewModel.clearTags,
                  onToggleMode: _viewModel.cycleTagsMode,
                  onToggleLogic: _viewModel.cycleTagsLogic,
                ),
                FiltersNodesSection(
                  options: state.nodeOptions,
                  lookup: state.nodeLookup,
                  descendants: state.nodeDescendants,
                  selectedNodeIds: state.form.selectedNodeIds,
                  mode: state.form.nodeMode,
                  onSelectionChanged: _viewModel.updateSelectedNodeIds,
                  onClear: _viewModel.clearNodes,
                  onToggleMode: _viewModel.toggleNodeMode,
                ),
                FiltersSeveritySection(
                  selectedSeverity: state.form.selectedSeverity,
                  severityOperator: state.form.severityOperator,
                  onChanged: _viewModel.setSeverity,
                  onClear: _viewModel.clearSeverity,
                  onCycleOperator: _viewModel.cycleSeverityOperator,
                ),
              ],
            ),
          ),
        );
        if (!constraints.hasBoundedWidth || maxWidth < 360) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 360),
              child: content,
            ),
          );
        }
        return SizedBox(width: maxWidth, child: content);
      },
    );
  }

  Widget _buildActionsRow(ThemeData theme, FiltersViewState state) {
    final ColorScheme scheme = theme.colorScheme;
    final BorderRadius buttonRadius = BorderRadius.circular(8);
    final Widget debounceToggle = Tooltip(
      message: state.debounceEnabled
          ? 'Automatic apply enabled'
          : 'Enable automatic apply',
      child: FilledButton.tonal(
        onPressed: _viewModel.toggleDebounce,
        style:
            FilledButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              shape: RoundedRectangleBorder(borderRadius: buttonRadius),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.surfaceContainerHighest.withValues(alpha: 0.35);
                }
                if (state.debounceEnabled) {
                  return scheme.primary;
                }
                return scheme.surfaceContainerHighest.withValues(alpha: 0.55);
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.onSurfaceVariant.withValues(alpha: 0.38);
                }
                if (state.debounceEnabled) {
                  return scheme.onPrimary;
                }
                return scheme.onSurfaceVariant;
              }),
            ),
        child: const Icon(Icons.timer, size: 18),
      ),
    );
    final Widget applyButton = UyavaToolbarIconButton(
      tooltip: state.debounceEnabled
          ? 'Automatic apply is enabled'
          : 'Apply filters',
      onPressed: state.debounceEnabled ? null : _viewModel.applyNow,
      icon: const Icon(Icons.filter_alt, size: 18),
    );
    final Widget clearButton = UyavaToolbarIconButton(
      tooltip: 'Clear filters',
      onPressed: state.canClearFilters ? _handleClearFiltersPressed : null,
      icon: const Icon(Icons.filter_alt_off, size: 18),
    );
    final Widget scopeToggle = Tooltip(
      message: state.filterAllPanels
          ? 'Filter all panels'
          : 'Filter only graph',
      child: FilledButton.tonal(
        onPressed: () => _handleFilterAllPanelsChanged(!state.filterAllPanels),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(48, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: theme.textTheme.labelSmall,
        ),
        child: Text(state.filterAllPanels ? 'All' : 'Graph'),
      ),
    );
    final Widget compactToggle = Tooltip(
      message: state.autoCompactEnabled
          ? 'Auto-compact layout after filtering'
          : 'Auto-compact disabled',
      child: FilledButton.tonal(
        onPressed: () => _handleAutoCompactChanged(!state.autoCompactEnabled),
        style:
            FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(48, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.surfaceContainerHighest.withValues(alpha: 0.35);
                }
                if (state.autoCompactEnabled) {
                  return scheme.primary;
                }
                return scheme.surfaceContainerHighest.withValues(alpha: 0.55);
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.onSurfaceVariant.withValues(alpha: 0.38);
                }
                if (state.autoCompactEnabled) {
                  return scheme.onPrimary;
                }
                return scheme.onSurfaceVariant;
              }),
            ),
        child: const Icon(Icons.center_focus_strong, size: 18),
      ),
    );

    final List<Widget> controls = <Widget>[
      debounceToggle,
      applyButton,
      clearButton,
      scopeToggle,
      compactToggle,
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 520;
        if (compact) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: controls,
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < controls.length; i++) ...[
              if (i != 0) const SizedBox(width: 8),
              controls[i],
            ],
          ],
        );
      },
    );
  }

  void _handleClearFiltersPressed() {
    _viewModel.clearFilters();
    widget.onReset?.call();
  }

  void _handleFilterAllPanelsChanged(bool next) {
    _viewModel.updateFilterAllPanels(next);
    widget.onFilterAllPanelsChanged?.call(next);
  }

  void _handleAutoCompactChanged(bool next) {
    _viewModel.updateAutoCompact(next);
    widget.onAutoCompactChanged?.call(next);
  }
}
