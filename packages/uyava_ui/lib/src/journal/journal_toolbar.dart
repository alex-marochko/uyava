import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import '../theme.dart';
import '../widgets/toolbar_icon_button.dart';
import 'journal_filter_field.dart';
import 'journal_view_model.dart';

part 'journal_tab_header.dart';
part 'journal_toolbar_buttons.dart';
part 'journal_toolbar_focus.dart';

const double _kJournalToolbarButtonHeight = 36.0;
const Size _kJournalToolbarButtonSize = Size.square(36);
const EdgeInsets _kJournalToolbarButtonPadding = EdgeInsets.all(8);

class GraphJournalToolbar extends StatelessWidget {
  const GraphJournalToolbar({
    super.key,
    required this.tabController,
    required this.viewModel,
    required this.focusFilterPaused,
    required this.onFocusFilterToggle,
    required this.onClearFocus,
    required this.onRemoveNodeFromFocus,
    required this.onRemoveEdgeFromFocus,
    required this.onRevealFocus,
    required this.respectsGraphFilter,
    required this.onGraphFilterToggle,
    required this.isEventsTabActive,
    required this.isCurrentTabRaw,
    required this.onRawToggle,
    required this.autoScrollEnabled,
    required this.onAutoScrollPressed,
    required this.onCopyVisibleLog,
    required this.copyEnabled,
    required this.onClearLog,
    required this.clearEnabled,
    required this.filterController,
    required this.onFocusPauseTooltip,
    required this.controlsEnabled,
    this.paywallTooltip,
    this.totalEventsCount,
    this.totalWarnCount,
    this.totalCriticalCount,
    this.hasActiveFilters = false,
  });

  final TabController tabController;
  final GraphJournalViewModel viewModel;
  final bool focusFilterPaused;
  final VoidCallback? onFocusFilterToggle;
  final VoidCallback? onClearFocus;
  final ValueChanged<String>? onRemoveNodeFromFocus;
  final ValueChanged<String>? onRemoveEdgeFromFocus;
  final Future<void> Function()? onRevealFocus;
  final bool respectsGraphFilter;
  final VoidCallback? onGraphFilterToggle;
  final bool isEventsTabActive;
  final bool isCurrentTabRaw;
  final VoidCallback? onRawToggle;
  final bool autoScrollEnabled;
  final VoidCallback? onAutoScrollPressed;
  final VoidCallback onCopyVisibleLog;
  final bool copyEnabled;
  final VoidCallback onClearLog;
  final bool clearEnabled;
  final TextEditingController filterController;
  final String onFocusPauseTooltip;
  final bool controlsEnabled;
  final String? paywallTooltip;
  final int? totalEventsCount;
  final int? totalWarnCount;
  final int? totalCriticalCount;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final String disabledHint = paywallTooltip ?? 'Requires Pro';
    final Widget tabBar = GraphJournalTabBar(
      controller: tabController,
      eventsCount: viewModel.events.length,
      totalEventsCount: totalEventsCount,
      diagnosticsAttentionCount: viewModel.diagnosticsAttentionCount,
      warnCount: viewModel.severityTally.warnCount,
      criticalCount: viewModel.severityTally.criticalCount,
      totalWarnCount: totalWarnCount,
      totalCriticalCount: totalCriticalCount,
      hasActiveFilters: hasActiveFilters,
    );
    final List<Widget> trailing = _buildTrailingControls(context, disabledHint);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: IntrinsicHeight(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SizedBox(
              height: 36,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  tabBar,
                  if (trailing.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (int i = 0; i < trailing.length; i++) ...[
                                if (i != 0) const SizedBox(width: 8),
                                trailing[i],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTrailingControls(
    BuildContext context,
    String disabledTooltip,
  ) {
    final List<Widget> controls = <Widget>[];
    final GraphJournalFocusContext focusContext = viewModel.focusContext;
    final bool hasFocusControls = focusContext.hasFocus;
    if (hasFocusControls) {
      controls.add(
        _FocusSummaryButton(
          context: focusContext,
          summaryLabel: viewModel.focusSummaryLabel,
          paused: focusFilterPaused || !focusContext.hasFocus,
          onRemoveNode: controlsEnabled ? onRemoveNodeFromFocus : null,
          onRemoveEdge: controlsEnabled ? onRemoveEdgeFromFocus : null,
        ),
      );
      controls.add(
        _FocusActions(
          focusContext: focusContext,
          focusFilterPaused: focusFilterPaused,
          onFocusFilterToggle: controlsEnabled ? onFocusFilterToggle : null,
          onClearFocus: controlsEnabled ? onClearFocus : null,
          onRevealFocus: controlsEnabled ? onRevealFocus : null,
          tooltip: controlsEnabled ? onFocusPauseTooltip : disabledTooltip,
        ),
      );
    }
    controls.add(const _JournalToolbarDivider());
    controls.add(
      _JournalGraphFilterButton(
        respectsGraphFilter: respectsGraphFilter,
        onPressed: controlsEnabled ? onGraphFilterToggle : null,
        disabledTooltip: disabledTooltip,
      ),
    );
    controls.add(
      _JournalRawToggleButton(
        key: ValueKey<String>(
          isEventsTabActive
              ? 'uyava_journal_events_raw_toggle'
              : 'uyava_journal_diagnostics_raw_toggle',
        ),
        isEventsTab: isEventsTabActive,
        isActive: isCurrentTabRaw,
        onPressed: controlsEnabled ? onRawToggle : null,
        disabledTooltip: disabledTooltip,
      ),
    );
    controls.add(
      _CopyLogButton(
        enabled: copyEnabled,
        onPressed: copyEnabled ? onCopyVisibleLog : null,
        disabledTooltip: disabledTooltip,
      ),
    );
    controls.add(
      _ClearLogButton(
        enabled: clearEnabled,
        onPressed: clearEnabled ? onClearLog : null,
        disabledTooltip: disabledTooltip,
      ),
    );
    controls.add(const _JournalToolbarDivider());
    controls.add(
      _AutoScrollButton(
        isEventsTab: isEventsTabActive,
        enabled: controlsEnabled && autoScrollEnabled,
        onPressed: controlsEnabled ? onAutoScrollPressed : null,
        disabledTooltip: disabledTooltip,
      ),
    );
    controls.add(const _JournalToolbarDivider());
    controls.add(
      GraphJournalFilterField(
        controller: filterController,
        enabled: controlsEnabled,
        disabledTooltip: disabledTooltip,
      ),
    );
    return controls;
  }
}
