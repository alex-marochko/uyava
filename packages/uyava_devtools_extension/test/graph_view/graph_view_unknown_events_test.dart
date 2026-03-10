import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:vm_service/vm_service.dart';

import 'graph_view_test_utils.dart';

void main() {
  registerGraphViewTestHarness();

  testWidgets('ignores reserved replay events gracefully', (tester) async {
    final dynamic graphState = await pumpGraphViewPage(
      tester,
      graphPayload: basicGraphPayload(),
    );
    final int initialNodeCount = graphState.graphController.nodes.length;

    final ExtensionData extensionData = ExtensionData()
      ..data.addAll(<String, Object?>{
        'type': UyavaEventTypes.replayChunk,
        'payload': <String, Object?>{
          'body': <String, Object?>{'demo': true},
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

    final Event event = Event(
      extensionKind: 'ext.uyava.event',
      extensionData: extensionData,
    );

    graphState.handleExtensionEventForTesting(event);
    await tester.pump();

    expect(graphState.graphController.nodes.length, initialNodeCount);
  });

  testWidgets(
    'drops reserved replay/control payloads without polluting journal',
    (tester) async {
      final dynamic graphState = await pumpGraphViewPage(
        tester,
        graphPayload: basicGraphPayload(),
      );
      final GraphJournalController journal =
          graphState.journalControllerForTesting as GraphJournalController;
      final GraphDiagnosticsBuffer diagnostics =
          graphState.diagnosticsForTesting as GraphDiagnosticsBuffer;
      final int initialJournal = journal.value.events.length;
      final int initialDiagnostics = diagnostics.records.length;

      ExtensionData buildExt(Map<String, Object?> data) {
        final ExtensionData extensionData = ExtensionData();
        extensionData.data.addAll(data);
        return extensionData;
      }

      void sendReserved(Map<String, Object?> data) {
        final Event event = Event(
          extensionKind: 'ext.uyava.event',
          extensionData: buildExt(data),
        );
        graphState.handleExtensionEventForTesting(event);
      }

      final String timestamp = DateTime.now().toIso8601String();
      sendReserved(<String, Object?>{
        'type': UyavaEventTypes.replayChunk,
        'payload': <String, Object?>{
          'body': <String, Object?>{'demo': true},
        },
        'timestamp': timestamp,
      });
      sendReserved(<String, Object?>{
        'type': UyavaEventTypes.restEnvelope,
        'payload': const <String, Object?>{'events': <Object?>[]},
        'timestamp': timestamp,
      });
      sendReserved(<String, Object?>{
        'type': '_marker',
        'payload': const <String, Object?>{},
        'timestamp': timestamp,
      });
      sendReserved(<String, Object?>{
        'type': '_control.aggregateRealtimeDiscard',
        'payload': const <String, Object?>{'dropped': 3},
        'timestamp': timestamp,
      });
      await tester.pump();

      expect(journal.value.events.length, initialJournal);
      expect(diagnostics.records.length, initialDiagnostics);
    },
  );
}
