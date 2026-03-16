import 'package:uyava_core/uyava_core.dart';

/// Distinguishes which type of graph event produced a journal entry.
enum GraphJournalEventKind { node, edge }

/// Immutable representation of a single event entry within the shared journal.
///
/// The entry keeps the original event payload so hosts can render additional
/// detail (e.g. context menus, focus actions) without losing metadata.
class GraphJournalEventEntry {
  GraphJournalEventEntry._({
    required this.kind,
    required this.timestamp,
    required this.sequence,
    this.deltaSincePrevious,
    this.sourceId,
    this.sourceType,
    this.isolateId,
    this.isolateName,
    this.isolateNumber,
    this.nodeEvent,
    this.edgeEvent,
  }) : assert(
         (kind == GraphJournalEventKind.node && nodeEvent != null) ||
             (kind == GraphJournalEventKind.edge && edgeEvent != null),
         'Entry kind must match the supplied payload.',
       );

  factory GraphJournalEventEntry.node({
    required int sequence,
    required UyavaNodeEvent event,
    Duration? deltaSincePrevious,
  }) {
    return GraphJournalEventEntry._(
      kind: GraphJournalEventKind.node,
      timestamp: event.timestamp,
      sequence: sequence,
      deltaSincePrevious: deltaSincePrevious,
      sourceId: event.sourceId,
      sourceType: event.sourceType,
      isolateId: event.isolateId,
      isolateName: event.isolateName,
      isolateNumber: event.isolateNumber,
      nodeEvent: event,
    );
  }

  factory GraphJournalEventEntry.edge({
    required int sequence,
    required UyavaEvent event,
    Duration? deltaSincePrevious,
  }) {
    return GraphJournalEventEntry._(
      kind: GraphJournalEventKind.edge,
      timestamp: event.timestamp,
      sequence: sequence,
      deltaSincePrevious: deltaSincePrevious,
      sourceId: event.sourceId,
      sourceType: event.sourceType,
      isolateId: event.isolateId,
      isolateName: event.isolateName,
      isolateNumber: event.isolateNumber,
      edgeEvent: event,
    );
  }

  /// Identifies whether this entry describes a node or edge event.
  final GraphJournalEventKind kind;

  /// Monotonic sequence assigned by the controller to keep a stable sort key.
  final int sequence;

  /// Timestamp captured when the event was emitted.
  final DateTime timestamp;

  /// Time since the previous entry (clamped to zero on out-of-order inputs).
  final Duration? deltaSincePrevious;

  /// Ingest source identifier (Desktop-only).
  final String? sourceId;

  /// Ingest source type (Desktop-only).
  final String? sourceType;

  /// Isolate identifier for the emitting source, when available.
  final String? isolateId;

  /// Human-readable isolate name, when provided by the host.
  final String? isolateName;

  /// Numeric isolate number when supplied.
  final int? isolateNumber;

  /// Underlying node event payload when [kind] is [GraphJournalEventKind.node].
  final UyavaNodeEvent? nodeEvent;

  /// Underlying edge event payload when [kind] is [GraphJournalEventKind.edge].
  final UyavaEvent? edgeEvent;

  /// Returns the severity associated with this entry (if any).
  UyavaSeverity? get severity => switch (kind) {
    GraphJournalEventKind.node => nodeEvent?.severity,
    GraphJournalEventKind.edge => edgeEvent?.severity,
  };

  /// Returns the message attached to this entry.
  String get message => switch (kind) {
    GraphJournalEventKind.node => nodeEvent!.message,
    GraphJournalEventKind.edge => edgeEvent!.message,
  };

  GraphJournalEventEntry withDelta(Duration? delta) => switch (kind) {
    GraphJournalEventKind.node => GraphJournalEventEntry.node(
      sequence: sequence,
      event: nodeEvent!,
      deltaSincePrevious: delta,
    ),
    GraphJournalEventKind.edge => GraphJournalEventEntry.edge(
      sequence: sequence,
      event: edgeEvent!,
      deltaSincePrevious: delta,
    ),
  };
}
