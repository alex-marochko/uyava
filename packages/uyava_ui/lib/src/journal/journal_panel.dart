import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import '../focus_controller.dart';
import 'journal_actions.dart';
import 'journal_controller.dart';
import 'journal_diagnostics_list.dart';
import 'journal_entry.dart';
import 'journal_event_list.dart';
import 'journal_host_adapter.dart';
import 'journal_link.dart';
import 'journal_tabs.dart';
import 'journal_toolbar.dart';
import 'journal_view_model.dart';

/// Shared bottom journal panel that exposes Events / Diagnostics tabs.
class UyavaGraphJournalPanel extends StatefulWidget {
  const UyavaGraphJournalPanel({
    super.key,
    required this.controller,
    required this.graphController,
    required this.focusState,
    this.hostAdapter,
    this.displayController,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.tabSpacing = 6,
    this.emptyStatePadding = const EdgeInsets.symmetric(vertical: 24),
    this.onLinkTap,
    this.onClearFocus,
    this.onRemoveNodeFromFocus,
    this.onRemoveEdgeFromFocus,
    this.onRevealFocus,
    this.onFocusFilterPausedChanged,
    this.initialFocusFilterPaused = false,
    this.onFocusGraphFilterChanged,
    this.initialFocusRespectsGraphFilter = true,
    this.onOpenDiagnosticDocs,
    this.onOpenInIde,
    this.initialEventsRaw = false,
    this.initialDiagnosticsRaw = false,
    this.onEventsRawChanged,
    this.onDiagnosticsRawChanged,
    this.onEventTap,
    this.totalJournalEvents,
    this.visibleJournalEvents,
    this.totalWarnEvents,
    this.totalCriticalEvents,
    this.virtualized = false,
    this.onRequestMoreEvents,
    this.controlsEnabled = true,
    this.paywallLabel,
    this.paywallAction,
    this.paywallTooltip,
  });

  final GraphJournalController controller;
  final GraphController graphController;
  final GraphFocusState focusState;
  final GraphJournalHostAdapter? hostAdapter;
  final GraphJournalDisplayController? displayController;
  final EdgeInsetsGeometry padding;
  final double tabSpacing;
  final EdgeInsetsGeometry emptyStatePadding;
  final ValueChanged<GraphJournalLinkTarget>? onLinkTap;
  final VoidCallback? onClearFocus;
  final ValueChanged<String>? onRemoveNodeFromFocus;
  final ValueChanged<String>? onRemoveEdgeFromFocus;
  final Future<void> Function()? onRevealFocus;
  final ValueChanged<bool>? onFocusFilterPausedChanged;
  final bool initialFocusFilterPaused;
  final ValueChanged<bool>? onFocusGraphFilterChanged;
  final bool initialFocusRespectsGraphFilter;
  final Future<void> Function(GraphDiagnosticRecord record)?
  onOpenDiagnosticDocs;
  final Future<void> Function(String sourceRef)? onOpenInIde;
  final bool initialEventsRaw;
  final bool initialDiagnosticsRaw;
  final ValueChanged<bool>? onEventsRawChanged;
  final ValueChanged<bool>? onDiagnosticsRawChanged;
  final ValueChanged<GraphJournalEventEntry>? onEventTap;
  final int? totalJournalEvents;
  final int? visibleJournalEvents;
  final int? totalWarnEvents;
  final int? totalCriticalEvents;
  final bool virtualized;
  final VoidCallback? onRequestMoreEvents;
  final bool controlsEnabled;
  final String? paywallLabel;
  final VoidCallback? paywallAction;
  final String? paywallTooltip;

  @override
  State<UyavaGraphJournalPanel> createState() => _UyavaGraphJournalPanelState();
}

class _UyavaGraphJournalPanelState extends State<UyavaGraphJournalPanel> {
  late final ScrollController _eventsScrollController;
  late final ScrollController _diagnosticsController;
  bool _autoScrollEvents = true;
  bool _autoScrollDiagnostics = true;
  late bool _focusFilterPaused;
  late bool _journalRespectsGraphFilter;
  late bool _eventsRaw;
  late bool _diagnosticsRaw;
  late GraphJournalTab _activeTab;
  GraphJournalDisplayController? _displayController;
  int? _lastEventSequence;
  DateTime? _lastDiagnosticTimestamp;
  int? _selectedEventSequence;
  int _hiddenFilteredScrollSkips = 0;
  final Map<int, GraphJournalEventDetailCache> _eventDetailCache =
      <int, GraphJournalEventDetailCache>{};
  late final TextEditingController _journalFilterController;
  String _journalFilterQuery = '';

  @override
  void initState() {
    super.initState();
    _displayController = widget.displayController;
    _displayController?.addListener(_handleDisplayControllerChanged);
    _activeTab = _displayController?.activeTab ?? GraphJournalTab.events;
    _eventsScrollController = ScrollController();
    _diagnosticsController = ScrollController();
    _focusFilterPaused = widget.initialFocusFilterPaused;
    _journalRespectsGraphFilter = widget.initialFocusRespectsGraphFilter;
    _eventsRaw = widget.initialEventsRaw;
    _diagnosticsRaw = widget.initialDiagnosticsRaw;
    _journalFilterController = TextEditingController()
      ..addListener(_handleJournalFilterChanged);
  }

  @override
  void didUpdateWidget(covariant UyavaGraphJournalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayController != oldWidget.displayController) {
      oldWidget.displayController?.removeListener(
        _handleDisplayControllerChanged,
      );
      _displayController = widget.displayController;
      _displayController?.addListener(_handleDisplayControllerChanged);
    }
    if (widget.initialFocusFilterPaused != oldWidget.initialFocusFilterPaused &&
        _focusFilterPaused != widget.initialFocusFilterPaused) {
      setState(() {
        _focusFilterPaused = widget.initialFocusFilterPaused;
      });
    }
    if (widget.initialFocusRespectsGraphFilter !=
            oldWidget.initialFocusRespectsGraphFilter &&
        _journalRespectsGraphFilter != widget.initialFocusRespectsGraphFilter) {
      setState(() {
        _journalRespectsGraphFilter = widget.initialFocusRespectsGraphFilter;
      });
    }
    if (widget.initialEventsRaw != oldWidget.initialEventsRaw &&
        _eventsRaw != widget.initialEventsRaw) {
      setState(() {
        _eventsRaw = widget.initialEventsRaw;
      });
    }
    if (widget.initialDiagnosticsRaw != oldWidget.initialDiagnosticsRaw &&
        _diagnosticsRaw != widget.initialDiagnosticsRaw) {
      setState(() {
        _diagnosticsRaw = widget.initialDiagnosticsRaw;
      });
    }
    if (widget.displayController != oldWidget.displayController &&
        widget.displayController != null) {
      _activeTab = widget.displayController!.activeTab;
    }
  }

  void _maybeAutoScroll({
    required List<GraphJournalEventEntry> visibleEvents,
    required List<GraphDiagnosticRecord> visibleDiagnostics,
  }) {
    final int? latestSequence = visibleEvents.isEmpty
        ? null
        : visibleEvents.last.sequence;
    final bool newEventArrived =
        latestSequence != null && latestSequence != _lastEventSequence;
    if (_autoScrollEvents && newEventArrived) {
      _scheduleScrollControllerToEnd(_eventsScrollController);
    }
    _lastEventSequence = latestSequence;

    final DateTime? latestDiagnosticTimestamp = visibleDiagnostics.isEmpty
        ? null
        : visibleDiagnostics.last.timestamp;
    final bool newDiagnosticArrived =
        latestDiagnosticTimestamp != null &&
        latestDiagnosticTimestamp != _lastDiagnosticTimestamp;
    if (_autoScrollDiagnostics && newDiagnosticArrived) {
      _scheduleScrollControllerToEnd(_diagnosticsController);
    }
    _lastDiagnosticTimestamp = latestDiagnosticTimestamp;
  }

  void _pruneEventDetailCache(Iterable<GraphJournalEventEntry> entries) {
    if (_eventDetailCache.isEmpty && _selectedEventSequence == null) {
      return;
    }
    final Set<int> retain = <int>{for (final entry in entries) entry.sequence};
    _eventDetailCache.removeWhere((sequence, _) => !retain.contains(sequence));
    if (_selectedEventSequence != null &&
        !retain.contains(_selectedEventSequence)) {
      _selectedEventSequence = null;
    }
  }

  void _handleEventSelected(GraphJournalEventEntry entry) {
    if (!_eventsRaw) {
      return;
    }
    if (_selectedEventSequence == entry.sequence) {
      return;
    }
    setState(() {
      _selectedEventSequence = entry.sequence;
    });
  }

  void _scheduleScrollControllerToEnd(ScrollController controller) {
    if (!controller.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.jumpTo(controller.position.maxScrollExtent);
    });
  }

  void _handleUserScrollAway(GraphJournalTab tab) {
    if (tab == GraphJournalTab.events) {
      if (!_autoScrollEvents) return;
      setState(() => _autoScrollEvents = false);
      return;
    }
    if (!_autoScrollDiagnostics) return;
    setState(() => _autoScrollDiagnostics = false);
  }

  void _toggleFocusFilter() {
    setState(() {
      _focusFilterPaused = !_focusFilterPaused;
    });
    widget.onFocusFilterPausedChanged?.call(_focusFilterPaused);
    _logJournalAction(
      'toggle_focus_filter',
      context: <String, Object?>{'paused': _focusFilterPaused},
    );
  }

  void _toggleJournalGraphFilter() {
    setState(() {
      _journalRespectsGraphFilter = !_journalRespectsGraphFilter;
    });
    widget.onFocusGraphFilterChanged?.call(_journalRespectsGraphFilter);
    _logJournalAction(
      'toggle_graph_filter_binding',
      context: <String, Object?>{'respectPrimary': _journalRespectsGraphFilter},
    );
  }

  void _handleClearLog() {
    widget.controller.clearLog();
    if (_eventsScrollController.hasClients) {
      _eventsScrollController.jumpTo(0);
    }
    if (_diagnosticsController.hasClients) {
      _diagnosticsController.jumpTo(0);
    }
    if (_selectedEventSequence != null || _eventDetailCache.isNotEmpty) {
      setState(() {
        _selectedEventSequence = null;
      });
      _eventDetailCache.clear();
    }
    _logJournalAction('clear_log');
  }

  void _toggleRawForTab(GraphJournalTab tab) {
    if (tab == GraphJournalTab.events) {
      _setEventsRaw(!_eventsRaw);
      return;
    }
    _setDiagnosticsRaw(!_diagnosticsRaw);
  }

  void _setEventsRaw(bool next) {
    if (_eventsRaw == next) return;
    setState(() {
      _eventsRaw = next;
      if (!next) {
        _selectedEventSequence = null;
      }
    });
    if (_autoScrollEvents) {
      _scheduleScrollControllerToEnd(_eventsScrollController);
    }
    widget.onEventsRawChanged?.call(next);
    _logJournalAction(
      'toggle_raw_view',
      context: <String, Object?>{'tab': 'events', 'enabled': next},
    );
  }

  void _setDiagnosticsRaw(bool next) {
    if (_diagnosticsRaw == next) return;
    setState(() {
      _diagnosticsRaw = next;
    });
    widget.onDiagnosticsRawChanged?.call(next);
    _logJournalAction(
      'toggle_raw_view',
      context: <String, Object?>{'tab': 'diagnostics', 'enabled': next},
    );
  }

  bool _isTabRaw(GraphJournalTab tab) =>
      tab == GraphJournalTab.events ? _eventsRaw : _diagnosticsRaw;

  void _handleAutoScrollPressed(GraphJournalTab tab) {
    final bool eventsTab = tab == GraphJournalTab.events;
    if (eventsTab) {
      final bool enabled = _autoScrollEvents;
      if (enabled) {
        setState(() => _autoScrollEvents = false);
      } else {
        setState(() => _autoScrollEvents = true);
        _scheduleScrollControllerToEnd(_eventsScrollController);
      }
      _logJournalAction(
        'toggle_auto_scroll',
        context: <String, Object?>{
          'tab': 'events',
          'enabled': _autoScrollEvents,
        },
      );
    } else {
      final bool enabled = _autoScrollDiagnostics;
      if (enabled) {
        setState(() => _autoScrollDiagnostics = false);
      } else {
        setState(() => _autoScrollDiagnostics = true);
        _scheduleScrollControllerToEnd(_diagnosticsController);
      }
      _logJournalAction(
        'toggle_auto_scroll',
        context: <String, Object?>{
          'tab': 'diagnostics',
          'enabled': _autoScrollDiagnostics,
        },
      );
    }
  }

  GraphJournalViewModel _buildViewModel(GraphJournalState state) {
    return GraphJournalViewModel(
      journalState: state,
      graphController: widget.graphController,
      focusState: widget.focusState,
      focusFilterPaused: _focusFilterPaused,
      respectsGraphFilter: _journalRespectsGraphFilter,
      normalizedQuery: _normalizedJournalFilter,
    );
  }

  void _handleDisplayControllerChanged() {
    final GraphJournalDisplayController? controller = _displayController;
    if (controller == null) return;
    final GraphJournalViewModel viewModel = _buildViewModel(
      widget.controller.value,
    );
    final bool hasFiltersActive =
        viewModel.restrictsToVisibleGraph ||
        viewModel.textFilterActive ||
        viewModel.focusFilteringActive;
    final int? pending = controller.takePendingSequence();
    if (pending != null) {
      final bool scrolled = _scrollToEventSequence(pending, viewModel.events);
      if (!scrolled && hasFiltersActive) {
        setState(() => _hiddenFilteredScrollSkips += 1);
      }
    }
    final ({bool events, bool diagnostics}) disables = controller
        .takePendingAutoScrollDisables();
    if (disables.events && _autoScrollEvents) {
      setState(() => _autoScrollEvents = false);
    }
    if (disables.diagnostics && _autoScrollDiagnostics) {
      setState(() => _autoScrollDiagnostics = false);
    }
  }

  bool _scrollToEventSequence(
    int sequence,
    List<GraphJournalEventEntry> visibleEvents,
  ) {
    if (visibleEvents.isEmpty) return false;
    final int index = visibleEvents.indexWhere(
      (entry) => entry.sequence == sequence,
    );
    if (index < 0) return false;
    final double offset = index * kGraphJournalEventItemExtent;
    if (_eventsScrollController.hasClients) {
      _eventsScrollController.jumpTo(offset);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToEventSequence(sequence, visibleEvents);
        }
      });
    }
    if (_eventsRaw) {
      setState(() {
        _selectedEventSequence = sequence;
      });
    }
    return true;
  }

  bool _isAutoScrollEnabledForTab(GraphJournalTab tab) =>
      tab == GraphJournalTab.events
      ? _autoScrollEvents
      : _autoScrollDiagnostics;

  @override
  void dispose() {
    _eventsScrollController.dispose();
    _diagnosticsController.dispose();
    _journalFilterController
      ..removeListener(_handleJournalFilterChanged)
      ..dispose();
    _displayController?.removeListener(_handleDisplayControllerChanged);
    super.dispose();
  }

  void _handleJournalFilterChanged() {
    final String next = _journalFilterController.text;
    if (next == _journalFilterQuery) {
      return;
    }
    setState(() => _journalFilterQuery = next);
  }

  String get _normalizedJournalFilter =>
      _journalFilterQuery.trim().toLowerCase();

  void _logJournalAction(String action, {Map<String, Object?>? context}) =>
      widget.hostAdapter?.logAction(action: action, context: context);

  Future<void> _handleCopyVisibleLog(
    GraphJournalViewModel viewModel,
    GraphJournalTab activeTab,
  ) async {
    final bool isEventsTabActive = activeTab == GraphJournalTab.events;
    final List<GraphJournalEventEntry> events = isEventsTabActive
        ? viewModel.events
        : const <GraphJournalEventEntry>[];
    final List<GraphDiagnosticRecord> diagnostics = isEventsTabActive
        ? const <GraphDiagnosticRecord>[]
        : viewModel.diagnostics;
    await copyVisibleLog(
      events: events,
      diagnostics: diagnostics,
      includeEvents: isEventsTabActive,
      includeDiagnostics: !isEventsTabActive,
    );
    _logJournalAction(
      'copy_visible_log',
      context: <String, Object?>{
        'tab': isEventsTabActive ? 'events' : 'diagnostics',
        'events': events.length,
        'diagnostics': diagnostics.length,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: widget.padding,
      child: GraphJournalTabHost(
        initialTab: _activeTab,
        displayController: widget.displayController,
        onTabChanged: (tab) {
          setState(() {
            _activeTab = tab;
          });
        },
        builder: (context, tabController, activeTab) {
          return ValueListenableBuilder<GraphJournalState>(
            valueListenable: widget.controller,
            builder: (context, state, _) {
              final GraphJournalViewModel viewModel = GraphJournalViewModel(
                journalState: state,
                graphController: widget.graphController,
                focusState: widget.focusState,
                focusFilterPaused: _focusFilterPaused,
                respectsGraphFilter: _journalRespectsGraphFilter,
                normalizedQuery: _normalizedJournalFilter,
              );

              _maybeAutoScroll(
                visibleEvents: viewModel.events,
                visibleDiagnostics: viewModel.diagnostics,
              );
              _pruneEventDetailCache(viewModel.events);

              final bool isEventsTabActive =
                  activeTab == GraphJournalTab.events;
              final bool copyEnabled = isEventsTabActive
                  ? viewModel.events.isNotEmpty
                  : viewModel.diagnostics.isNotEmpty;

              Widget toolbar = GraphJournalToolbar(
                tabController: tabController,
                viewModel: viewModel,
                totalEventsCount: widget.totalJournalEvents,
                totalWarnCount: widget.totalWarnEvents,
                totalCriticalCount: widget.totalCriticalEvents,
                hasActiveFilters: viewModel.hasActiveFilters,
                focusFilterPaused: _focusFilterPaused,
                onFocusFilterToggle: _toggleFocusFilter,
                onClearFocus: widget.onClearFocus,
                onRemoveNodeFromFocus: widget.onRemoveNodeFromFocus,
                onRemoveEdgeFromFocus: widget.onRemoveEdgeFromFocus,
                onRevealFocus: widget.onRevealFocus,
                respectsGraphFilter: _journalRespectsGraphFilter,
                onGraphFilterToggle: _toggleJournalGraphFilter,
                isEventsTabActive: isEventsTabActive,
                isCurrentTabRaw: _isTabRaw(activeTab),
                onRawToggle: () => _toggleRawForTab(activeTab),
                autoScrollEnabled: _isAutoScrollEnabledForTab(activeTab),
                onAutoScrollPressed: () => _handleAutoScrollPressed(activeTab),
                onCopyVisibleLog: () =>
                    _handleCopyVisibleLog(viewModel, activeTab),
                copyEnabled: widget.controlsEnabled && copyEnabled,
                onClearLog: widget.controlsEnabled ? _handleClearLog : () {},
                clearEnabled:
                    widget.controlsEnabled &&
                    viewModel.underlyingJournalHasEntries,
                filterController: _journalFilterController,
                onFocusPauseTooltip: viewModel.focusContext.hasFocus
                    ? (_focusFilterPaused
                          ? 'Resume focus filtering'
                          : 'Pause focus filtering')
                    : 'No focus selection',
                controlsEnabled: widget.controlsEnabled,
                paywallTooltip: widget.paywallTooltip ?? widget.paywallLabel,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  toolbar,
                  SizedBox(height: widget.tabSpacing),
                  if (activeTab == GraphJournalTab.events &&
                      _hiddenFilteredScrollSkips > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt_off_outlined,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$_hiddenFilteredScrollSkips event(s) skipped by filters during playback/seek.',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _hiddenFilteredScrollSkips = 0),
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: activeTab.index,
                      children: [
                        GraphJournalEventList(
                          entries: viewModel.events,
                          scheme: scheme,
                          controller: _eventsScrollController,
                          onUserScrollAway: () =>
                              _handleUserScrollAway(GraphJournalTab.events),
                          onLinkTap: widget.onLinkTap,
                          onEventTap: widget.onEventTap,
                          onOpenInIde: widget.onOpenInIde,
                          emptyMessage: viewModel.eventsEmptyMessage,
                          detailsMode: _eventsRaw,
                          detailCache: _eventDetailCache,
                          detailCacheBuilder: viewModel.buildDetailCache,
                          selectedSequence: _selectedEventSequence,
                          onSelectEntry: _eventsRaw
                              ? _handleEventSelected
                              : null,
                          softLimit: widget.controller.maxEntriesSoftLimit,
                          totalTrimmed: state.totalEventsTrimmed,
                          totalAvailable: widget.virtualized
                              ? widget.totalJournalEvents
                              : null,
                          onLoadMore: widget.virtualized
                              ? widget.onRequestMoreEvents
                              : null,
                        ),
                        GraphJournalDiagnosticsList(
                          records: viewModel.diagnostics,
                          scheme: scheme,
                          controller: _diagnosticsController,
                          onUserScrollAway: () => _handleUserScrollAway(
                            GraphJournalTab.diagnostics,
                          ),
                          onLinkTap: widget.onLinkTap,
                          emptyMessage: viewModel.diagnosticsEmptyMessage,
                          onOpenDocs: widget.onOpenDiagnosticDocs,
                          forceRaw: _diagnosticsRaw,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
