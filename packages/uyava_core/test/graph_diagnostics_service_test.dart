import 'dart:async';

import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('GraphDiagnosticsService', () {
    test(
      'publishIntegrity copies integrity issues to diagnostics stream',
      () async {
        final GraphDiagnosticsService service = GraphDiagnosticsService();
        final List<List<GraphDiagnosticRecord>> emissions =
            <List<GraphDiagnosticRecord>>[];
        final StreamSubscription<List<GraphDiagnosticRecord>> subscription =
            service.stream.listen(emissions.add);

        service.integrity.add(code: UyavaGraphIntegrityCode.nodesMissingId);
        service.publishIntegrity();
        await Future<void>.delayed(Duration.zero);

        expect(service.diagnostics.records, isNotEmpty);
        expect(emissions, isNotEmpty);
        expect(
          emissions.last.single.code,
          UyavaGraphIntegrityCode.nodesMissingId.toWireString(),
        );

        await subscription.cancel();
      },
    );

    test(
      'logPayloadAnomaly emits app diagnostic without integrity changes',
      () {
        final GraphDiagnosticsService service = GraphDiagnosticsService();

        service.logPayloadAnomaly(
          code: 'core.payload_anomaly',
          context: const <String, Object?>{'source': 'test'},
        );

        expect(service.integrity.issues, isEmpty);
        expect(service.diagnostics.records.single.code, 'core.payload_anomaly');
        expect(service.diagnostics.records.single.context?['source'], 'test');
      },
    );
  });
}
