import 'package:uyava_protocol/uyava_protocol.dart';

/// Diagnostics captured while canonicalizing graph payloads.
///
/// Hosts can read these issues to surface actionable warnings in tooling.
class GraphIntegrity {
  final List<GraphIntegrityIssue> _issues = <GraphIntegrityIssue>[];

  /// Structured list of issues detected during the last graph load.
  List<GraphIntegrityIssue> get issues => List.unmodifiable(_issues);

  /// Whether at least one issue has been recorded.
  bool get hasIssues => _issues.isNotEmpty;

  /// Removes all recorded issues.
  void clear() {
    _issues.clear();
  }

  /// Records a new issue entry.
  void add({
    required UyavaGraphIntegrityCode code,
    String? nodeId,
    String? edgeId,
    Map<String, Object?>? context,
    UyavaDiagnosticLevel? level,
  }) {
    final UyavaDiagnosticLevel resolvedLevel = level ?? code.defaultLevel;
    _issues.add(
      GraphIntegrityIssue(
        code: code,
        nodeId: nodeId,
        edgeId: edgeId,
        level: resolvedLevel,
        context: context == null ? null : Map.unmodifiable(context),
      ),
    );
  }

  /// Records a diagnostic described by the shared protocol payload.
  void addPayload(UyavaGraphDiagnosticPayload diagnostic) {
    final UyavaGraphIntegrityCode? code =
        diagnostic.codeEnum ??
        UyavaGraphIntegrityCode.fromWireString(diagnostic.code);
    if (code == null) return;
    add(
      code: code,
      nodeId: diagnostic.nodeId,
      edgeId: diagnostic.edgeId,
      context: diagnostic.context,
      level: diagnostic.level,
    );
  }

  /// Returns all issues matching the provided [code].
  List<GraphIntegrityIssue> issuesFor(UyavaGraphIntegrityCode code) {
    return _issues.where((issue) => issue.code == code).toList(growable: false);
  }
}

/// Single integrity issue for a node payload.
class GraphIntegrityIssue {
  /// Machine-readable issue code, e.g. `nodes.invalid_color`.
  final UyavaGraphIntegrityCode code;

  /// Diagnostic severity for host presentation.
  final UyavaDiagnosticLevel level;

  /// Optional node identifier associated with the issue.
  final String? nodeId;

  /// Optional edge identifier associated with the issue.
  final String? edgeId;

  /// Additional context useful for debugging (previous/next values, etc.).
  final Map<String, Object?>? context;

  const GraphIntegrityIssue({
    required this.code,
    required this.level,
    this.nodeId,
    this.edgeId,
    this.context,
  });

  /// Wire format string for serialization / logging.
  String get wireCode => code.toWireString();
}
