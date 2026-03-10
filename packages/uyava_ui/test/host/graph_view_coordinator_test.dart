import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  late GraphViewCoordinator coordinator;

  setUp(() {
    coordinator = GraphViewCoordinator(
      renderConfig: const RenderConfig(),
      layoutConfig: const LayoutConfig(),
    );
    coordinator.graphController.replaceGraph({
      'nodes': const <Map<String, dynamic>>[
        {'id': 'a', 'type': 'service'},
        {'id': 'b', 'type': 'service'},
      ],
      'edges': const <Map<String, dynamic>>[
        {'id': 'edge', 'source': 'a', 'target': 'b'},
      ],
    }, const Size2D(800, 600));
  });

  test('cloneGraphPayload and lifecycle overrides', () {
    coordinator.state.nodeLifecycleOverrides['a'] = NodeLifecycle.initialized;
    final payload = coordinator.cloneGraphPayload({
      'nodes': const <Map<String, dynamic>>[
        {'id': 'a', 'type': 'service'},
      ],
      'edges': const <Map<String, dynamic>>[],
    });
    coordinator.applyLifecycleOverridesToPayload(payload);
    expect(payload['nodes'], isA<List<Map<String, dynamic>>>());
    final List<Map<String, dynamic>> nodes = (payload['nodes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(nodes.first['lifecycle'], 'initialized');
  });

  test('recordNodeEvent appends to queue', () {
    final event = UyavaNodeEvent(
      nodeId: 'a',
      message: 'ping',
      timestamp: DateTime.now(),
      severity: UyavaSeverity.info,
    );
    final added = coordinator.recordNodeEvent(event);
    expect(added, isTrue);
    expect(coordinator.state.nodeEvents, contains(event));
  });

  test('recordEdgeAnimation tracks arrivals and active directions', () {
    final Map<String, String?> parentById = {
      for (final node in coordinator.graphController.nodes)
        node.id: node.parentId,
    };
    final policy = EdgeAggregationPolicy(
      collapsedParents: <String>{},
      collapseProgress: <String, double>{},
      parentById: parentById,
    );
    final event = UyavaEvent(
      from: 'a',
      to: 'b',
      message: 'edge',
      timestamp: DateTime.now(),
      severity: UyavaSeverity.info,
    );
    final started = coordinator.recordEdgeAnimation(
      event: event,
      aggregationPolicy: policy,
    );
    expect(started, isTrue);
    expect(coordinator.state.edgeEvents, isNotEmpty);
    expect(coordinator.state.activeVisibleDirections.contains('a->b'), isTrue);

    coordinator.state.edgeEvents.clear();
    coordinator.state.arrivalsByVisibleDirection.clear();
    coordinator.drainCompletedDirections();
    expect(coordinator.state.activeVisibleDirections, isEmpty);
  });

  test('layoutSizeForPayload uses fallback node count', () {
    final size = coordinator.layoutSizeForPayload(null, const Size(400, 300));
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));
  });

  test('filter codec helpers round-trip state', () {
    final GraphFilterState codecState = GraphFilterState(
      search: GraphFilterSearch(
        mode: UyavaFilterSearchMode.substring,
        pattern: 'service',
        caseSensitive: false,
      ),
    );
    final Map<String, Object?>? encoded = coordinator.encodeFilterState(
      codecState,
    );
    expect(encoded, isNotNull);
    final decoded = coordinator.decodeFilterState(encoded);
    expect(decoded, codecState);
  });
}
