import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('GraphEventChainStore.record validation', () {
    late GraphEventChainStore store;
    const UyavaEventChainDefinitionPayload definition =
        UyavaEventChainDefinitionPayload(
          id: 'flow',
          tags: <String>['chain:test'],
          tagsNormalized: <String>['chain:test'],
          steps: <UyavaEventChainStepPayload>[
            UyavaEventChainStepPayload(
              stepId: 'start',
              nodeId: 'ui',
              edgeId: 'edge:start',
            ),
            UyavaEventChainStepPayload(
              stepId: 'finish',
              nodeId: 'service',
              edgeId: 'edge:finish',
            ),
          ],
        );

    setUp(() {
      store = GraphEventChainStore();
      store.register(definition);
    });

    test('rejects events with mismatched node id', () {
      final GraphEventChainProgressResult result = store.record(
        GraphEventChainEvent(
          chainId: 'flow',
          stepId: 'start',
          nodeId: 'wrong-node',
          edgeId: 'edge:start',
          timestamp: DateTime.utc(2024, 01, 01),
        ),
      );

      expect(result.status, GraphEventChainProgressStatus.ignored);
      expect(
        result.diagnostics.map((d) => d.code),
        contains(UyavaGraphIntegrityCode.chainsUnknownStep),
      );
      final snapshot = store.snapshotFor('flow')!;
      expect(snapshot.successCount, 0);
      expect(snapshot.failureCount, 0);
      expect(snapshot.activeAttempts, isEmpty);
    });

    test('rejects events with mismatched edge id', () {
      final GraphEventChainProgressResult result = store.record(
        GraphEventChainEvent(
          chainId: 'flow',
          stepId: 'finish',
          nodeId: 'service',
          edgeId: 'edge:other',
          timestamp: DateTime.utc(2024, 01, 01),
        ),
      );

      expect(result.status, GraphEventChainProgressStatus.ignored);
      expect(
        result.diagnostics.map((d) => d.code),
        contains(UyavaGraphIntegrityCode.chainsUnknownStep),
      );
      final snapshot = store.snapshotFor('flow')!;
      expect(snapshot.successCount, 0);
      expect(snapshot.failureCount, 0);
      expect(snapshot.activeAttempts, isEmpty);
    });
  });
}
