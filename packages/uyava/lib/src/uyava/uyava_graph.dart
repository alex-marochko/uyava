part of 'package:uyava/uyava.dart';

class _MetricNormalizationResult {
  const _MetricNormalizationResult({this.replacement, this.remove = false});

  final Map<String, dynamic>? replacement;
  final bool remove;
}

class _IndexedNode {
  const _IndexedNode({required this.node, required this.index});

  final UyavaNode node;
  final int index;
}

class _IndexedEdge {
  const _IndexedEdge({required this.edge, required this.index});

  final UyavaEdge edge;
  final int index;
}

/// A private class to hold the state of the graph.
class _UyavaGraph {
  final Map<String, UyavaNode> nodes = {};
  final Map<String, UyavaEdge> edges = {};
  final Map<String, UyavaMetricDefinitionPayload> metricDefinitions = {};
  final Map<String, UyavaEventChainDefinitionPayload> eventChainDefinitions =
      {};
}
