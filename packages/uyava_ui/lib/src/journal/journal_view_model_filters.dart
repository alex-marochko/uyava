part of 'journal_view_model.dart';

List<GraphJournalEventEntry> _filterEventsByGraphVisibility(
  List<GraphJournalEventEntry> entries,
  Set<String> visibleNodeIds, {
  required Set<String> knownNodeIds,
}) {
  if (visibleNodeIds.isEmpty) {
    if (knownNodeIds.isEmpty) {
      return entries;
    }
    return const <GraphJournalEventEntry>[];
  }
  return entries
      .where((entry) {
        switch (entry.kind) {
          case GraphJournalEventKind.node:
            final String id = entry.nodeEvent!.nodeId;
            if (!knownNodeIds.contains(id)) return true;
            return visibleNodeIds.contains(id);
          case GraphJournalEventKind.edge:
            final UyavaEvent event = entry.edgeEvent!;
            final bool fromKnown = knownNodeIds.contains(event.from);
            final bool toKnown = knownNodeIds.contains(event.to);
            if (!fromKnown || !toKnown) return true;
            return visibleNodeIds.contains(event.from) &&
                visibleNodeIds.contains(event.to);
        }
      })
      .toList(growable: false);
}

List<GraphDiagnosticRecord> _filterDiagnosticsByGraphVisibility(
  List<GraphDiagnosticRecord> records,
  Set<String> visibleNodeIds,
  Set<String> visibleEdgeIds, {
  required Set<String> knownNodeIds,
  required Set<String> knownEdgeIds,
}) {
  if (records.isEmpty) {
    return const <GraphDiagnosticRecord>[];
  }
  return records
      .where((record) {
        if (record.subjects.isEmpty) {
          return true;
        }
        bool subjectKnown = false;
        for (final String subject in record.subjects) {
          if (_subjectWithinVisibleGraph(
            subject,
            visibleNodeIds: visibleNodeIds,
            visibleEdgeIds: visibleEdgeIds,
          )) {
            return true;
          }
          if (_subjectKnownInGraph(
            subject,
            knownNodeIds: knownNodeIds,
            knownEdgeIds: knownEdgeIds,
          )) {
            subjectKnown = true;
          }
        }
        return !subjectKnown;
      })
      .toList(growable: false);
}

List<GraphJournalEventEntry> _filterEventsByFocus(
  List<GraphJournalEventEntry> entries,
  GraphJournalFocusContext focus,
) {
  return entries
      .where((entry) {
        switch (entry.kind) {
          case GraphJournalEventKind.node:
            return focus.nodeIds.contains(entry.nodeEvent!.nodeId);
          case GraphJournalEventKind.edge:
            final UyavaEvent event = entry.edgeEvent!;
            if (focus.containsEdgePair(event.from, event.to)) {
              return true;
            }
            return focus.nodeIds.contains(event.from) ||
                focus.nodeIds.contains(event.to);
        }
      })
      .toList(growable: false);
}

List<GraphDiagnosticRecord> _filterDiagnosticsByFocus(
  List<GraphDiagnosticRecord> records,
  GraphJournalFocusContext focus,
) {
  return records
      .where((record) {
        if (record.subjects.isEmpty) return false;
        for (final String subject in record.subjects) {
          if (_subjectMatchesFocus(subject, focus)) {
            return true;
          }
        }
        return false;
      })
      .toList(growable: false);
}

bool _subjectMatchesFocus(String subject, GraphJournalFocusContext focus) {
  if (focus.nodeIds.contains(subject) || focus.edgeIds.contains(subject)) {
    return true;
  }
  if (subject.startsWith('node:') &&
      focus.nodeIds.contains(subject.substring(5))) {
    return true;
  }
  if (subject.startsWith('edge:') &&
      focus.edgeIds.contains(subject.substring(5))) {
    return true;
  }
  final int arrowIndex = subject.indexOf('->');
  if (arrowIndex > 0) {
    final String left = subject.substring(0, arrowIndex).trim();
    final String right = subject.substring(arrowIndex + 2).trim();
    if (focus.containsEdgePair(left, right)) {
      return true;
    }
  }
  return false;
}

List<GraphJournalEventEntry> _filterEventsByQuery(
  List<GraphJournalEventEntry> entries,
  String query,
) {
  if (entries.isEmpty || query.isEmpty) {
    return entries;
  }
  return entries
      .where((entry) => _eventMatchesQuery(entry, query))
      .toList(growable: false);
}

List<GraphDiagnosticRecord> _filterDiagnosticsByQuery(
  List<GraphDiagnosticRecord> records,
  String query,
) {
  if (records.isEmpty || query.isEmpty) {
    return records;
  }
  return records
      .where((record) => _diagnosticMatchesQuery(record, query))
      .toList(growable: false);
}

bool _eventMatchesQuery(GraphJournalEventEntry entry, String query) {
  if (_containsIgnoreCase(entry.message, query)) {
    return true;
  }
  switch (entry.kind) {
    case GraphJournalEventKind.node:
      final UyavaNodeEvent event = entry.nodeEvent!;
      return _containsIgnoreCase(event.nodeId, query) ||
          _iterableContainsIgnoreCase(event.tags, query) ||
          _containsIgnoreCase(event.isolateName, query) ||
          _containsIgnoreCase(event.sourceRef, query);
    case GraphJournalEventKind.edge:
      final UyavaEvent event = entry.edgeEvent!;
      return _containsIgnoreCase(event.from, query) ||
          _containsIgnoreCase(event.to, query) ||
          _containsIgnoreCase(event.sourceRef, query) ||
          _containsIgnoreCase(event.isolateName, query);
  }
}

bool _diagnosticMatchesQuery(GraphDiagnosticRecord record, String query) {
  if (_containsIgnoreCase(record.code, query)) {
    return true;
  }
  if (record.codeEnum != null &&
      _containsIgnoreCase(record.codeEnum!.name, query)) {
    return true;
  }
  if (_containsIgnoreCase(record.source.name, query)) {
    return true;
  }
  if (_iterableContainsIgnoreCase(record.subjects, query)) {
    return true;
  }
  if (record.context != null) {
    for (final MapEntry<String, Object?> entry in record.context!.entries) {
      if (_containsIgnoreCase(entry.key, query)) {
        return true;
      }
      final Object? value = entry.value;
      if (value == null) continue;
      if (_containsIgnoreCase(value.toString(), query)) {
        return true;
      }
    }
  }
  return false;
}

bool _containsIgnoreCase(String? value, String query) {
  if (value == null || value.isEmpty) {
    return false;
  }
  return value.toLowerCase().contains(query);
}

bool _iterableContainsIgnoreCase(Iterable<String>? values, String query) {
  if (values == null) {
    return false;
  }
  for (final String value in values) {
    if (_containsIgnoreCase(value, query)) {
      return true;
    }
  }
  return false;
}

List<GraphJournalEventEntry> _filterEventsBySeverity(
  List<GraphJournalEventEntry> entries,
  GraphFilterSeverity severity,
) {
  if (entries.isEmpty) {
    return const <GraphJournalEventEntry>[];
  }
  return entries
      .where((entry) => severity.matches(entry.severity))
      .toList(growable: false);
}

bool _subjectWithinVisibleGraph(
  String subject, {
  required Set<String> visibleNodeIds,
  required Set<String> visibleEdgeIds,
}) {
  if (visibleNodeIds.contains(subject) || visibleEdgeIds.contains(subject)) {
    return true;
  }
  if (subject.startsWith('node:')) {
    return visibleNodeIds.contains(subject.substring(5));
  }
  if (subject.startsWith('edge:')) {
    return visibleEdgeIds.contains(subject.substring(5));
  }
  final int arrowIndex = subject.indexOf('->');
  if (arrowIndex > 0) {
    final String left = subject.substring(0, arrowIndex).trim();
    final String right = subject.substring(arrowIndex + 2).trim();
    return visibleNodeIds.contains(left) && visibleNodeIds.contains(right);
  }
  return false;
}

bool _subjectKnownInGraph(
  String subject, {
  required Set<String> knownNodeIds,
  required Set<String> knownEdgeIds,
}) {
  if (knownNodeIds.contains(subject) || knownEdgeIds.contains(subject)) {
    return true;
  }
  if (subject.startsWith('node:')) {
    return knownNodeIds.contains(subject.substring(5));
  }
  if (subject.startsWith('edge:')) {
    return knownEdgeIds.contains(subject.substring(5));
  }
  final int arrowIndex = subject.indexOf('->');
  if (arrowIndex > 0) {
    final String left = subject.substring(0, arrowIndex).trim();
    final String right = subject.substring(arrowIndex + 2).trim();
    return knownNodeIds.contains(left) || knownEdgeIds.contains(right);
  }
  return false;
}

int _countDiagnosticsRequiringAttention(
  Iterable<GraphDiagnosticRecord> diagnostics,
) {
  int count = 0;
  for (final GraphDiagnosticRecord record in diagnostics) {
    if (record.level == UyavaDiagnosticLevel.warning ||
        record.level == UyavaDiagnosticLevel.error) {
      count++;
    }
  }
  return count;
}
