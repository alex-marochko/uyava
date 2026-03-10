part of 'package:uyava/uyava.dart';

/// Represents a node in the Uyava graph.
///
/// Use this class to define a static component of your application's architecture.
class UyavaNode {
  final String id;
  final String type;
  final String? label;
  final String? description;
  final String? parentId;
  final List<String>? tags;
  final String? color;
  final String? shape;

  /// Creates a node with a custom string type.
  ///
  /// Consider using [UyavaNode.standard] for type-safety and consistent styling.
  const UyavaNode({
    required this.id,
    this.type = 'unknown',
    this.label,
    this.description,
    this.parentId,
    this.tags,
    this.color,
    this.shape,
  });

  /// Creates a node using a predefined, standard type for consistent styling
  /// and semantic analysis by the DevTools extension.
  UyavaNode.standard({
    required this.id,
    required UyavaStandardType standardType,
    this.label,
    this.description,
    this.parentId,
    this.tags,
    this.color,
    this.shape,
  }) : type = standardType.name;

  /// Converts the node to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> raw = <String, dynamic>{
      'id': id,
      'type': type,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (parentId != null) 'parentId': parentId,
      if (tags != null) 'tags': tags,
      if (color != null) 'color': color,
      if (shape != null) 'shape': shape,
    };

    final UyavaNodeSanitizationResult result = UyavaGraphNodePayload.sanitize(
      raw,
    );
    final UyavaGraphNodePayload? payload = result.payload;
    for (final diagnostic in result.diagnostics) {
      final UyavaGraphIntegrityCode? codeEnum = diagnostic.codeEnum;
      if (codeEnum == UyavaGraphIntegrityCode.nodesInvalidColor) {
        developer.log(
          'Uyava node color ignored for $id: invalid format (${diagnostic.context?['value']})',
          name: 'Uyava',
        );
      } else if (codeEnum == UyavaGraphIntegrityCode.nodesInvalidShape) {
        developer.log(
          'Uyava node shape ignored for $id: invalid identifier (${diagnostic.context?['value']})',
          name: 'Uyava',
        );
      }
      Uyava._runtime.postDiagnosticPayload(diagnostic);
    }
    if (!result.isValid || payload == null) {
      throw StateError('Uyava node $id failed to sanitize.');
    }
    final Map<String, dynamic> json = payload.toJson();
    json.removeWhere((key, value) => value == null);
    return json;
  }
}
