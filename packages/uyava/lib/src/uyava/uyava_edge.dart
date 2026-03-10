part of 'package:uyava/uyava.dart';

/// Represents a directed edge between two nodes in the Uyava graph.
class UyavaEdge {
  final String id;
  final String from; // Source node id
  final String to; // Target node id
  final String? label;
  final String? description;

  const UyavaEdge({
    required this.id,
    required this.from,
    required this.to,
    this.label,
    this.description,
  });

  /// Converts the edge to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> raw = <String, dynamic>{
      'id': id,
      'source': from,
      'target': to,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
    };
    final UyavaEdgeSanitizationResult result = UyavaGraphEdgePayload.sanitize(
      raw,
    );
    for (final diagnostic in result.diagnostics) {
      Uyava._runtime.postDiagnosticPayload(diagnostic);
    }
    final UyavaGraphEdgePayload? payload = result.payload;
    if (!result.isValid || payload == null) {
      throw StateError('Uyava edge $id failed to sanitize.');
    }
    final Map<String, dynamic> json = payload.toJson();
    json.removeWhere((key, value) => value == null);
    return json;
  }
}
