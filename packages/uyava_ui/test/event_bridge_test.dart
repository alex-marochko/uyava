import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  group('event_bridge', () {
    test('parseAnimationEvent with explicit from/to', () {
      final controller = GraphController();
      final evt = parseAnimationEvent({
        'from': 'a',
        'to': 'b',
        'message': 'edge event a->b',
      }, controller);
      expect(evt, isNotNull);
      expect(evt!.from, 'a');
      expect(evt.to, 'b');
    });

    test('parseAnimationEvent resolves edge id via controller', () {
      final controller = GraphController();
      controller.replaceGraph({
        'nodes': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'edges': [
          {'id': 'e1', 'source': 'a', 'target': 'b'},
        ],
      }, const Size2D(100, 100));

      final evt = parseAnimationEvent({
        'edge': 'e1',
        'message': 'edge e1',
      }, controller);
      expect(evt, isNotNull);
      expect(evt!.from, 'a');
      expect(evt.to, 'b');
    });

    test('parseAnimationEvent normalizes invalid severity to null', () {
      final controller = GraphController();
      final evt = parseAnimationEvent({
        'from': 'a',
        'to': 'b',
        'message': 'edge event invalid severity',
        'severity': 'nope',
      }, controller);
      expect(evt, isNotNull);
      expect(evt!.severity, isNull);
    });

    test('parseAnimationEvent keeps source metadata', () {
      final controller = GraphController();
      final evt = parseAnimationEvent({
        'from': 'a',
        'to': 'b',
        'message': 'edge event with source',
        'sourceId': 'routerA',
        'sourceType': 'vmService',
      }, controller);
      expect(evt, isNotNull);
      expect(evt!.sourceId, 'routerA');
      expect(evt.sourceType, 'vmService');
    });

    test(
      'parseNodeEvent returns minimal event and filters tags to strings',
      () {
        final evt = parseNodeEvent({
          'nodeId': 'n1',
          'message': 'node event tags',
          'severity': 'info',
          'tags': ['a', 1, 'b'],
        });
        expect(evt, isNotNull);
        expect(evt!.nodeId, 'n1');
        expect(evt.severity, UyavaSeverity.info);
        expect(evt.tags, ['a', 'b']);
      },
    );

    test('parseNodeEvent normalizes invalid severity to null', () {
      final evt = parseNodeEvent({
        'nodeId': 'n1',
        'message': 'node event severity',
        'severity': 'NOPE',
      });
      expect(evt, isNotNull);
      expect(evt!.severity, isNull);
    });

    test('parseNodeEvent keeps source metadata', () {
      final evt = parseNodeEvent({
        'nodeId': 'n1',
        'message': 'node event with source',
        'sourceId': 'routerB',
        'sourceType': 'replayFile',
      });
      expect(evt, isNotNull);
      expect(evt!.sourceId, 'routerB');
      expect(evt.sourceType, 'replayFile');
    });

    test('parseNodeEvent returns null for missing nodeId', () {
      final evt = parseNodeEvent({'severity': 'info', 'message': 'missing id'});
      expect(evt, isNull);
    });

    test(
      'recordEventChainProgressFromNodeEvent ignores payload without chain',
      () {
        final controller = GraphController();
        controller.registerEventChainDefinition(<String, dynamic>{
          'id': 'login_flow',
          'tag': 'chain:login',
          'steps': const <Map<String, String>>[
            {'stepId': 'start', 'nodeId': 'ui_login'},
            {'stepId': 'finish', 'nodeId': 'service_auth'},
          ],
        });

        final result =
            recordEventChainProgressFromNodeEvent(controller, <String, dynamic>{
              'nodeId': 'ui_login',
              'message': 'node event without chain',
              'severity': 'info',
              'payload': <String, dynamic>{},
            });
        expect(result, isNull);
        final snapshot = controller.eventChainFor('login_flow')!;
        expect(snapshot.successCount, 0);
        expect(snapshot.activeAttempts, isEmpty);
      },
    );

    test(
      'recordEventChainProgressFromNodeEvent records progress and parses metadata',
      () {
        final controller = GraphController();
        controller.registerEventChainDefinition(<String, dynamic>{
          'id': 'login_flow',
          'tag': 'chain:login',
          'steps': const <Map<String, String>>[
            {'stepId': 'start', 'nodeId': 'ui_login'},
            {'stepId': 'finish', 'nodeId': 'service_auth'},
          ],
        });

        final result = recordEventChainProgressFromNodeEvent(
          controller,
          <String, dynamic>{
            'nodeId': 'ui_login',
            'message': 'node event chain progress',
            'severity': 'debug',
            'timestamp': '2024-01-02T03:04:05.678Z',
            'payload': <String, dynamic>{
              'chain': <String, String>{
                'id': 'login_flow',
                'step': 'start',
                'attempt': 'attempt_1',
              },
              'edgeId': 'edge_1',
            },
          },
        );

        expect(result, isNotNull);
        expect(
          result!.status,
          equals(GraphEventChainProgressStatus.progressed),
        );
        final snapshot = controller.eventChainFor('login_flow')!;
        expect(snapshot.activeAttempts, hasLength(1));
        expect(snapshot.activeAttempts.single.completedSteps, ['start']);
      },
    );

    test('recordEventChainProgressFromNodeEvent forwards failure status', () {
      final controller = GraphController();
      controller.registerEventChainDefinition(<String, dynamic>{
        'id': 'checkout_flow',
        'tag': 'chain:checkout',
        'steps': const <Map<String, String>>[
          {'stepId': 'start', 'nodeId': 'ui_checkout'},
          {'stepId': 'finish', 'nodeId': 'service_payment'},
        ],
      });

      recordEventChainProgressFromNodeEvent(controller, <String, dynamic>{
        'nodeId': 'ui_checkout',
        'message': 'checkout started',
        'payload': <String, dynamic>{
          'chain': <String, String>{
            'id': 'checkout_flow',
            'step': 'start',
            'attempt': 'attempt_1',
          },
        },
      });

      recordEventChainProgressFromNodeEvent(controller, <String, dynamic>{
        'nodeId': 'service_payment',
        'message': 'checkout failed',
        'payload': <String, dynamic>{
          'chain': <String, String>{
            'id': 'checkout_flow',
            'step': 'finish',
            'attempt': 'attempt_1',
          },
          'status': 'failed',
        },
      });

      final GraphEventChainSnapshot snapshot = controller.eventChainFor(
        'checkout_flow',
      )!;
      expect(snapshot.failureCount, 1);
      expect(snapshot.activeAttempts, isEmpty);
    });
  });
}
