part of 'package:uyava/uyava.dart';

extension _UyavaRegistryOps on _UyavaRuntime {
  void initialize({
    UyavaLifecycleState defaultLifecycleState = UyavaLifecycleState.unknown,
  }) {
    this.defaultLifecycleState = defaultLifecycleState;
    // Ensure nodes added prior to initialize call have lifecycle entries.
    for (final nodeId in graph.nodes.keys) {
      nodeLifecycleStates.putIfAbsent(nodeId, () => this.defaultLifecycleState);
    }
    if (isInitialized) return;
    developer.registerExtension(_getInitialGraphMethod, (
      method,
      parameters,
    ) async {
      final graphState = {
        'nodes': graph.nodes.values.map((node) {
          final json = nodeSnapshot(node);
          final init = nodeInitSources[node.id];
          if (init != null) json['initSource'] = init;
          return json;
        }).toList(),
        'edges': graph.edges.values.map((edge) => edge.toJson()).toList(),
        'metrics': graph.metricDefinitions.values
            .map((payload) => Map<String, dynamic>.from(payload.asMap()))
            .toList(growable: false),
        'eventChains': graph.eventChainDefinitions.values
            .map(_canonicalChainDefinition)
            .toList(growable: false),
      };
      return developer.ServiceExtensionResponse.result(jsonEncode(graphState));
    });
    isInitialized = true;
  }

  /// Registers or updates a metric definition for downstream hosts.
  void defineMetric({
    required String id,
    String? label,
    String? description,
    String? unit,
    List<String>? tags,
    List<UyavaMetricAggregator>? aggregators,
  }) {
    final Map<String, dynamic> raw = <String, dynamic>{
      'id': id,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (unit != null) 'unit': unit,
      if (tags != null) 'tags': tags,
      if (aggregators != null)
        'aggregators': aggregators.map((mode) => mode.name).toList(),
    };

    final UyavaMetricDefinitionSanitizationResult result =
        UyavaMetricDefinitionPayload.sanitize(raw);
    for (final UyavaGraphDiagnosticPayload diagnostic in result.diagnostics) {
      postDiagnosticPayload(diagnostic);
    }
    final UyavaMetricDefinitionPayload? payload = result.payload;
    if (!result.isValid || payload == null) {
      throw StateError('Uyava metric definition "$id" failed to sanitize.');
    }

    graph.metricDefinitions[payload.id] = payload;
    postEvent(
      UyavaEventTypes.defineMetric,
      Map<String, dynamic>.from(payload.asMap()),
      scope: UyavaTransportScope.snapshot,
    );
  }

  /// Registers or updates an event-chain definition used for runtime tracing.
  void defineEventChain({
    required String id,
    List<String>? tags,
    String? tag,
    required List<UyavaEventChainStep> steps,
    String? label,
    String? description,
  }) {
    final Map<String, dynamic> raw = <String, dynamic>{
      'id': id,
      if (tags != null) 'tags': tags,
      if (tags == null && tag != null) 'tag': tag,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      'steps': steps.map((step) => step.toJson()).toList(),
    };

    final UyavaEventChainDefinitionSanitizationResult result =
        UyavaEventChainDefinitionPayload.sanitize(raw);
    for (final UyavaGraphDiagnosticPayload diagnostic in result.diagnostics) {
      postDiagnosticPayload(diagnostic);
    }
    final UyavaEventChainDefinitionPayload? payload = result.payload;
    if (!result.isValid || payload == null) {
      throw StateError('Uyava event chain "$id" failed to sanitize.');
    }

    graph.eventChainDefinitions[payload.id] = payload;
    postEvent(
      UyavaEventTypes.defineEventChain,
      _canonicalChainDefinition(payload),
      scope: UyavaTransportScope.snapshot,
    );
  }
}
