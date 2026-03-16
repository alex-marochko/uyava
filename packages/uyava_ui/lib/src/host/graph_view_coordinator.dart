import 'package:flutter/widgets.dart';
import 'package:uyava_core/uyava_core.dart';
import '../adapters.dart';
import '../config.dart';
import '../focus_controller.dart';
import '../journal/journal_host_adapter.dart';
import '../journal/journal_tabs.dart';
import '../layout_sizer.dart';
import '../policies/edge_aggregation_policy.dart';
import '../viewport.dart';
import 'graph_host_controller.dart';
import 'graph_view_state.dart';

/// Coordinates shared graph view state across DevTools/Desktop hosts.
class GraphViewCoordinator {
  GraphViewCoordinator({
    required RenderConfig renderConfig,
    required LayoutConfig layoutConfig,
    GraphFilterStateCodec? filterStateCodec,
    GraphHostController? hostController,
    GraphViewState? state,
  }) : _host =
           hostController ??
           GraphHostController(
             renderConfig: renderConfig,
             layoutConfig: layoutConfig,
           ),
       state = state ?? GraphViewState(),
       _filterStateCodec = filterStateCodec ?? const GraphFilterStateCodec();

  final GraphHostController _host;
  final GraphFilterStateCodec _filterStateCodec;
  final GraphViewState state;

  static const int diagnosticsSoftLimit =
      GraphHostController.diagnosticsSoftLimit;

  RenderConfig get renderConfig => _host.renderConfig;
  GraphController get graphController => _host.graphController;
  GraphFocusController get focusController => _host.focusController;
  GraphJournalHostAdapter get journalAdapter => _host.journalAdapter;
  GraphJournalDisplayController get journalDisplayController =>
      _host.journalDisplayController;
  LayoutSizingController get layoutSizing => _host.layoutSizing;
  GraphFilterStateCodec get filterStateCodec => _filterStateCodec;

  void dispose() => _host.dispose();

  GraphViewportController createViewportController({
    required TransformationController transformationController,
    required ValueChanged<GraphViewportState> onStateChanged,
  }) {
    return _host.createViewportController(
      transformationController: transformationController,
      onStateChanged: onStateChanged,
    );
  }

  Map<String, dynamic> cloneGraphPayload(Map<String, dynamic> payload) {
    final Map<String, dynamic> clone = Map<String, dynamic>.from(payload);
    clone['nodes'] = _cloneGraphEntries(payload['nodes']);
    clone['edges'] = _cloneGraphEntries(payload['edges']);
    return clone;
  }

  void cacheGraphPayload(Map<String, dynamic> payload) {
    state.lastGraphPayload = payload;
  }

  void applyLifecycleOverridesToPayload(Map<String, dynamic> payload) {
    if (state.nodeLifecycleOverrides.isEmpty) return;
    final List<Map<String, dynamic>> nodes = _nodeMaps(payload);
    if (nodes.isEmpty) return;
    final Map<String, Map<String, dynamic>> nodeById =
        <String, Map<String, dynamic>>{};
    for (final node in nodes) {
      final String? id = node['id'] as String?;
      if (id != null) {
        nodeById[id] = node;
      }
    }
    state.nodeLifecycleOverrides.forEach((nodeId, lifecycle) {
      final Map<String, dynamic>? node = nodeById[nodeId];
      if (node != null) {
        node['lifecycle'] = lifecycle.name;
      }
    });
  }

  void writeLifecycleOverrideToPayload(String nodeId, NodeLifecycle lifecycle) {
    final Map<String, dynamic>? payload = state.lastGraphPayload;
    if (payload == null) return;
    final List<Map<String, dynamic>> nodes = _nodeMaps(payload);
    for (final node in nodes) {
      final String? id = node['id'] as String?;
      if (id == nodeId) {
        node['lifecycle'] = lifecycle.name;
        break;
      }
    }
  }

  Size2D layoutSizeForPayload(
    Map<String, dynamic>? payload,
    Size viewportHint,
  ) {
    final LayoutSizingResult sizing = layoutSizing.resolveForPayload(
      payload: payload,
      viewportHint: viewportHint,
      fallbackNodeCount: graphController.nodes.length,
    );
    return toSize2D(sizing.layoutSize);
  }

  bool recordEdgeAnimation({
    required UyavaEvent event,
    required EdgeAggregationPolicy aggregationPolicy,
  }) {
    final DateTime now = DateTime.now();
    final Duration window = renderConfig.eventDuration;
    final String key = _dirKey(event.from, event.to);
    final List<DateTime> arrivals = state.arrivalsByDirection.putIfAbsent(
      key,
      () => <DateTime>[],
    );
    arrivals
      ..add(now)
      ..removeWhere((t) => now.difference(t) > window);

    final String visFrom = aggregationPolicy.mapToVisibleAncestor(event.from);
    final String visTo = aggregationPolicy.mapToVisibleAncestor(event.to);
    final String visKey = _dirKey(visFrom, visTo);
    final List<GraphEdgeArrival> visibleArrivals = state
        .arrivalsByVisibleDirection
        .putIfAbsent(visKey, () => <GraphEdgeArrival>[]);
    visibleArrivals
      ..add(GraphEdgeArrival(now, event.severity))
      ..removeWhere((a) => now.difference(a.timestamp) > window);

    if (state.activeVisibleDirections.contains(visKey)) {
      return false;
    }

    final List<GraphEdgeArrival> accepted = visibleArrivals
        .where((arrival) => acceptsSeverity(arrival.severity))
        .toList(growable: false);
    final int total = accepted.length;
    UyavaSeverity? severity = event.severity;
    if (total >= renderConfig.queueLabelMinCountToShow) {
      int maxRank = -1;
      for (final GraphEdgeArrival candidate in accepted) {
        final int rank = _severityRank(candidate.severity);
        if (rank > maxRank) {
          maxRank = rank;
          severity = candidate.severity;
        }
      }
    }

    state.edgeEvents.add(
      UyavaEvent(
        from: visFrom,
        to: visTo,
        message: event.message,
        timestamp: now,
        severity: severity,
        sourceRef: event.sourceRef,
        sourceId: event.sourceId,
        sourceType: event.sourceType,
        isolateId: event.isolateId,
        isolateName: event.isolateName,
        isolateNumber: event.isolateNumber,
      ),
    );
    state.activeVisibleDirections.add(visKey);
    return true;
  }

  void drainCompletedDirections() {
    if (state.activeVisibleDirections.isEmpty) return;
    final DateTime now = DateTime.now();
    final Duration window = renderConfig.eventDuration;
    for (final List<GraphEdgeArrival> arrivals
        in state.arrivalsByVisibleDirection.values) {
      arrivals.removeWhere(
        (arrival) => now.difference(arrival.timestamp) > window,
      );
    }
    final List<String> activeSnapshot = List<String>.from(
      state.activeVisibleDirections,
    );
    for (final String key in activeSnapshot) {
      final bool hasActive = state.edgeEvents.any(
        (e) => _dirKey(e.from, e.to) == key && acceptsSeverity(e.severity),
      );
      if (hasActive) {
        continue;
      }
      final List<GraphEdgeArrival> arrivals =
          (state.arrivalsByVisibleDirection[key] ?? const <GraphEdgeArrival>[])
              .where((arrival) => acceptsSeverity(arrival.severity))
              .toList(growable: false);
      if (arrivals.length > 1) {
        final int sep = key.indexOf('->');
        if (sep > 0) {
          final String from = key.substring(0, sep);
          final String to = key.substring(sep + 2);
          UyavaSeverity? severity;
          if (arrivals.isNotEmpty) {
            if (arrivals.length >= renderConfig.queueLabelMinCountToShow) {
              int maxRank = -1;
              for (final GraphEdgeArrival arrival in arrivals) {
                final int rank = _severityRank(arrival.severity);
                if (rank > maxRank) {
                  maxRank = rank;
                  severity = arrival.severity;
                }
              }
            } else {
              severity = arrivals.last.severity;
            }
          }
          state.edgeEvents.add(
            UyavaEvent(
              from: from,
              to: to,
              message: 'edge animation (aggregated)',
              timestamp: DateTime.now(),
              severity: severity,
            ),
          );
          continue;
        }
      }

      state.activeVisibleDirections.remove(key);
    }
  }

  bool recordNodeEvent(UyavaNodeEvent event) {
    state.nodeEvents.add(event);
    return true;
  }

  bool acceptsSeverity(UyavaSeverity? severity) {
    final GraphFilterSeverity? filter = graphController.filters.severity;
    if (filter == null) {
      return true;
    }
    return filter.matches(severity);
  }

  GraphFilterState? decodeFilterState(Object? raw) =>
      _filterStateCodec.decode(raw);

  Map<String, Object?>? encodeFilterState(GraphFilterState state) =>
      _filterStateCodec.encode(state);

  List<Map<String, dynamic>> _cloneGraphEntries(Object? raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is Map) {
        result.add(Map<String, dynamic>.from(entry.cast<String, dynamic>()));
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _nodeMaps(Map<String, dynamic> payload) {
    final Object? raw = payload['nodes'];
    if (raw is List<Map<String, dynamic>>) {
      return raw;
    }
    if (raw is List) {
      final List<Map<String, dynamic>> converted = <Map<String, dynamic>>[];
      for (final entry in raw) {
        if (entry is Map) {
          converted.add(
            Map<String, dynamic>.from(entry.cast<String, dynamic>()),
          );
        }
      }
      payload['nodes'] = converted;
      return converted;
    }
    final List<Map<String, dynamic>> empty = <Map<String, dynamic>>[];
    payload['nodes'] = empty;
    return empty;
  }

  String _dirKey(String from, String to) => '$from->$to';

  int _severityRank(UyavaSeverity? severity) {
    return severity?.index ?? UyavaSeverity.info.index;
  }
}
