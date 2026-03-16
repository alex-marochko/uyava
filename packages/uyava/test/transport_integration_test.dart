import 'package:test/test.dart';
import 'package:uyava/uyava.dart';

void main() {
  group('Uyava transport integration', () {
    late _RecordingTransport realtimeTransport;
    late _RecordingTransport diagnosticTransport;

    setUp(() {
      Uyava.replaceGraph();
      Uyava.unregisterTransport(UyavaTransportChannel.webSocket);
      Uyava.unregisterTransport(UyavaTransportChannel.localFile);

      realtimeTransport = _RecordingTransport(
        channel: UyavaTransportChannel.webSocket,
      );
      diagnosticTransport = _RecordingTransport(
        channel: UyavaTransportChannel.localFile,
        allowedScopes: <UyavaTransportScope>{UyavaTransportScope.diagnostic},
      );

      Uyava.registerTransport(realtimeTransport, replaceExisting: false);
      Uyava.registerTransport(diagnosticTransport, replaceExisting: false);
    });

    tearDown(() {
      Uyava.unregisterTransport(realtimeTransport.channel);
      Uyava.unregisterTransport(diagnosticTransport.channel);
      if (!Uyava.transports.any(
        (UyavaTransport transport) =>
            transport.channel == UyavaTransportChannel.vmService,
      )) {
        Uyava.registerTransport(
          const UyavaVmServiceTransport(eventKind: 'ext.uyava.event'),
        );
      }
      Uyava.replaceGraph();
    });

    test('routes snapshot, realtime, and diagnostic scopes appropriately', () {
      Uyava.replaceGraph(nodes: const <UyavaNode>[UyavaNode(id: 'alpha')]);

      Uyava.emitNodeEvent(nodeId: 'alpha', message: 'alpha heartbeat');
      Uyava.clearDiagnostics();

      expect(
        realtimeTransport.events.map(
          (UyavaTransportEvent event) => event.scope,
        ),
        containsAll(<UyavaTransportScope>{
          UyavaTransportScope.snapshot,
          UyavaTransportScope.realtime,
        }),
      );

      expect(
        realtimeTransport.events.map((UyavaTransportEvent event) => event.type),
        containsAll(<String>{
          UyavaEventTypes.replaceGraph,
          UyavaEventTypes.nodeEvent,
        }),
      );

      expect(
        diagnosticTransport.events.map(
          (UyavaTransportEvent event) => event.scope,
        ),
        everyElement(equals(UyavaTransportScope.diagnostic)),
      );

      expect(
        diagnosticTransport.events.map(
          (UyavaTransportEvent event) => event.type,
        ),
        contains(UyavaEventTypes.clearDiagnostics),
      );
    });
  });
}

class _RecordingTransport extends UyavaTransport {
  _RecordingTransport({required this.channel, this.allowedScopes});

  final Set<UyavaTransportScope>? allowedScopes;

  @override
  final UyavaTransportChannel channel;

  final List<UyavaTransportEvent> events = <UyavaTransportEvent>[];

  @override
  bool accepts(UyavaTransportEvent event) {
    if (allowedScopes == null) {
      return true;
    }
    return allowedScopes!.contains(event.scope);
  }

  @override
  void send(UyavaTransportEvent event) {
    events.add(event);
  }
}
