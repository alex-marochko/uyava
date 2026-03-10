import '../graph_diagnostic_level.dart';

/// Canonical diagnostic codes emitted by Uyava graph validation.
///
/// Codes are serialized as `category.reason` strings to keep parity with
/// existing tooling and documentation.
enum UyavaGraphIntegrityCode {
  nodesInvalidColor('nodes.invalid_color'),
  nodesInvalidShape('nodes.invalid_shape'),
  nodesConflictingColor('nodes.conflicting_color'),
  nodesConflictingTags('nodes.conflicting_tags'),
  nodesDuplicateId('nodes.duplicate_id'),
  nodesMissingId('nodes.missing_id'),
  edgesDuplicateId('edges.duplicate_id'),
  edgesMissingId('edges.missing_id'),
  edgesMissingSource('edges.missing_source'),
  edgesMissingTarget('edges.missing_target'),
  edgesDanglingSource('edges.dangling_source'),
  edgesDanglingTarget('edges.dangling_target'),
  edgesSelfLoop('edges.self_loop'),
  metricsConflictingDefinition('metrics.conflicting_definition'),
  metricsMissingId('metrics.missing_id'),
  metricsInvalidValue('metrics.invalid_value'),
  metricsInvalidAggregator('metrics.invalid_aggregator'),
  metricsUnknownId('metrics.unknown_id'),
  chainsUnknownId('chains.unknown_id'),
  chainsUnknownStep('chains.unknown_step'),
  chainsMissingId('chains.missing_id'),
  chainsMissingTag('chains.missing_tag'),
  chainsInvalidStep('chains.invalid_step'),
  chainsConflictingDefinition('chains.conflicting_definition'),
  chainsConflictingStep('chains.conflicting_step'),
  chainsInvalidStepOrder('chains.invalid_step_order'),
  filtersInvalidPattern('filters.invalid_pattern'),
  filtersUnknownNode('filters.unknown_node'),
  filtersUnknownEdge('filters.unknown_edge'),
  filtersInvalidMode('filters.invalid_mode');

  const UyavaGraphIntegrityCode(this._wire);

  final String _wire;

  /// Returns the canonical wire-format string for the enum value.
  String toWireString() => _wire;

  /// Parses [value] by enum [name]. Returns `null` if not found.
  static UyavaGraphIntegrityCode? fromName(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final code in UyavaGraphIntegrityCode.values) {
      if (code.name == value) {
        return code;
      }
    }
    return null;
  }

  /// Parses [value] into a [UyavaGraphIntegrityCode] when possible.
  /// Returns `null` for unknown strings.
  static UyavaGraphIntegrityCode? fromWireString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final code in UyavaGraphIntegrityCode.values) {
      if (code._wire == value) {
        return code;
      }
    }
    return null;
  }
}

/// Shared policies for diagnostic codes.
extension UyavaGraphIntegrityCodePolicy on UyavaGraphIntegrityCode {
  static const Map<UyavaGraphIntegrityCode, UyavaDiagnosticLevel>
  _defaultLevels = <UyavaGraphIntegrityCode, UyavaDiagnosticLevel>{
    UyavaGraphIntegrityCode.nodesInvalidColor: UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.nodesInvalidShape: UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.nodesConflictingColor: UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.nodesConflictingTags: UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.nodesDuplicateId: UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.nodesMissingId: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.edgesDuplicateId: UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.edgesMissingId: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.edgesMissingSource: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.edgesMissingTarget: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.edgesDanglingSource: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.edgesDanglingTarget: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.edgesSelfLoop: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.metricsConflictingDefinition:
        UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.metricsMissingId: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.metricsInvalidValue: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.metricsUnknownId: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.metricsInvalidAggregator:
        UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.chainsUnknownId: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.chainsUnknownStep: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.chainsMissingId: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.chainsMissingTag: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.chainsInvalidStep: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.chainsConflictingDefinition:
        UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.chainsConflictingStep: UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.chainsInvalidStepOrder:
        UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.filtersInvalidPattern: UyavaDiagnosticLevel.error,
    UyavaGraphIntegrityCode.filtersUnknownNode: UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.filtersUnknownEdge: UyavaDiagnosticLevel.warning,
    UyavaGraphIntegrityCode.filtersInvalidMode: UyavaDiagnosticLevel.error,
  };

  /// Default diagnostic level per integrity code.
  UyavaDiagnosticLevel get defaultLevel =>
      _defaultLevels[this] ?? UyavaDiagnosticLevel.warning;

  /// Category prefix (e.g. `nodes`).
  String get category => _wire.split('.').first;

  /// Reason suffix (e.g. `invalid_color`).
  String get reason => _wire.split('.').last;
}
