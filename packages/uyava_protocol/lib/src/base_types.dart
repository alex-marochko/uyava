/// Canonical event type strings used across SDK and hosts.
class UyavaEventTypes {
  static const String replaceGraph = 'replaceGraph';
  static const String loadGraph = 'loadGraph';
  static const String addNode = 'addNode';
  static const String addEdge = 'addEdge';
  static const String removeNode = 'removeNode';
  static const String removeEdge = 'removeEdge';
  static const String patchNode = 'patchNode';
  static const String patchEdge = 'patchEdge';
  static const String edgeEvent = 'edgeEvent';
  static const String animation = 'animation'; // legacy alias
  static const String nodeEvent = 'nodeEvent';
  static const String nodeLifecycle = 'nodeLifecycle';
  static const String graphDiagnostics = 'graphDiagnostics';
  static const String clearDiagnostics = 'clearDiagnostics';
  static const String defineMetric = 'defineMetric';
  static const String defineEventChain = 'defineEventChain';
  static const String updateGraphFilters = 'updateGraphFilters';
  // Reserved for upcoming replay/REST ingest wrappers; ignored by current hosts.
  static const String replayChunk = 'replayChunk';
  static const String restEnvelope = 'restEnvelope';
}

/// Lifecycle states emitted by apps for graph nodes.
/// Serialized on the wire via [name].
enum UyavaLifecycleState { unknown, initialized, disposed }

/// Severity levels for node and edge events.
/// Serialized on the wire via [name].
///
/// Order: trace < debug < info < warn < error < fatal
enum UyavaSeverity { trace, debug, info, warn, error, fatal }

/// Canonical optional payload keys used across hosts/SDK for developer navigation.
/// These are debug/profile-only metadata fields and may be absent.
class UyavaPayloadKeys {
  /// Node init call-site captured when adding a node to the graph.
  /// Value format: compact string 'package:foo/bar.dart:LINE:COLUMN'.
  static const String initSource = 'initSource';

  /// Generic call-site captured when emitting an event (edge/node).
  /// Value format: compact string 'package:foo/bar.dart:LINE:COLUMN'.
  static const String sourceRef = 'sourceRef';
}

/// Supported aggregation strategies for metrics.
/// Serialized via [name].
enum UyavaMetricAggregator { last, min, max, sum, count }

extension UyavaMetricAggregatorCodec on UyavaMetricAggregator {
  String toWireString() => name;

  static UyavaMetricAggregator? fromWireString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final candidate in UyavaMetricAggregator.values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }
}

/// Search strategy used in filter commands.
enum UyavaFilterSearchMode { substring, mask, regex }

extension UyavaFilterSearchModeCodec on UyavaFilterSearchMode {
  String toWireString() => name;

  static UyavaFilterSearchMode? fromWireString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final candidate in UyavaFilterSearchMode.values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }
}

/// Tag filter mode (include/exclude/exact).
enum UyavaFilterTagsMode { include, exclude, exact }

extension UyavaFilterTagsModeCodec on UyavaFilterTagsMode {
  String toWireString() => name;

  static UyavaFilterTagsMode? fromWireString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final candidate in UyavaFilterTagsMode.values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }
}

/// Logical strategy for tag filters.
enum UyavaFilterTagLogic { any, all }

extension UyavaFilterTagLogicCodec on UyavaFilterTagLogic {
  String toWireString() => name;

  static UyavaFilterTagLogic? fromWireString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final candidate in UyavaFilterTagLogic.values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }
}

/// Grouping strategies for graph views.
enum UyavaFilterGroupingMode { none, level }

extension UyavaFilterGroupingModeCodec on UyavaFilterGroupingMode {
  String toWireString() => name;

  static UyavaFilterGroupingMode? fromWireString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final candidate in UyavaFilterGroupingMode.values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }
}

/// Comparison operators for severity filters.
enum UyavaFilterSeverityOperator { atLeast, atMost, exact }

extension UyavaFilterSeverityOperatorCodec on UyavaFilterSeverityOperator {
  String toWireString() => name;

  static UyavaFilterSeverityOperator? fromWireString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final candidate in UyavaFilterSeverityOperator.values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }
}
