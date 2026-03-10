part of '../../graph_view_page.dart';

const UyavaPanelId _graphPanelId = UyavaPanelId('graph');
const UyavaPanelId _filtersPanelId = UyavaPanelId('filters');
const UyavaPanelId _dashboardPanelId = UyavaPanelId('dashboard');
const UyavaPanelId _chainsPanelId = UyavaPanelId('chains');
const UyavaPanelId _journalPanelId = UyavaPanelId('journal');
const String _panelStorageKey = 'uyava.devtools.panel_layout.v2';
const String _legacyPanelStorageKey = 'uyava.panel_layout.v1';
const String _panelLayoutSchemaId = kDefaultPanelLayoutSchemaId;
const String _panelFiltersSchemaId = GraphFilterStateCodec.schemaId;
const String _extensionVersion = extensionVersion;
const String _coreVersion = coreVersion;
const String _protocolVersion = protocolVersion;
const String _devtoolsVersion = 'devtools';

const LayoutConfig _devtoolsLayout = LayoutConfig();

bool _devtoolsGraphViewAnimationsDisabledForTesting = false;

mixin _DevToolsGraphViewCoordinatorCore
    on State<GraphViewPage>, TickerProvider {
  final RenderConfig _renderConfig = const RenderConfig().copyWith(
    hideEdgesDuringWarmup: true,
  );
  late final GraphViewCoordinator _graphHost = GraphViewCoordinator(
    renderConfig: _renderConfig,
    layoutConfig: _devtoolsLayout,
  );
  late DevToolsGraphPersistence _graphPersistence;

  AnimationController? _controller;
  late final DevToolsVmEventBridge _vmEventBridge;
  bool _vmBridgeInitialized = false;
  late EdgeVisibilityPolicy _edgeVisibilityPolicy;
  double _edgeAlpha = 1.0;

  final Set<String> _collapsedParents = <String>{};
  final Map<String, double> _collapseProgress = <String, double>{};
  final Set<String> _autoCollapseOverrides = <String>{};
  GraphFilterGrouping? _lastGrouping;
  DateTime _lastTick = DateTime.now();

  final String _sessionId = DateTime.now().microsecondsSinceEpoch.toRadixString(
    36,
  );
  VoidCallback? _vmConnectionListener;
  bool? _lastVmConnected;

  void _initializeAnimationController() {
    if (_devtoolsGraphViewAnimationsDisabledForTesting) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    _controller?.dispose();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            final now = DateTime.now();
            final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
            _lastTick = now;

            if (_advanceCollapseAnimations(dt)) {
              if (!(_controller?.isAnimating ?? false)) {
                _controller?.forward(from: 0);
              }
            }

            if (!_graphHost.graphController.isConverged) {
              _graphHost.graphController.step();
            }

            _edgeAlpha = _edgeVisibilityPolicy.update(
              _graphHost.graphController.positions,
              dt,
            );

            _graphHost.state.edgeEvents.retainWhere((event) {
              final eventDuration = _renderConfig.eventDuration;
              return DateTime.now().difference(event.timestamp) < eventDuration;
            });
            _drainCompletedDirections();
            _graphHost.state.nodeEvents.retainWhere((event) {
              final eventDuration = _renderConfig.eventDuration;
              return DateTime.now().difference(event.timestamp) < eventDuration;
            });

            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (!_graphHost.graphController.isConverged ||
                  _graphHost.state.edgeEvents.isNotEmpty ||
                  _hasActiveCollapseAnimations()) {
                _controller!.forward(from: 0);
              }
            }
          });

    _controller!.forward();
  }

  void _drainCompletedDirections() {
    _graphHost.drainCompletedDirections();
  }

  bool _hasActiveCollapseAnimations() {
    for (final id in _collapseProgress.keys) {
      final target = _collapsedParents.contains(id) ? 1.0 : 0.0;
      final progress = _collapseProgress[id] ?? 0.0;
      if ((progress - target).abs() > 0.001) {
        return true;
      }
    }
    return false;
  }

  bool _advanceCollapseAnimations(double _) {
    bool anyChange = false;
    final ids = {..._collapseProgress.keys, ..._collapsedParents};
    for (final id in ids) {
      final target = _collapsedParents.contains(id) ? 1.0 : 0.0;
      if (target == 0.0) {
        final removed = _collapseProgress.remove(id);
        if (removed != null && removed != 0.0) {
          anyChange = true;
        }
      } else {
        final current = _collapseProgress[id];
        if (current != 1.0) {
          _collapseProgress[id] = 1.0;
          anyChange = true;
        }
      }
    }
    return anyChange;
  }

  double _ease(double x) => Curves.easeInOut.transform(x.clamp(0.0, 1.0));
}
