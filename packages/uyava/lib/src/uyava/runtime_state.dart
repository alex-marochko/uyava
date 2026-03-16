part of 'package:uyava/uyava.dart';

Future<UyavaFileTransport> _defaultFileTransportStarter(
  UyavaFileLoggerConfig config,
) {
  return UyavaFileTransport.start(config: config);
}

class _UyavaRuntime {
  _UyavaRuntime({
    UyavaTransportHub? transportHub,
    Future<UyavaFileTransport> Function(UyavaFileLoggerConfig config)?
    fileTransportStarter,
  }) : transportHub =
           transportHub ??
           UyavaTransportHub(
             transports: <UyavaTransport>[
               UyavaVmServiceTransport(eventKind: _eventKind),
             ],
           ),
       fileTransportStarter =
           fileTransportStarter ?? _defaultFileTransportStarter {
    setDiagnosticPublisher((payload) {
      final UyavaGraphDiagnosticPayload normalized = payload.timestamp == null
          ? payload.copyWith(timestamp: DateTime.now().toUtc())
          : payload;
      postDiagnosticPayload(normalized);
    });
  }

  final _UyavaGraph graph = _UyavaGraph();
  bool isInitialized = false;
  final Map<String, String> nodeInitSources = <String, String>{};
  final Map<String, UyavaLifecycleState> nodeLifecycleStates =
      <String, UyavaLifecycleState>{};
  UyavaLifecycleState defaultLifecycleState = UyavaLifecycleState.unknown;

  final UyavaTransportHub transportHub;
  UyavaConsoleLogger? consoleLogger;
  StreamSubscription<UyavaTransportEvent>? consoleTransportTap;

  Future<UyavaFileTransport> Function(UyavaFileLoggerConfig config)
  fileTransportStarter;

  void Function(String type, Map<String, dynamic> data)? postEventObserver;

  @visibleForTesting
  void resetStateForTesting() {
    graph.nodes.clear();
    graph.edges.clear();
    graph.metricDefinitions.clear();
    graph.eventChainDefinitions.clear();
    nodeInitSources.clear();
    nodeLifecycleStates.clear();
  }
}
