import 'package:uyava_protocol/uyava_protocol.dart';

import 'graph_integrity.dart';
import 'node_lifecycle.dart';

/// Represents a single node in the Uyava graph.
///
/// This is a thin wrapper around the canonical wire payload defined in
/// `uyava_protocol`, keeping the core package UI-free while exposing
/// convenience accessors for layout/interaction code.
class UyavaNode {
  UyavaNode._(this.payload);

  /// Creates a node from raw JSON-like data, applying canonicalization and
  /// recording any diagnostics into [integrity].
  factory UyavaNode({
    required Map<String, dynamic> rawData,
    GraphIntegrity? integrity,
  }) {
    final UyavaNodeSanitizationResult result = UyavaGraphNodePayload.sanitize(
      rawData,
    );
    if (integrity != null) {
      for (final diagnostic in result.diagnostics) {
        integrity.addPayload(diagnostic);
      }
    }
    final UyavaGraphNodePayload? payload = result.payload;
    if (!result.isValid || payload == null) {
      throw ArgumentError('Invalid node payload: missing id');
    }
    return UyavaNode._(payload);
  }

  /// Creates a node from an already-sanitized payload.
  factory UyavaNode.fromPayload(UyavaGraphNodePayload payload) {
    return UyavaNode._(payload);
  }

  final UyavaGraphNodePayload payload;

  String get id => payload.id;
  String get type => payload.type;
  String get label => payload.label;
  String? get parentId => payload.parentId;
  NodeLifecycle get lifecycle => payload.lifecycle;

  /// Canonicalized node data for consumers that still operate on maps.
  Map<String, Object?> get data => payload.asMap();

  /// Returns a copy with an updated lifecycle.
  UyavaNode copyWithLifecycle(NodeLifecycle next) {
    return UyavaNode._(payload.copyWith(lifecycle: next));
  }

  UyavaGraphNodePayload toPayload() => payload;

  Map<String, dynamic> toJson() => payload.toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UyavaNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UyavaNode{id: $id, label: $label, parentId: $parentId, lifecycle: $lifecycle}';
  }
}
