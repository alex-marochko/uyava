import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uyava_core/uyava_core.dart';

import 'journal_entry.dart';

/// Immutable snapshot of the journal state consumed by the panel widget.
@immutable
class GraphJournalState {
  const GraphJournalState({
    required this.events,
    required this.diagnostics,
    required this.eventsTrimmed,
    required this.totalEventsTrimmed,
  });

  /// Latest event entries (newest first).
  final List<GraphJournalEventEntry> events;

  /// Latest diagnostics records (oldest-to-newest as provided by the buffer).
  final List<GraphDiagnosticRecord> diagnostics;

  /// Becomes true once the controller trims older entries to honor the soft limit.
  final bool eventsTrimmed;

  /// Total number of entries trimmed from the buffer since startup.
  final int totalEventsTrimmed;

  static const empty = GraphJournalState(
    events: <GraphJournalEventEntry>[],
    diagnostics: <GraphDiagnosticRecord>[],
    eventsTrimmed: false,
    totalEventsTrimmed: 0,
  );

  GraphJournalState copyWith({
    List<GraphJournalEventEntry>? events,
    List<GraphDiagnosticRecord>? diagnostics,
    bool? eventsTrimmed,
    int? totalEventsTrimmed,
  }) {
    return GraphJournalState(
      events: events ?? this.events,
      diagnostics: diagnostics ?? this.diagnostics,
      eventsTrimmed: eventsTrimmed ?? this.eventsTrimmed,
      totalEventsTrimmed: totalEventsTrimmed ?? this.totalEventsTrimmed,
    );
  }
}

/// Central coordinator that keeps the shared event + diagnostics journal in sync
/// with the underlying [GraphController].
///
/// Hosts forward node/edge events via [addNodeEvent] / [addEdgeEvent]. The
/// controller listens to [GraphController.diagnosticsStream] automatically so
/// diagnostics stay synchronized without manual plumbing.
class GraphJournalController extends ValueNotifier<GraphJournalState> {
  GraphJournalController({
    required GraphController graphController,
    int maxEntriesSoftLimit = 20000,
  }) : _graphController = graphController,
       maxEntriesSoftLimit = maxEntriesSoftLimit <= 0 ? 0 : maxEntriesSoftLimit,
       _eventsBuffer = <GraphJournalEventEntry>[],
       _startIndex = 0,
       super(
         GraphJournalState(
           events: const <GraphJournalEventEntry>[],
           diagnostics: List<GraphDiagnosticRecord>.unmodifiable(
             graphController.diagnostics.records,
           ),
           eventsTrimmed: false,
           totalEventsTrimmed: 0,
         ),
       ) {
    _diagnosticsSub = _graphController.diagnosticsStream.listen(
      _handleDiagnosticsUpdate,
    );
  }

  final GraphController _graphController;
  final int maxEntriesSoftLimit;
  List<GraphJournalEventEntry> _eventsBuffer;
  int _startIndex;
  StreamSubscription<List<GraphDiagnosticRecord>>? _diagnosticsSub;
  int _eventSequence = 0;
  static const int _trimChunkSize = 1024;
  static const int _bufferCompactionThreshold = _trimChunkSize * 4;

  bool get hasEvents => value.events.isNotEmpty;

  bool get hasDiagnostics => value.diagnostics.isNotEmpty;

  UnmodifiableListView<GraphJournalEventEntry> get events =>
      UnmodifiableListView<GraphJournalEventEntry>(value.events);

  UnmodifiableListView<GraphDiagnosticRecord> get diagnostics =>
      UnmodifiableListView<GraphDiagnosticRecord>(value.diagnostics);

  /// Appends a node event to the journal.
  void addNodeEvent(UyavaNodeEvent event) {
    _addEvent(
      GraphJournalEventEntry.node(
        sequence: _eventSequence++,
        event: event,
        deltaSincePrevious: _deltaSinceLast(event.timestamp),
      ),
    );
  }

  /// Appends an edge event to the journal.
  void addEdgeEvent(UyavaEvent event) {
    _addEvent(
      GraphJournalEventEntry.edge(
        sequence: _eventSequence++,
        event: event,
        deltaSincePrevious: _deltaSinceLast(event.timestamp),
      ),
    );
  }

  /// Removes all recorded event entries.
  void clearEvents() {
    if (_eventsBuffer.isEmpty && value.events.isEmpty) return;
    _eventsBuffer = <GraphJournalEventEntry>[];
    _startIndex = 0;
    value = value.copyWith(
      events: const <GraphJournalEventEntry>[],
      eventsTrimmed: false,
      totalEventsTrimmed: 0,
    );
  }

  /// Clears the entire journal, including diagnostics.
  void clearLog() {
    clearEvents();
    _graphController.clearDiagnostics();
  }

  /// Replaces the diagnostics list with the latest controller snapshot.
  void refreshDiagnostics() {
    _handleDiagnosticsUpdate(_graphController.diagnostics.records);
  }

  void _addEvent(GraphJournalEventEntry entry) {
    _eventsBuffer.add(entry);
    bool trimmed = value.eventsTrimmed;
    int totalTrimmed = value.totalEventsTrimmed;
    final int limit = maxEntriesSoftLimit;
    if (limit > 0) {
      final int removed = _trimToSoftLimit(limit);
      if (removed > 0) {
        trimmed = true;
        totalTrimmed += removed;
      }
    }
    value = value.copyWith(
      events: _eventsBuffer.isEmpty || _startIndex >= _eventsBuffer.length
          ? const <GraphJournalEventEntry>[]
          : _JournalEntriesView(
              _eventsBuffer,
              _startIndex,
              _eventsBuffer.length - _startIndex,
            ),
      eventsTrimmed: trimmed,
      totalEventsTrimmed: totalTrimmed,
    );
  }

  int _trimToSoftLimit(int limit) {
    int available = _eventsBuffer.length - _startIndex;
    if (available <= limit) {
      return 0;
    }
    int removed = 0;
    while (available > limit) {
      final int excess = available - limit;
      final int step = math.min(_trimChunkSize, excess);
      _startIndex += step;
      removed += step;
      available -= step;

      if (_startIndex < _eventsBuffer.length) {
        final GraphJournalEventEntry first = _eventsBuffer[_startIndex];
        if (first.deltaSincePrevious != null) {
          _eventsBuffer[_startIndex] = first.withDelta(null);
        }
      }

      if (_startIndex >= _bufferCompactionThreshold &&
          _eventsBuffer.length > _trimChunkSize) {
        final int drop = math.min(_trimChunkSize, _startIndex);
        _eventsBuffer.removeRange(0, drop);
        _startIndex -= drop;
      }
    }
    return removed;
  }

  void _handleDiagnosticsUpdate(List<GraphDiagnosticRecord> records) {
    value = value.copyWith(
      diagnostics: List<GraphDiagnosticRecord>.unmodifiable(records),
    );
  }

  @override
  void dispose() {
    _diagnosticsSub?.cancel();
    super.dispose();
  }

  Duration? _deltaSinceLast(DateTime timestamp) {
    if (value.events.isEmpty) return null;
    final DateTime previous = value.events.last.timestamp;
    final Duration diff = timestamp.difference(previous);
    if (diff.isNegative) {
      return Duration.zero;
    }
    return diff;
  }
}

class _JournalEntriesView extends ListBase<GraphJournalEventEntry> {
  _JournalEntriesView(this._buffer, this._offset, this._length);

  final List<GraphJournalEventEntry> _buffer;
  final int _offset;
  final int _length;

  @override
  int get length => _length;

  @override
  set length(int value) =>
      throw UnsupportedError('GraphJournal entries are immutable.');

  @override
  GraphJournalEventEntry operator [](int index) => _buffer[_offset + index];

  @override
  void operator []=(int index, GraphJournalEventEntry value) =>
      throw UnsupportedError('GraphJournal entries are immutable.');
}
