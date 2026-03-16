part of 'package:uyava/uyava.dart';

const String _eventKind = 'ext.uyava.event';
const String _getInitialGraphMethod = 'ext.uyava.getInitialGraph';

/// The main class for interacting with the Uyava DevTools extension.
class Uyava {
  static final _UyavaRuntime _runtime = _UyavaRuntime();

  @visibleForTesting
  static void resetStateForTesting() => _runtime.resetStateForTesting();

  /// Hook to observe every payload dispatched to transports (tests only).
  @visibleForTesting
  static void Function(String type, Map<String, dynamic> data)?
  get postEventObserver => _runtime.postEventObserver;

  /// Hook to observe every payload dispatched to transports (tests only).
  @visibleForTesting
  static set postEventObserver(
    void Function(String type, Map<String, dynamic> data)? observer,
  ) {
    _runtime.postEventObserver = observer;
  }

  /// Returns the active transports dispatching Uyava events.
  static List<UyavaTransport> get transports => _runtime.transports;

  /// Registers a custom transport (e.g., WebSocket or file logger).
  ///
  /// When [replaceExisting] is true the new transport replaces any existing
  /// transport with the same [UyavaTransport.channel].
  static void registerTransport(
    UyavaTransport transport, {
    bool replaceExisting = true,
  }) => _runtime.registerTransport(transport, replaceExisting: replaceExisting);

  /// Removes a transport by its channel identifier.
  static void unregisterTransport(UyavaTransportChannel channel) =>
      _runtime.unregisterTransport(channel);

  /// Overrides the factory used to create file transports.
  ///
  /// Intended for tests that need to inject a mock or synchronous worker.
  @visibleForTesting
  static void setFileTransportStarter(
    Future<UyavaFileTransport> Function(UyavaFileLoggerConfig config)? starter,
  ) {
    _runtime.fileTransportStarter = starter ?? _defaultFileTransportStarter;
  }

  /// Flushes and disposes every registered transport.
  static Future<void> shutdownTransports() => _runtime.shutdownTransports();

  /// Starts a file logging transport and optionally registers it with Uyava.
  ///
  /// When the transport is registered, [shutdownTransports] flushes and
  /// disposes it alongside the other channels so pending archives are safely
  /// written before teardown.
  static Future<UyavaFileTransport> enableFileLogging({
    required UyavaFileLoggerConfig config,
    bool registerTransport = true,
    bool replaceExisting = true,
  }) => _runtime.enableFileLogging(
    config: config,
    registerTransport: registerTransport,
    replaceExisting: replaceExisting,
  );

  /// Enables the console logger, returning the active instance.
  ///
  /// When already enabled, this replaces the existing logger using the new
  /// [config].
  static UyavaConsoleLogger enableConsoleLogging({
    UyavaConsoleLoggerConfig? config,
    Stream<dynamic>? diagnosticsStream,
  }) => _runtime.enableConsoleLogging(
    config: config,
    diagnosticsStream: diagnosticsStream,
  );

  /// Disables the console logger and releases associated resources.
  static Future<void> disableConsoleLogging() =>
      _runtime.disableConsoleLogging();

  /// Exports the current log archive by rotating the file transport.
  ///
  /// The archive is copied to [targetDirectoryPath] when provided; otherwise an
  /// `exports/` subdirectory is created inside the logging directory. The
  /// active transport immediately starts writing to a new archive.
  static Future<UyavaLogArchive> exportCurrentArchive({
    String? targetDirectoryPath,
  }) => _runtime.exportCurrentArchive(targetDirectoryPath: targetDirectoryPath);

  /// Creates a snapshot of the active archive without rotating the logger.
  ///
  /// The clone is written to [targetDirectoryPath] when provided or to the
  /// `exports/` subdirectory alongside other shared archives. The active file
  /// remains open, enabling “share latest log” flows without interrupting
  /// logging.
  static Future<UyavaLogArchive> cloneActiveArchive({
    String? targetDirectoryPath,
  }) => _runtime.cloneActiveArchive(targetDirectoryPath: targetDirectoryPath);

  /// Returns the latest completed log archive without rotating the transport.
  ///
  /// When [includeExports] is true, the method also considers copies previously
  /// produced by [exportCurrentArchive]. Returns `null` when no completed
  /// archives are available or when file logging is disabled.
  static Future<UyavaLogArchive?> latestArchiveSnapshot({
    bool includeExports = true,
  }) => _runtime.latestArchiveSnapshot(includeExports: includeExports);

  /// Stream of archive lifecycle notifications.
  ///
  /// Emits whenever a sealed archive becomes available (rotation, panic
  /// sealing, streaming journal recovery) or when a copy is produced via export
  /// or clone. Returns `null` when file logging is disabled.
  static Stream<UyavaLogArchiveEvent>? get archiveEvents =>
      _runtime.archiveEvents;

  static Stream<UyavaDiscardStats>? get discardStatsStream =>
      _runtime.discardStatsStream;

  static UyavaDiscardStats? get latestDiscardStats =>
      _runtime.latestDiscardStats;

  /// Initializes the Uyava SDK for use with the DevTools extension.
  ///
  /// [defaultLifecycleState] controls the lifecycle value used for nodes until
  /// an explicit [updateNodeLifecycle] or [updateNodesListLifecycle] call is
  /// made. Use [UyavaLifecycleState.disposed] to start every node in a
  /// "disabled" state and light them up as the app initializes components.
  static void initialize({
    UyavaLifecycleState defaultLifecycleState = UyavaLifecycleState.unknown,
  }) => _runtime.initialize(defaultLifecycleState: defaultLifecycleState);

  /// Registers or updates a metric definition for downstream hosts.
  static void defineMetric({
    required String id,
    String? label,
    String? description,
    String? unit,
    List<String>? tags,
    List<UyavaMetricAggregator>? aggregators,
  }) => _runtime.defineMetric(
    id: id,
    label: label,
    description: description,
    unit: unit,
    tags: tags,
    aggregators: aggregators,
  );

  /// Registers or updates an event-chain definition used for runtime tracing.
  static void defineEventChain({
    required String id,
    List<String>? tags,
    String? tag,
    required List<UyavaEventChainStep> steps,
    String? label,
    String? description,
  }) => _runtime.defineEventChain(
    id: id,
    tags: tags,
    tag: tag,
    steps: steps,
    label: label,
    description: description,
  );

  /// Adds a single node to the graph.
  ///
  /// Optional [sourceRef] overrides auto-captured call-site (debug/profile only).
  static void addNode(UyavaNode node, {String? sourceRef}) =>
      _runtime.addNode(node, sourceRef: sourceRef);

  /// Adds a single edge to the graph.
  static void addEdge(UyavaEdge edge) => _runtime.addEdge(edge);

  /// Removes a node from the graph and optionally cascades connected edges.
  ///
  /// When removing a node the SDK automatically drops any edges referencing it
  /// to keep the graph consistent. The payload emitted to hosts includes the
  /// removed node id and the list of edge ids that were cascaded.
  static void removeNode(String nodeId) => _runtime.removeNode(nodeId);

  /// Removes an edge from the graph.
  static void removeEdge(String edgeId) => _runtime.removeEdge(edgeId);

  /// Applies a selective update to an existing node.
  ///
  /// [changes] accepts a partial set of node fields (type, label, description,
  /// parentId, tags, color, shape). Tags should be provided as a list of
  /// strings. Passing `null` clears the value for nullable fields.
  static void patchNode(String nodeId, Map<String, Object?> changes) =>
      _runtime.patchNode(nodeId, changes);

  /// Applies a selective update to an existing edge.
  ///
  /// [changes] accepts a partial set of edge fields (from, to, label,
  /// description). Passing `null` clears the value for nullable fields.
  static void patchEdge(String edgeId, Map<String, Object?> changes) =>
      _runtime.patchEdge(edgeId, changes);

  /// A convenience method to add multiple nodes and/or edges to the existing graph.
  static void loadGraph({List<UyavaNode>? nodes, List<UyavaEdge>? edges}) =>
      _runtime.loadGraph(nodes: nodes, edges: edges);

  /// Clears the current graph in DevTools and loads a new one.
  static void replaceGraph({List<UyavaNode>? nodes, List<UyavaEdge>? edges}) =>
      _runtime.replaceGraph(nodes: nodes, edges: edges);

  /// Posts a transient event to be visualized on the graph (e.g., an animation).
  static void postEvent({
    required String eventType,
    required Map<String, dynamic> eventData,
  }) => _runtime.postEvent(eventType, eventData);

  /// Emits a directed edge event (visual animation) by edge identifier.
  /// This is the typed wrapper around `postEvent(eventType: 'edgeEvent', ...)`.
  static void emitEdgeEvent({
    required String edge,
    required String message,
    UyavaSeverity? severity,
    String? sourceRef,
  }) => _runtime.emitEdgeEvent(
    edge: edge,
    message: message,
    severity: severity,
    sourceRef: sourceRef,
  );

  /// Emits a node-level event (pulse) with optional severity/tags.
  static void emitNodeEvent({
    required String nodeId,
    required String message,
    UyavaSeverity? severity,
    List<String>? tags,
    Map<String, dynamic>? payload,
    String? sourceRef,
  }) => _runtime.emitNodeEvent(
    nodeId: nodeId,
    message: message,
    severity: severity,
    tags: tags,
    payload: payload,
    sourceRef: sourceRef,
  );

  /// Updates runtime lifecycle state for a node.
  static void updateNodeLifecycle({
    required String nodeId,
    required UyavaLifecycleState state,
  }) => _runtime.updateNodeLifecycle(nodeId: nodeId, state: state);

  /// Updates lifecycle state for a list of nodes in one call.
  static void updateNodesListLifecycle({
    required List<String> nodeIds,
    required UyavaLifecycleState state,
  }) => _runtime.updateNodesListLifecycle(nodeIds: nodeIds, state: state);

  /// Updates lifecycle state for a node and its descendant subtree.
  ///
  /// Descendants are determined by the `parentId` relationships captured when
  /// and after the node graph was built. When [includeRoot] is `false`, only
  /// the descendants are affected and the root node keeps its current state.
  static void updateSubtreeLifecycle({
    required String rootNodeId,
    required UyavaLifecycleState state,
    bool includeRoot = true,
  }) => _runtime.updateSubtreeLifecycle(
    rootNodeId: rootNodeId,
    state: state,
    includeRoot: includeRoot,
  );

  /// Clears all diagnostics currently displayed by connected hosts.
  static void clearDiagnostics() => _runtime.clearDiagnostics();

  /// Emits a diagnostic payload for connected hosts.
  static void postDiagnostic({
    required String code,
    required UyavaDiagnosticLevel level,
    UyavaGraphIntegrityCode? codeEnum,
    String? nodeId,
    String? edgeId,
    Map<String, Object?>? context,
    DateTime? timestamp,
  }) {
    publishDiagnostic(
      UyavaGraphDiagnosticPayload(
        code: codeEnum?.toWireString() ?? code,
        codeEnum: codeEnum,
        level: level,
        nodeId: nodeId,
        edgeId: edgeId,
        context: context,
        timestamp: timestamp,
      ),
    );
  }

  /// Emits a prebuilt diagnostic payload for connected hosts.
  @visibleForTesting
  static void postDiagnosticPayload(UyavaGraphDiagnosticPayload payload) =>
      publishDiagnostic(payload);

  /// Public helper to capture a caller source reference from app code.
  ///
  /// Use this in your adapters to skip over the adapter frame and point to
  /// the actual use-case/handler that invoked the adapter.
  ///
  /// [skip] skips additional non-Uyava frames beyond the first one. For example,
  /// if your call path is `UseCase -> Adapter -> Uyava`, then `caller(skip: 1)`
  /// returns the `UseCase` location.
  static String? caller({int skip = 0}) => _runtime.captureCaller(skip: skip);
}
