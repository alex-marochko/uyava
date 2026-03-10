import 'package:test/test.dart';
import 'package:uyava_core/src/graph_controller.dart';
import 'package:uyava_core/src/math/size2d.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('GraphController filters', () {
    late GraphController controller;

    setUp(() {
      controller = GraphController();
      controller.replaceGraph({
        'nodes': [
          {
            'id': 'root',
            'label': 'Root Node',
            'tags': ['Core'],
          },
          {
            'id': 'auth',
            'label': 'Auth Service',
            'parentId': 'root',
            'tags': ['Auth', 'backend'],
          },
          {
            'id': 'billing',
            'label': 'Billing Engine',
            'parentId': 'root',
            'tags': ['Payments'],
          },
          {
            'id': 'signup',
            'label': 'Signup Form',
            'parentId': 'auth',
            'tags': ['frontend'],
          },
        ],
        'edges': [
          {'id': 'e1', 'source': 'auth', 'target': 'billing'},
          {'id': 'e2', 'source': 'signup', 'target': 'auth'},
        ],
      }, const Size2D(800, 600));
      controller.registerMetricDefinition({
        'id': 'latency',
        'label': 'Latency',
        'tags': ['perf', 'backend'],
        'aggregators': ['last', 'max'],
      });
      controller.registerMetricDefinition({
        'id': 'fps',
        'label': 'FPS',
        'tags': ['perf', 'frontend'],
      });
      controller.registerEventChainDefinition({
        'id': 'login_chain',
        'tag': 'chain:auth',
        'label': 'Login Flow',
        'steps': [
          {'stepId': 'open', 'nodeId': 'signup'},
          {'stepId': 'submit', 'nodeId': 'auth'},
        ],
      });
      controller.registerEventChainDefinition({
        'id': 'billing_chain',
        'tag': 'chain:payments',
        'steps': [
          {'stepId': 'charge', 'nodeId': 'billing'},
        ],
      });
    });

    tearDown(() {
      controller.dispose();
    });

    test('default filters expose all nodes and metrics', () {
      expect(controller.filteredNodes.length, controller.nodes.length);
      expect(controller.filteredEdges.length, controller.edges.length);
      expect(controller.filteredMetrics.length, controller.metrics.length);
      expect(
        controller.filteredEventChains.length,
        controller.eventChains.length,
      );
      expect(controller.autoCollapsedParents, isEmpty);
    });

    test('substring search narrows nodes while keeping ancestors', () {
      controller.updateFiltersCommand({
        'search': {'mode': 'substring', 'pattern': 'Signup'},
      });

      final ids = controller.filteredNodes.map((n) => n.id).toList();
      expect(ids, ['auth', 'root', 'signup']);
      expect(controller.filteredEdges.map((e) => e.id), ['e2']);
      expect(controller.autoCollapsedParents, isEmpty);
    });

    test('tag include with logic all requires all tags', () {
      controller.updateFiltersCommand({
        'tags': {
          'mode': 'include',
          'values': ['Auth', 'backend'],
          'logic': 'all',
        },
      });

      final ids = controller.filteredNodes.map((n) => n.id).toList();
      expect(ids, ['auth', 'root']);
      expect(controller.filteredMetrics, isEmpty);
      expect(controller.filteredEventChains, isEmpty);
    });

    test('node include list enforces exact matches', () {
      controller.updateFiltersCommand({
        'nodes': {
          'include': ['billing'],
        },
      });

      expect(controller.filteredNodes.map((n) => n.id), ['billing', 'root']);
      expect(controller.filteredEdges, isEmpty);
    });

    test(
      'parent depth limits visible hierarchy and marks collapsed parents',
      () {
        controller.updateFiltersCommand({
          'parent': {'rootId': 'root', 'depth': 1},
        });

        expect(controller.filteredNodes.map((n) => n.id), [
          'auth',
          'billing',
          'root',
        ]);
        expect(controller.autoCollapsedParents, {'auth'});
        expect(controller.filteredEdges.map((e) => e.id), ['e1']);
      },
    );

    test('level grouping collapses deeper levels globally', () {
      controller.updateFiltersCommand({
        'grouping': {'mode': 'level', 'levelDepth': 0},
      });

      expect(controller.filteredNodes.map((n) => n.id), [
        'auth',
        'billing',
        'root',
        'signup',
      ]);
      expect(controller.autoCollapsedParents, {'root'});
      expect(controller.filteredEdges.map((e) => e.id), ['e1', 'e2']);
    });

    test('unknown node id emits diagnostic and keeps filters applied', () {
      final result = controller.updateFiltersCommand({
        'nodes': {
          'include': ['missing'],
        },
      });

      expect(result.applied, isTrue);
      expect(result.diagnostics, hasLength(1));
      expect(
        result.diagnostics.first.code,
        UyavaGraphIntegrityCode.filtersUnknownNode,
      );
      expect(controller.filteredNodes, isEmpty);
    });

    test('metrics respond to search filter', () {
      controller.updateFiltersCommand({
        'search': {'mode': 'substring', 'pattern': 'Latency'},
      });

      expect(controller.filteredMetrics.map((m) => m.id), ['latency']);
      expect(controller.filteredNodes, isEmpty);
    });
  });
}
