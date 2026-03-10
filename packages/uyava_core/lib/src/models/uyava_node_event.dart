import 'package:uyava_protocol/uyava_protocol.dart';

/// Represents a unary event occurring on a single node.
///
/// This is UI-agnostic and suitable for recording/replay and filtering.
class UyavaNodeEvent {
  /// The ID of the node where the event occurred.
  final String nodeId;

  /// Human-readable description for the event.
  final String message;

  /// Optional severity level (e.g., [UyavaSeverity.info]).
  final UyavaSeverity? severity;

  /// Optional tags for filtering/grouping.
  final List<String>? tags;

  /// The time the event occurred.
  final DateTime timestamp;

  /// Optional source reference (e.g., 'package:feat/handler.dart:88:7')
  /// captured at the call-site that emitted this node event. UI can use this
  /// to provide "open in IDE" functionality. May be null when unavailable.
  final String? sourceRef;

  /// Identifier for the ingest source that emitted this event (Desktop only).
  final String? sourceId;

  /// Type of ingest source (e.g. vmService, replayFile). Desktop-only metadata.
  final String? sourceType;

  /// VM isolate identifier that emitted the event, when available.
  final String? isolateId;

  /// Human-readable isolate name (e.g. "ui", "io.worker.1") when available.
  final String? isolateName;

  /// Numeric isolate number when the SDK captured it (optional).
  final int? isolateNumber;

  const UyavaNodeEvent({
    required this.nodeId,
    required this.message,
    this.severity,
    this.tags,
    required this.timestamp,
    this.sourceRef,
    this.sourceId,
    this.sourceType,
    this.isolateId,
    this.isolateName,
    this.isolateNumber,
  });

  @override
  String toString() {
    final t = tags?.join(',') ?? '-';
    final sev = severity?.name ?? '-';
    final src = sourceRef ?? '-';
    final srcId = sourceId ?? '-';
    final srcType = sourceType ?? '-';
    final isoId = isolateId ?? '-';
    final isoName = isolateName ?? '-';
    final isoNum = isolateNumber?.toString() ?? '-';
    return 'UyavaNodeEvent{nodeId: $nodeId, message: $message, severity: $sev, tags: $t, sourceRef: $src, sourceId: $srcId, sourceType: $srcType, timestamp: ${timestamp.toIso8601String()}, isolateId: $isoId, isolateName: $isoName, isolateNumber: $isoNum}';
  }
}
