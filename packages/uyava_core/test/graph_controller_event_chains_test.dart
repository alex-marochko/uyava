import 'dart:async';

import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('GraphController event chains', () {
    late GraphController controller;
    late StreamSubscription<List<GraphEventChainSnapshot>> subscription;
    final List<List<GraphEventChainSnapshot>> emissions =
        <List<GraphEventChainSnapshot>>[];

    setUp(() {
      controller = GraphController();
      subscription = controller.eventChainsStream.listen(emissions.add);
      emissions.clear();
    });

    tearDown(() async {
      await subscription.cancel();
      controller.dispose();
    });

    test(
      'registerEventChainDefinition stores definition and emits snapshot',
      () async {
        final GraphEventChainRegistrationResult result = controller
            .registerEventChainDefinition(<String, dynamic>{
              'id': 'login_flow',
              'tag': 'chain:login',
              'steps': const <Map<String, String>>[
                {'stepId': 'start', 'nodeId': 'ui_login'},
                {'stepId': 'finish', 'nodeId': 'auth_service'},
              ],
            });

        expect(result.updated, isTrue);
        expect(controller.eventChains, hasLength(1));
        final GraphEventChainSnapshot snapshot = controller.eventChainFor(
          'login_flow',
        )!;
        expect(snapshot.definition.steps.first.stepId, 'start');
        expect(snapshot.successCount, 0);
        expect(snapshot.failureCount, 0);

        await Future<void>.delayed(Duration.zero);
        expect(emissions, isNotEmpty);
        expect(emissions.last.single.id, 'login_flow');
      },
    );

    test('recordEventChainProgress tracks sequential attempts', () async {
      controller.registerEventChainDefinition(<String, dynamic>{
        'id': 'order_flow',
        'tag': 'chain:order',
        'steps': const <Map<String, String>>[
          {'stepId': 'open', 'nodeId': 'ui_cart'},
          {'stepId': 'submit', 'nodeId': 'payment_service'},
          {'stepId': 'confirmed', 'nodeId': 'order_service'},
        ],
      });

      final GraphEventChainProgressResult first = controller
          .recordEventChainProgress(
            nodeId: 'ui_cart',
            chain: const <String, String>{'id': 'order_flow', 'step': 'open'},
          );
      expect(first.status, GraphEventChainProgressStatus.progressed);
      expect(
        controller
            .eventChainFor('order_flow')!
            .activeAttempts
            .single
            .completedSteps,
        ['open'],
      );

      final GraphEventChainProgressResult second = controller
          .recordEventChainProgress(
            nodeId: 'payment_service',
            chain: const <String, String>{'id': 'order_flow', 'step': 'submit'},
          );
      expect(second.status, GraphEventChainProgressStatus.progressed);
      final GraphEventChainAttemptSnapshot attempt = controller
          .eventChainFor('order_flow')!
          .activeAttempts
          .single;
      expect(attempt.completedSteps, ['open', 'submit']);

      final GraphEventChainProgressResult third = controller
          .recordEventChainProgress(
            nodeId: 'order_service',
            chain: const <String, String>{
              'id': 'order_flow',
              'step': 'confirmed',
            },
          );
      expect(third.status, GraphEventChainProgressStatus.completed);
      final GraphEventChainSnapshot snapshot = controller.eventChainFor(
        'order_flow',
      )!;
      expect(snapshot.successCount, 1);
      expect(snapshot.activeAttempts, isEmpty);
    });

    test('recordEventChainProgress respects failure status', () {
      controller.registerEventChainDefinition(<String, dynamic>{
        'id': 'flow',
        'tag': 'chain:flow',
        'steps': const <Map<String, String>>[
          {'stepId': 'start', 'nodeId': 'n1'},
          {'stepId': 'finish', 'nodeId': 'n2'},
        ],
      });

      controller.recordEventChainProgress(
        nodeId: 'n1',
        chain: const <String, String>{
          'id': 'flow',
          'step': 'start',
          'attempt': 'A',
        },
      );

      final GraphEventChainProgressResult result = controller
          .recordEventChainProgress(
            nodeId: 'n2',
            chain: const <String, String>{
              'id': 'flow',
              'step': 'finish',
              'attempt': 'A',
              'status': 'failed',
            },
          );

      expect(result.status, GraphEventChainProgressStatus.failed);
      final GraphEventChainSnapshot snapshot = controller.eventChainFor(
        'flow',
      )!;
      expect(snapshot.failureCount, 1);
      expect(snapshot.activeAttempts, isEmpty);
    });

    test(
      'sequential duplicate first step marks failure and restarts attempt',
      () {
        controller.registerEventChainDefinition(<String, dynamic>{
          'id': 'flow',
          'tag': 'chain:flow',
          'steps': const <Map<String, String>>[
            {'stepId': 'one', 'nodeId': 'n1'},
            {'stepId': 'two', 'nodeId': 'n2'},
          ],
        });

        controller.recordEventChainProgress(
          nodeId: 'n1',
          chain: const <String, String>{'id': 'flow', 'step': 'one'},
        );
        final GraphEventChainProgressResult repeated = controller
            .recordEventChainProgress(
              nodeId: 'n1',
              chain: const <String, String>{'id': 'flow', 'step': 'one'},
            );

        expect(repeated.status, GraphEventChainProgressStatus.progressed);
        final GraphEventChainSnapshot snapshot = controller.eventChainFor(
          'flow',
        )!;
        expect(snapshot.failureCount, 1);
        expect(snapshot.successCount, 0);
        expect(
          controller.diagnostics.records.last.code,
          'chains.invalid_step_order',
        );
        expect(
          snapshot.activeAttempts.single.completedSteps,
          ['one'],
          reason: 'New attempt should start immediately after failure.',
        );
      },
    );

    test('attempt tokens allow parallel progress and isolate failures', () {
      controller.registerEventChainDefinition(<String, dynamic>{
        'id': 'flow',
        'tag': 'chain:flow',
        'steps': const <Map<String, String>>[
          {'stepId': 'start', 'nodeId': 'n1'},
          {'stepId': 'middle', 'nodeId': 'n2'},
          {'stepId': 'done', 'nodeId': 'n3'},
        ],
      });

      controller.recordEventChainProgress(
        nodeId: 'n1',
        chain: const <String, String>{
          'id': 'flow',
          'step': 'start',
          'attempt': 'A',
        },
      );
      controller.recordEventChainProgress(
        nodeId: 'n1',
        chain: const <String, String>{
          'id': 'flow',
          'step': 'start',
          'attempt': 'B',
        },
      );

      controller.recordEventChainProgress(
        nodeId: 'n2',
        chain: const <String, String>{
          'id': 'flow',
          'step': 'middle',
          'attempt': 'A',
        },
      );
      final GraphEventChainProgressResult success = controller
          .recordEventChainProgress(
            nodeId: 'n3',
            chain: const <String, String>{
              'id': 'flow',
              'step': 'done',
              'attempt': 'A',
            },
          );
      expect(success.status, GraphEventChainProgressStatus.completed);
      expect(controller.eventChainFor('flow')!.successCount, 1);

      final GraphEventChainProgressResult failure = controller
          .recordEventChainProgress(
            nodeId: 'n3',
            chain: const <String, String>{
              'id': 'flow',
              'step': 'done',
              'attempt': 'B',
            },
          );
      expect(failure.status, GraphEventChainProgressStatus.failed);
      final GraphEventChainSnapshot snapshot = controller.eventChainFor(
        'flow',
      )!;
      expect(snapshot.failureCount, 1);
      expect(
        controller.diagnostics.records.last.code,
        'chains.invalid_step_order',
      );
      expect(
        snapshot.activeAttempts,
        isEmpty,
        reason: 'Attempt B should be removed after failure.',
      );
    });

    test('unknown chain emits diagnostic without crashing', () {
      final GraphEventChainProgressResult result = controller
          .recordEventChainProgress(
            nodeId: 'n1',
            chain: const <String, String>{'id': 'missing', 'step': 'start'},
          );

      expect(result.status, GraphEventChainProgressStatus.ignored);
      expect(result.diagnostics, isNotEmpty);
      expect(controller.diagnostics.records.last.code, 'chains.unknown_id');
    });

    test('missing chain metadata surfaces diagnostics', () {
      final GraphEventChainProgressResult result = controller
          .recordEventChainProgress(
            nodeId: 'n1',
            chain: const <String, String>{'step': 'start'},
          );

      expect(result.status, GraphEventChainProgressStatus.ignored);
      expect(
        result.diagnostics.map((d) => d.code),
        contains(UyavaGraphIntegrityCode.chainsMissingId),
      );
      expect(controller.diagnostics.records.last.code, 'chains.missing_id');
    });

    test('definition re-register resets stats when steps change', () {
      controller.registerEventChainDefinition(<String, dynamic>{
        'id': 'flow',
        'tag': 'chain:flow',
        'steps': const <Map<String, String>>[
          {'stepId': 's1', 'nodeId': 'n1'},
        ],
      });
      controller.recordEventChainProgress(
        nodeId: 'n1',
        chain: const <String, String>{'id': 'flow', 'step': 's1'},
      );
      expect(controller.eventChainFor('flow')!.successCount, 1);

      final GraphEventChainRegistrationResult redefinition = controller
          .registerEventChainDefinition(<String, dynamic>{
            'id': 'flow',
            'tag': 'chain:flow',
            'steps': const <Map<String, String>>[
              {'stepId': 's1', 'nodeId': 'n1'},
              {'stepId': 's2', 'nodeId': 'n2'},
            ],
          });

      expect(redefinition.updated, isTrue);
      expect(
        redefinition.diagnostics.map((d) => d.code),
        contains(UyavaGraphIntegrityCode.chainsConflictingDefinition),
      );
      final GraphEventChainSnapshot snapshot = controller.eventChainFor(
        'flow',
      )!;
      expect(snapshot.successCount, 0);
      expect(snapshot.failureCount, 0);
      expect(snapshot.definition.steps, hasLength(2));
    });

    test('resetEventChain clears statistics and attempts', () async {
      controller.registerEventChainDefinition(<String, dynamic>{
        'id': 'flow',
        'tag': 'chain:flow',
        'steps': const <Map<String, String>>[
          {'stepId': 'start', 'nodeId': 'n1'},
          {'stepId': 'finish', 'nodeId': 'n2'},
        ],
      });

      controller.recordEventChainProgress(
        nodeId: 'n1',
        chain: const <String, String>{'id': 'flow', 'step': 'start'},
      );
      await Future<void>.delayed(Duration.zero);
      controller.recordEventChainProgress(
        nodeId: 'n2',
        chain: const <String, String>{'id': 'flow', 'step': 'finish'},
      );
      await Future<void>.delayed(Duration.zero);
      controller.recordEventChainProgress(
        nodeId: 'n1',
        chain: const <String, String>{'id': 'flow', 'step': 'start'},
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.eventChainFor('flow')!.successCount, 1);
      expect(controller.eventChainFor('flow')!.activeAttempts, isNotEmpty);

      final int emissionsBeforeReset = emissions.length;
      final bool reset = controller.resetEventChain('flow');
      expect(reset, isTrue);

      await Future<void>.delayed(Duration.zero);

      expect(emissions.length, emissionsBeforeReset + 1);
      final GraphEventChainSnapshot after = controller.eventChainFor('flow')!;
      expect(after.successCount, 0);
      expect(after.failureCount, 0);
      expect(after.activeAttempts, isEmpty);

      expect(controller.resetEventChain('flow'), isFalse);
      expect(controller.resetEventChain('unknown'), isFalse);
    });

    test('clearEventChainDefinitions removes all chain snapshots', () async {
      controller.registerEventChainDefinition(<String, dynamic>{
        'id': 'flow',
        'tag': 'chain:flow',
        'steps': const <Map<String, String>>[
          {'stepId': 'start', 'nodeId': 'n1'},
          {'stepId': 'finish', 'nodeId': 'n2'},
        ],
      });
      controller.recordEventChainProgress(
        nodeId: 'n1',
        chain: const <String, String>{'id': 'flow', 'step': 'start'},
      );
      await Future<void>.delayed(Duration.zero);
      emissions.clear();

      controller.clearEventChainDefinitions();
      await Future<void>.delayed(Duration.zero);

      expect(controller.eventChains, isEmpty);
      expect(controller.eventChainFor('flow'), isNull);
      expect(emissions, isNotEmpty);
      expect(emissions.last, isEmpty);
    });
  });
}
