import 'package:uyava_protocol/uyava_protocol.dart';

/// Represents a real-time event occurring between two nodes.
class UyavaEvent {
  /// The ID of the source node of the event.
  final String from;

  /// The ID of the target node of the event.
  final String to;

  /// Human-readable description for the event.
  final String message;

  /// The time the event occurred.
  final DateTime timestamp;

  /// Optional severity level (e.g., [UyavaSeverity.info]).
  /// When null, UI should fall back to default coloring.
  final UyavaSeverity? severity;

  /// Optional source reference (e.g., 'package:feat/usecase.dart:123:5')
  /// captured at the call-site that emitted this event. UI can use this to
  /// provide "open in IDE" functionality. May be null when unavailable.
  final String? sourceRef;

  /// Identifier for the ingest source that emitted this event (e.g., router id).
  /// Used by Desktop to disambiguate multiple feeds.
  final String? sourceId;

  /// Type of ingest source (e.g. vmService, replayFile). Desktop-only metadata.
  final String? sourceType;

  /// VM isolate identifier that emitted the event, when available.
  final String? isolateId;

  /// Human-readable isolate name (e.g. "ui", "io.worker.1") when available.
  final String? isolateName;

  /// Numeric isolate number when available.
  final int? isolateNumber;

  UyavaEvent({
    required this.from,
    required this.to,
    required this.message,
    required this.timestamp,
    this.severity,
    this.sourceRef,
    this.sourceId,
    this.sourceType,
    this.isolateId,
    this.isolateName,
    this.isolateNumber,
  });

  @override
  String toString() {
    final sev = severity?.name ?? '-';
    final src = sourceRef ?? '-';
    final srcId = sourceId ?? '-';
    final srcType = sourceType ?? '-';
    final isoId = isolateId ?? '-';
    final isoName = isolateName ?? '-';
    final isoNum = isolateNumber?.toString() ?? '-';
    return 'UyavaEvent{from: $from, to: $to, message: $message, severity: $sev, sourceRef: $src, sourceId: $srcId, sourceType: $srcType, timestamp: $timestamp, isolateId: $isoId, isolateName: $isoName, isolateNumber: $isoNum}';
  }
}
