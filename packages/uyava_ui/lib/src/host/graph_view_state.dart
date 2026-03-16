import 'package:uyava_core/uyava_core.dart';

/// Tracks transient visibility of edge and node badges.
class GraphLabelState {
  GraphLabelState({required this.visible, required this.changedAt});

  bool visible;
  DateTime changedAt;
}

/// Arrival metadata for aggregated edge events.
class GraphEdgeArrival {
  GraphEdgeArrival(this.timestamp, this.severity);

  final DateTime timestamp;
  final UyavaSeverity? severity;
}

/// Shared state container for coordinated graph views.
class GraphViewState {
  Map<String, dynamic>? lastGraphPayload;
  final Map<String, NodeLifecycle> nodeLifecycleOverrides =
      <String, NodeLifecycle>{};
  final Map<String, Map<String, dynamic>> metricDefinitionsById =
      <String, Map<String, dynamic>>{};

  final List<UyavaEvent> edgeEvents = <UyavaEvent>[];
  final List<UyavaNodeEvent> nodeEvents = <UyavaNodeEvent>[];
  final Map<String, List<DateTime>> arrivalsByDirection =
      <String, List<DateTime>>{};
  final Map<String, List<GraphEdgeArrival>> arrivalsByVisibleDirection =
      <String, List<GraphEdgeArrival>>{};
  final Set<String> activeVisibleDirections = <String>{};
  final Map<String, GraphLabelState> edgeLabelStates =
      <String, GraphLabelState>{};
  final Map<String, int> edgeLabelLastCount = <String, int>{};
  final Map<String, GraphLabelState> nodeBadgeStates =
      <String, GraphLabelState>{};
  final Map<String, int> nodeBadgeLastCount = <String, int>{};
}
