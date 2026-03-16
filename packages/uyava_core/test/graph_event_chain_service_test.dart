import 'dart:async';

import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('GraphEventChainService', () {
    late GraphDiagnosticsService diagnostics;
    late GraphEventChainService service;

    setUp(() {
      diagnostics = GraphDiagnosticsService();
      service = GraphEventChainService(diagnosticsService: diagnostics);
    });

    test('registerDefinition stores chain and emits snapshot', () async {
      final List<List<GraphEventChainSnapshot>> emissions =
          <List<GraphEventChainSnapshot>>[];
      final StreamSubscription<List<GraphEventChainSnapshot>> subscription =
          service.stream.listen(emissions.add);

      final GraphEventChainRegistrationResult result = service
          .registerDefinition(<String, Object?>{
            'id': 'flow',
            'tag': 'chain:flow',
            'steps': const <Map<String, String>>[
              {'stepId': 'start', 'nodeId': 'n1'},
              {'stepId': 'finish', 'nodeId': 'n2'},
            ],
          });

      expect(result.updated, isTrue);
      expect(service.snapshots.single.id, 'flow');
      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);

      await subscription.cancel();
    });

    test('unknown chain progress surfaces diagnostics without crash', () {
      final GraphEventChainProgressResult progress = service.recordProgress(
        nodeId: 'n1',
        chain: const <String, String>{'id': 'missing', 'step': 'start'},
      );

      expect(progress.status, GraphEventChainProgressStatus.ignored);
      expect(progress.diagnostics, isNotEmpty);
      expect(
        diagnostics.diagnostics.records.last.code,
        UyavaGraphIntegrityCode.chainsUnknownId.toWireString(),
      );
    });
  });
}
