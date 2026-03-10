part of 'package:uyava/uyava.dart';

extension _UyavaEventOps on _UyavaRuntime {
  void postEvent(
    String type,
    Map<String, dynamic> data, {
    UyavaTransportScope scope = UyavaTransportScope.realtime,
    String? sequenceId,
  }) {
    if (!isInitialized) {
      developer.log(
        'Uyava is not initialized. Call Uyava.initialize() at app startup for full functionality.',
        name: 'Uyava',
      );
    }
    final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
    final UyavaTransportEvent event = UyavaTransportEvent(
      type: type,
      payload: payload,
      scope: scope,
      sequenceId: sequenceId,
    );
    transportHub.publish(event);
    postEventObserver?.call(type, Map<String, dynamic>.from(payload));
  }

  /// Emits a directed edge event (visual animation) by edge identifier.
  /// This is the typed wrapper around `postEvent(eventType: 'edgeEvent', ...)`.
  void emitEdgeEvent({
    required String edge,
    required String message,
    UyavaSeverity? severity,
    String? sourceRef,
  }) {
    final String normalizedMessage = _validateEventMessage(message);
    final UyavaEdge? resolved = graph.edges[edge];
    final String? src = sourceRef ?? _captureCallSite();
    if (resolved == null) {
      final Map<String, dynamic> legacy = {
        'edge': edge,
        'message': normalizedMessage,
        if (severity != null) 'severity': severity.name,
        if (src != null) 'sourceRef': src,
      };
      postEvent(UyavaEventTypes.edgeEvent, legacy);
      return;
    }

    final UyavaGraphEdgeEventPayload payload = UyavaGraphEdgeEventPayload(
      edgeId: edge,
      from: resolved.from,
      to: resolved.to,
      message: normalizedMessage,
      severity: severity,
      timestamp: DateTime.now(),
      sourceRef: src,
    );
    postEvent(UyavaEventTypes.edgeEvent, payload.toJson());
  }

  /// Emits a node-level event (pulse) with optional severity/tags.
  void emitNodeEvent({
    required String nodeId,
    required String message,
    UyavaSeverity? severity,
    List<String>? tags,
    Map<String, dynamic>? payload,
    String? sourceRef,
  }) {
    final String normalizedMessage = _validateEventMessage(message);
    List<String>? normalizedTags;
    if (tags != null) {
      final UyavaTagNormalizationResult norm = normalizeTags(tags);
      if (norm.hasValues) {
        normalizedTags = norm.values;
      }
    }
    final Map<String, dynamic>? normalizedPayload = _normalizeEventPayload(
      payload,
    );
    final UyavaGraphNodeEventPayload eventPayload = UyavaGraphNodeEventPayload(
      nodeId: nodeId,
      message: normalizedMessage,
      severity: severity,
      tags: normalizedTags,
      timestamp: DateTime.now(),
      sourceRef: sourceRef ?? _captureCallSite(),
      payload: normalizedPayload,
    );
    postEvent(UyavaEventTypes.nodeEvent, eventPayload.toJson());
  }

  /// Updates runtime lifecycle state for a node.
  void updateNodeLifecycle({
    required String nodeId,
    required UyavaLifecycleState state,
  }) {
    if (!graph.nodes.containsKey(nodeId)) {
      developer.log(
        'Uyava nodeLifecycle ignored for unknown node: $nodeId',
        name: 'Uyava',
      );
      return;
    }
    nodeLifecycleStates[nodeId] = state;
    postEvent(UyavaEventTypes.nodeLifecycle, {
      'nodeId': nodeId,
      'state': state.name,
    });
  }

  /// Updates lifecycle state for a list of nodes in one call.
  void updateNodesListLifecycle({
    required List<String> nodeIds,
    required UyavaLifecycleState state,
  }) {
    if (nodeIds.isEmpty) return;
    final Set<String> uniqueIds = <String>{...nodeIds};
    final List<String> updated = <String>[];
    final List<String> unknown = <String>[];
    for (final id in uniqueIds) {
      if (!graph.nodes.containsKey(id)) {
        unknown.add(id);
        continue;
      }
      nodeLifecycleStates[id] = state;
      updated.add(id);
    }
    if (unknown.isNotEmpty) {
      developer.log(
        'Uyava nodeLifecycle ignored for unknown node(s): ${unknown.join(', ')}',
        name: 'Uyava',
      );
    }
    for (final id in updated) {
      postEvent(UyavaEventTypes.nodeLifecycle, {
        'nodeId': id,
        'state': state.name,
      });
    }
  }

  /// Updates lifecycle state for a node and its descendant subtree.
  ///
  /// Descendants are determined by the `parentId` relationships captured when
  /// and after the node graph was built. When [includeRoot] is `false`, only
  /// the descendants are affected and the root node keeps its current state.
  void updateSubtreeLifecycle({
    required String rootNodeId,
    required UyavaLifecycleState state,
    bool includeRoot = true,
  }) {
    if (!graph.nodes.containsKey(rootNodeId)) {
      developer.log(
        'Uyava updateSubtreeLifecycle ignored for unknown node: $rootNodeId',
        name: 'Uyava',
      );
      return;
    }

    final List<String> subtreeIds = _collectSubtreeNodeIds(
      rootNodeId: rootNodeId,
      includeRoot: includeRoot,
    );
    if (subtreeIds.isEmpty) return;
    updateNodesListLifecycle(nodeIds: subtreeIds, state: state);
  }

  Map<String, dynamic>? _normalizeEventPayload(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    Map<String, dynamic>? working;
    bool mutated = false;

    Map<String, dynamic> ensureWorking() {
      return working ??= Map<String, dynamic>.from(payload);
    }

    final Object? metricRaw = payload['metric'];
    if (metricRaw != null) {
      final _MetricNormalizationResult metricResult = _normalizeMetricPayload(
        metricRaw,
      );
      if (metricResult.remove) {
        ensureWorking().remove('metric');
        mutated = true;
      } else if (metricResult.replacement != null) {
        ensureWorking()['metric'] = metricResult.replacement!;
        mutated = true;
      }
    }

    if (!mutated) {
      return payload;
    }

    return working ?? Map<String, dynamic>.from(payload);
  }

  String _validateEventMessage(String message) {
    final String trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        message,
        'message',
        'must not be empty or whitespace',
      );
    }
    return message;
  }

  _MetricNormalizationResult _normalizeMetricPayload(Object? raw) {
    if (raw == null) {
      return const _MetricNormalizationResult();
    }

    if (raw is Map) {
      final Map<String, dynamic> rawMap = <String, dynamic>{};
      raw.forEach((key, value) {
        if (key is String) {
          rawMap[key] = value;
        }
      });

      final UyavaMetricSampleSanitizationResult result =
          UyavaMetricSamplePayload.sanitize(rawMap);
      for (final UyavaGraphDiagnosticPayload diagnostic in result.diagnostics) {
        postDiagnosticPayload(diagnostic);
      }
      final UyavaMetricSamplePayload? payload = result.payload;
      if (!result.isValid || payload == null) {
        return const _MetricNormalizationResult(remove: true);
      }
      return _MetricNormalizationResult(
        replacement: _canonicalMetricSample(payload),
      );
    }

    postDiagnostic(
      code: UyavaGraphIntegrityCode.metricsInvalidValue,
      level: UyavaGraphIntegrityCode.metricsInvalidValue.defaultLevel,
      context: <String, Object?>{'rawMetric': raw},
    );
    return const _MetricNormalizationResult(remove: true);
  }

  /// Clears all diagnostics currently displayed by connected hosts.
  void clearDiagnostics() {
    postEvent(
      UyavaEventTypes.clearDiagnostics,
      const <String, dynamic>{},
      scope: UyavaTransportScope.diagnostic,
    );
  }

  void postDiagnosticPayload(UyavaGraphDiagnosticPayload diagnostic) {
    postEvent(
      UyavaEventTypes.graphDiagnostics,
      diagnostic.toJson(),
      scope: UyavaTransportScope.diagnostic,
    );
  }

  void postDiagnostic({
    required UyavaGraphIntegrityCode code,
    UyavaDiagnosticLevel? level,
    String? nodeId,
    String? edgeId,
    Map<String, Object?>? context,
  }) {
    final UyavaGraphDiagnosticPayload payload = UyavaGraphDiagnosticPayload(
      code: code.toWireString(),
      codeEnum: code,
      level: level ?? code.defaultLevel,
      nodeId: nodeId,
      edgeId: edgeId,
      context: context,
    );
    postDiagnosticPayload(payload);
  }

  String? captureCaller({int skip = 0}) {
    return _captureCallSite(extraSkip: skip);
  }

  List<String> _collectSubtreeNodeIds({
    required String rootNodeId,
    required bool includeRoot,
  }) {
    final Map<String, List<String>> childrenByParent = <String, List<String>>{};
    for (final node in graph.nodes.values) {
      final String? parentId = node.parentId;
      if (parentId == null) continue;
      childrenByParent.putIfAbsent(parentId, () => <String>[]).add(node.id);
    }

    final Set<String> visited = <String>{rootNodeId};
    final List<String> stack = <String>[rootNodeId];
    final List<String> result = <String>[];

    if (includeRoot) {
      result.add(rootNodeId);
    }

    while (stack.isNotEmpty) {
      final String current = stack.removeLast();
      final List<String>? children = childrenByParent[current];
      if (children == null) continue;
      for (final childId in children) {
        if (!visited.add(childId)) continue;
        result.add(childId);
        stack.add(childId);
      }
    }

    return result;
  }
}
