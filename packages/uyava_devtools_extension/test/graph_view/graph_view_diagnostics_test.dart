import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/uyava_ui.dart';
import 'package:vm_service/vm_service.dart';

import 'graph_view_test_utils.dart';

void main() {
  registerGraphViewTestHarness();

  testWidgets('journal captures panic diagnostics', (tester) async {
    final dynamic graphState = await pumpGraphViewPage(
      tester,
      graphPayload: basicGraphPayload(),
    );

    final ExtensionData extensionData = ExtensionData()
      ..data.addAll(<String, Object?>{
        'type': UyavaEventTypes.graphDiagnostics,
        'payload': <String, Object?>{
          'code': 'logging.panic_tail_captured',
          'level': UyavaDiagnosticLevel.error.toWireString(),
          'context': <String, Object?>{
            'summary': 'Global error captured, panic tail recorded',
            'panicTail': <String, Object?>{
              'available': true,
              'payloadBytes': 128,
            },
          },
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

    graphState.handleExtensionEventForTesting(
      Event(extensionKind: 'ext.uyava.event', extensionData: extensionData),
    );
    await tester.pump();

    final GraphJournalController journal =
        graphState.journalControllerForTesting as GraphJournalController;
    expect(
      journal.value.diagnostics.any(
        (GraphDiagnosticRecord record) =>
            record.code == 'logging.panic_tail_captured',
      ),
      isTrue,
    );
  });
}
