part of 'package:uyava_example/main.dart';

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, this.overrides});

  final ExampleAppOverrides? overrides;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class ExampleAppOverrides {
  const ExampleAppOverrides({
    this.simulationController,
    this.random,
    this.chainStepDelay,
  });

  final SimulationController? simulationController;
  final math.Random? random;
  final Duration? chainStepDelay;
}

abstract class _ExampleAppStateBase extends State<ExampleApp> {
  // Use the port in app code; implementation can vary per environment.
  final GraphPort _graphPort = UyavaGraphAdapter();
  late final SimulationController _simulationController;
  late final bool _ownsSimulationController;
  final Map<String, bool> _features = {
    'Authentication': true,
    'Restaurant Feed': true,
    'Order & Checkout': true,
    'Profile & Settings': true,
    'Real-time Tracking': true,
    'Customer Support': true,
  };
  final Map<String, _Lifecycle> _featureLifecycle = {
    'Authentication': _Lifecycle.initialized,
    'Restaurant Feed': _Lifecycle.initialized,
    'Order & Checkout': _Lifecycle.initialized,
    'Profile & Settings': _Lifecycle.initialized,
    'Real-time Tracking': _Lifecycle.initialized,
    'Customer Support': _Lifecycle.initialized,
  };
  final Map<String, String> _featureRootIds = const {
    'Authentication': 'feat_auth',
    'Restaurant Feed': 'feat_feed',
    'Order & Checkout': 'feat_order',
    'Profile & Settings': 'feat_profile',
    'Real-time Tracking': 'feat_tracking',
    'Customer Support': 'feat_support',
  };
  double _eventsPerSecond = 2.0;
  int _animationIndex = 0;
  List<String> _animatableEdgeIds = [];
  List<String> _eventableNodeIds = [];
  // Counters for generating unique test node ids.
  int _testNodeCounterA = 0;
  int _testNodeCounterB = 0;
  int _diagnosticScenarioCounter = 0;
  final List<String> _recentTestNodeIds = <String>[];
  final List<_AdhocEdge> _recentAdhocEdges = <_AdhocEdge>[];
  bool _authServiceHighlighted = false;
  bool _authEdgeAnnotated = false;
  bool _isSendingLog = false;
  UyavaSeverity _minLogLevel = UyavaSeverity.trace;
  bool _isUpdatingMinLevel = false;
  StreamSubscription<UyavaDiscardStats>? _discardStatsSubscription;
  UyavaDiscardStats? _discardStats;
  StreamSubscription<UyavaLogArchiveEvent>? _archiveEventSubscription;
  final List<UyavaLogArchiveEvent> _recentArchiveEvents =
      <UyavaLogArchiveEvent>[];
  bool _archiveStreamAvailable = false;
  bool _isCloningLog = false;
  bool _loginChainDefined = false;
  int _loginChainAttemptCounter = 0;
  String? _lastLoginAttemptId;
  bool _checkoutChainDefined = false;
  int _checkoutChainAttemptCounter = 0;
  String? _lastCheckoutAttemptId;
  bool _profileChainDefined = false;
  int _profileChainAttemptCounter = 0;
  String? _lastProfileAttemptId;
  int _errorHookCounter = 0;
  late final math.Random _rng;
  late final Duration _chainStepDelay;

  // Keep derived labels for targeted UI (labels and selection).
  Map<String, String> _nodeLabels = {}; // id -> label
  Map<String, String> _edgeLabels = {}; // id -> "from -> to" or label

  // Metrics tab state
  final TextEditingController _metricIdController = TextEditingController();
  final TextEditingController _metricLabelController = TextEditingController();
  final TextEditingController _metricDescriptionController =
      TextEditingController();
  final TextEditingController _metricUnitController = TextEditingController();
  final TextEditingController _metricTagsController = TextEditingController();
  final TextEditingController _sampleMetricIdController =
      TextEditingController();
  final TextEditingController _sampleValueController = TextEditingController(
    text: '0',
  );
  final Map<String, _RegisteredMetric> _registeredMetrics =
      <String, _RegisteredMetric>{};
  final Set<UyavaMetricAggregator> _selectedAggregators =
      <UyavaMetricAggregator>{
        UyavaMetricAggregator.last,
        UyavaMetricAggregator.min,
        UyavaMetricAggregator.max,
      };
  String? _selectedMetricNodeId;
  String _metricSampleSeverity = UyavaSeverity.info.name;
  late final Map<String, List<_MetricTemplate>> _defaultFeatureMetrics;
  final Map<String, String> _featureMetricNodeTargets = const {
    'Authentication': 'service_auth',
    'Restaurant Feed': 'bloc_restaurants',
    'Order & Checkout': 'service_payment',
    'Profile & Settings': 'service_user_preferences',
    'Real-time Tracking': 'service_location',
    'Customer Support': 'service_chat_websocket',
  };
  double _courierBurstEventsPerSecond = 8.0;
  double _courierBurstDurationSeconds = 7.0;
  bool _courierBurstIncludeMetrics = true;
  Timer? _courierBurstTimer;
  int _courierBurstTick = 0;
  int _courierBurstEventsEmitted = 0;
  String? _courierBurstLastSummary;
  void Function(String, Map<String, dynamic>)? _previousPostEventObserver;
  void Function(String, Map<String, dynamic>)? _panicPostEventObserver;
  // Global error options toggles for the Wrong data tab.
  UyavaGlobalErrorOptions _globalErrorOptions = const UyavaGlobalErrorOptions(
    delegateOriginalHandlers: false,
    propagateToZone: false,
  );
  bool _errorOptionsUpdating = false;
  bool _isolateErrorsEnabled = false;
  bool _captureCurrentIsolateErrors = true;
  bool _emitNonFatalDiagnostics = true;
  Map<String, dynamic>? _lastPanicDiagnostic;

  // Targeted events tab state
  _TargetType _targetType = _TargetType.edge;
  String? _selectedNodeIdTarget;
  String? _selectedEdgeIdTarget;
  // Severity for targeted events (applies to node and edge)
  String _selectedSeverity = UyavaSeverity.info.name;

  UyavaSeverity? _severityFromName(String? name) {
    if (name == null) return null;
    try {
      return UyavaSeverity.values.byName(name);
    } on ArgumentError {
      return null;
    }
  }

  String _severityLabel(UyavaSeverity severity) {
    switch (severity) {
      case UyavaSeverity.trace:
        return 'trace — tracing';
      case UyavaSeverity.debug:
        return 'debug — debugging';
      case UyavaSeverity.info:
        return 'info — informational';
      case UyavaSeverity.warn:
        return 'warn — warning';
      case UyavaSeverity.error:
        return 'error — error state';
      case UyavaSeverity.fatal:
        return 'fatal — critical';
    }
  }

  void _showSnack(String message) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ExampleAppState extends _ExampleAppStateBase
    with
        _FeaturesGraphMixin,
        _MetricsLogicMixin,
        _FeaturesTabMixin,
        _MetricsTabMixin,
        _EventChainsLogicMixin,
        _EventChainsTabMixin,
        _CourierBurstTabMixin,
        _TargetedEventsTabMixin,
        _WrongDataLogicMixin,
        _WrongDataTabMixin {
  @override
  void initState() {
    super.initState();
    final ExampleAppOverrides? overrides = widget.overrides;
    _rng = overrides?.random ?? math.Random();
    _chainStepDelay = overrides?.chainStepDelay ?? const Duration(seconds: 3);
    _defaultFeatureMetrics = _buildDefaultFeatureMetrics();
    final SimulationController controllerOverride =
        overrides?.simulationController ?? EventSimulationController();
    _simulationController = controllerOverride;
    _ownsSimulationController = overrides?.simulationController == null;
    _simulationController.setTickCallback(_handleSimulationTick);
    // On Hot Restart, the `main` function does not run again, so we need to
    // call updateGraph here to ensure the extension shows the correct state.
    final UyavaFileTransport? transport = currentFileTransport();
    if (transport != null) {
      _minLogLevel = transport.config.minLevel;
    }
    _bindDiscardStats(initial: true);
    _bindArchiveEvents(initial: true);
    _updateGraph();
    _initializeDefaultMetrics();
    _defineDefaultEventChains(silent: true);
    _isolateErrorsEnabled = _globalErrorOptions.enableIsolateErrors;
    _captureCurrentIsolateErrors =
        _globalErrorOptions.captureCurrentIsolateErrors;
    _emitNonFatalDiagnostics = _globalErrorOptions.emitNonFatalDiagnostics;
    _attachPanicDiagnosticObserver();
  }

  @override
  void dispose() {
    _stopCourierBurst(silent: true);
    if (_ownsSimulationController) {
      _simulationController.dispose();
    } else {
      _simulationController.stop();
    }
    _discardStatsSubscription?.cancel();
    _archiveEventSubscription?.cancel();
    _metricIdController.dispose();
    _metricLabelController.dispose();
    _metricDescriptionController.dispose();
    _metricUnitController.dispose();
    _metricTagsController.dispose();
    _sampleMetricIdController.dispose();
    _sampleValueController.dispose();
    unawaited(shutdownFileLogging());
    unawaited(Uyava.shutdownTransports());
    // ignore: invalid_use_of_visible_for_testing_member
    if (Uyava.postEventObserver == _panicPostEventObserver) {
      // ignore: invalid_use_of_visible_for_testing_member
      Uyava.postEventObserver = _previousPostEventObserver;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnimating = _simulationController.isRunning;
    final bool allFeaturesEnabled = _features.values.every((v) => v);

    return MaterialApp(
      home: DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Food Delivery App Simulation'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Features'),
                Tab(text: 'Metrics'),
                Tab(text: 'Event Chains'),
                Tab(text: 'Courier Burst'),
                Tab(text: 'Targeted Events'),
                Tab(text: 'Wrong data'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildFeaturesTab(isAnimating, allFeaturesEnabled),
              _buildMetricsTab(),
              _buildEventChainsTab(),
              _buildCourierBurstTab(),
              _buildTargetedEventsTab(),
              _buildWrongDataTab(),
            ],
          ),
        ),
      ),
    );
  }
}
