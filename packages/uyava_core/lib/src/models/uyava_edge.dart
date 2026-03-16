import 'package:uyava_protocol/uyava_protocol.dart';

import 'graph_integrity.dart';

/// Represents a single directed edge in the Uyava graph.
class UyavaEdge {
  UyavaEdge._(this.payload);

  /// Constructs an edge from raw JSON-like data, applying canonicalization
  /// and recording diagnostics into [integrity].
  factory UyavaEdge({
    required Map<String, dynamic> data,
    GraphIntegrity? integrity,
  }) {
    final UyavaEdgeSanitizationResult result = UyavaGraphEdgePayload.sanitize(
      data,
    );
    if (integrity != null) {
      for (final diagnostic in result.diagnostics) {
        integrity.addPayload(diagnostic);
      }
    }
    final UyavaGraphEdgePayload? payload = result.payload;
    if (!result.isValid || payload == null) {
      throw ArgumentError('Invalid edge payload: missing id/source/target');
    }
    return UyavaEdge._(payload);
  }

  /// Creates an edge from an already sanitized payload.
  factory UyavaEdge.fromPayload(UyavaGraphEdgePayload payload) {
    return UyavaEdge._(payload);
  }

  final UyavaGraphEdgePayload payload;

  String get id => payload.id;
  String get source => payload.source;
  String get target => payload.target;

  bool get isBidirectional => payload.bidirectional;
  bool get isRemapped => payload.remapped;

  /// Canonicalized map representation for legacy consumers.
  Map<String, Object?> get data {
    final Map<String, Object?> json = Map<String, Object?>.from(
      payload.toJson(),
    );
    json.removeWhere((key, value) => value == null);
    return Map<String, Object?>.unmodifiable(json);
  }

  UyavaGraphEdgePayload toPayload() => payload;

  Map<String, dynamic> toJson() => payload.toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UyavaEdge && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UyavaEdge{id: $id, source: $source, target: $target}';
  }
}
