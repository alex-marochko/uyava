import 'dart:collection';

import 'package:uyava_core/uyava_core.dart';

import '../focus_controller.dart';
import 'journal_actions.dart';
import 'journal_controller.dart';
import 'journal_entry.dart';
import 'journal_link.dart';

part 'journal_view_model_focus.dart';
part 'journal_view_model_filters.dart';
part 'journal_view_model_details.dart';

/// Holds all derived data needed by the journal panel after filters are applied.
class GraphJournalViewModel {
  GraphJournalViewModel({
    required GraphJournalState journalState,
    required GraphController graphController,
    required GraphFocusState focusState,
    required bool focusFilterPaused,
    required bool respectsGraphFilter,
    required String normalizedQuery,
  }) : _graphController = graphController,
       _journalState = journalState,
       _normalizedQuery = normalizedQuery {
    focusContext = GraphJournalFocusContext.fromGraph(
      focusState: focusState,
      nodes: graphController.nodes,
      edges: graphController.edges,
    );
    _focusFilteringActive = focusContext.hasFocus && !focusFilterPaused;
    _textFilterActive = normalizedQuery.isNotEmpty;
    _restrictToVisibleGraph = respectsGraphFilter;
    _build();
  }

  final GraphController _graphController;
  final GraphJournalState _journalState;
  final String _normalizedQuery;

  late final GraphJournalFocusContext focusContext;
  late final bool _focusFilteringActive;
  late final bool _textFilterActive;
  late final bool _restrictToVisibleGraph;
  late final List<GraphJournalEventEntry> _visibleEvents;
  late final List<GraphDiagnosticRecord> _visibleDiagnostics;
  late final int _diagnosticsAttentionCount;

  /// Events visible after every filter is applied.
  List<GraphJournalEventEntry> get events => _visibleEvents;

  /// Diagnostics visible after every filter is applied.
  List<GraphDiagnosticRecord> get diagnostics => _visibleDiagnostics;

  bool get focusFilteringActive => _focusFilteringActive;

  bool get textFilterActive => _textFilterActive;

  bool get restrictsToVisibleGraph => _restrictToVisibleGraph;

  bool get hasVisibleEntries => events.isNotEmpty || diagnostics.isNotEmpty;

  bool get underlyingJournalHasEntries =>
      _journalState.events.isNotEmpty || _journalState.diagnostics.isNotEmpty;

  GraphJournalSeverityTally get severityTally =>
      GraphJournalSeverityTally.fromEntries(events);

  int get diagnosticsAttentionCount => _diagnosticsAttentionCount;

  bool get hasActiveFilters {
    final bool graphFiltersActive =
        _restrictToVisibleGraph &&
        _graphController.filters != GraphFilterState.empty;
    return graphFiltersActive || _focusFilteringActive || _textFilterActive;
  }

  String get eventsEmptyMessage => _buildEmptyMessage(
    emptyDescription: 'graph events',
    noneRecorded: 'No graph events yet.',
  );

  String get diagnosticsEmptyMessage => _buildEmptyMessage(
    emptyDescription: 'diagnostics',
    noneRecorded: 'No diagnostics recorded.',
  );

  String get focusSummaryLabel => focusContext.summaryLabel;

  GraphJournalEventDetailCache buildDetailCache(GraphJournalEventEntry entry) {
    return buildJournalEventDetailCache(entry);
  }

  GraphJournalEventDetailCache ensureDetailCache(
    Map<int, GraphJournalEventDetailCache> cache,
    GraphJournalEventEntry entry,
  ) {
    return cache.putIfAbsent(entry.sequence, () => buildDetailCache(entry));
  }

  String _buildEmptyMessage({
    required String emptyDescription,
    required String noneRecorded,
  }) {
    if (textFilterActive && focusFilteringActive) {
      return 'No $emptyDescription match the focus/text filters.';
    }
    if (textFilterActive) {
      return 'No $emptyDescription match the text filter.';
    }
    if (focusFilteringActive) {
      return 'No $emptyDescription match the current focus.';
    }
    return noneRecorded;
  }

  void _build() {
    List<GraphJournalEventEntry> visibleEvents = _journalState.events;
    List<GraphDiagnosticRecord> visibleDiagnostics = _journalState.diagnostics;

    final GraphFilterSeverity? severityFilter =
        _graphController.filters.severity;

    if (_restrictToVisibleGraph) {
      final GraphFilterResult filterResult = _graphController.filterResult;
      final Set<String> knownNodeIds = {
        for (final UyavaNode node in _graphController.nodes) node.id,
      };
      final Set<String> knownEdgeIds = {
        for (final UyavaEdge edge in _graphController.edges) edge.id,
      };
      visibleEvents = _filterEventsByGraphVisibility(
        visibleEvents,
        filterResult.visibleNodeIds,
        knownNodeIds: knownNodeIds,
      );
      visibleDiagnostics = _filterDiagnosticsByGraphVisibility(
        visibleDiagnostics,
        filterResult.visibleNodeIds,
        filterResult.visibleEdgeIds,
        knownNodeIds: knownNodeIds,
        knownEdgeIds: knownEdgeIds,
      );
      if (severityFilter != null) {
        visibleEvents = _filterEventsBySeverity(visibleEvents, severityFilter);
      }
    }

    if (_focusFilteringActive) {
      visibleEvents = _filterEventsByFocus(visibleEvents, focusContext);
      visibleDiagnostics = _filterDiagnosticsByFocus(
        visibleDiagnostics,
        focusContext,
      );
    }

    if (_textFilterActive) {
      visibleEvents = _filterEventsByQuery(visibleEvents, _normalizedQuery);
      visibleDiagnostics = _filterDiagnosticsByQuery(
        visibleDiagnostics,
        _normalizedQuery,
      );
    }

    _visibleEvents = visibleEvents;
    _visibleDiagnostics = visibleDiagnostics;
    _diagnosticsAttentionCount = _countDiagnosticsRequiringAttention(
      _visibleDiagnostics,
    );
  }
}

class GraphJournalSeverityTally {
  const GraphJournalSeverityTally({
    required this.warnCount,
    required this.criticalCount,
  });

  final int warnCount;
  final int criticalCount;

  factory GraphJournalSeverityTally.fromEntries(
    Iterable<GraphJournalEventEntry> entries,
  ) {
    int warn = 0;
    int critical = 0;
    for (final GraphJournalEventEntry entry in entries) {
      final UyavaSeverity? severity = entry.severity;
      if (severity == UyavaSeverity.warn) {
        warn++;
      } else if (severity == UyavaSeverity.error ||
          severity == UyavaSeverity.fatal) {
        critical++;
      }
    }
    return GraphJournalSeverityTally(warnCount: warn, criticalCount: critical);
  }
}
