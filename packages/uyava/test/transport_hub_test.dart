import 'package:test/test.dart';
import 'package:uyava/uyava.dart';

void main() {
  group('UyavaTransportHub', () {
    test('delivers events to registered transports', () {
      final _RecordingTransport primary = _RecordingTransport();
      final UyavaTransportHub hub = UyavaTransportHub(
        transports: <UyavaTransport>[primary],
      );

      final UyavaTransportEvent event = UyavaTransportEvent(
        type: 'snapshot.replaceGraph',
        payload: const <String, dynamic>{'nodes': 1},
        scope: UyavaTransportScope.snapshot,
      );

      hub.publish(event);

      expect(primary.events, hasLength(1));
      expect(primary.events.single.type, 'snapshot.replaceGraph');
    });

    test('continues delivering after transport failure', () {
      final _ThrowingTransport flaky = _ThrowingTransport(
        failuresBeforeRecover: 1,
      );
      final _RecordingTransport healthy = _RecordingTransport(
        channel: UyavaTransportChannel.localFile,
      );
      final UyavaTransportHub hub = UyavaTransportHub(
        transports: <UyavaTransport>[flaky, healthy],
      );

      final UyavaTransportEvent first = UyavaTransportEvent(
        type: 'nodeEvent',
        payload: const <String, dynamic>{'nodeId': 'a'},
      );
      hub.publish(first);

      expect(healthy.events, contains(first));
      expect(flaky.attempts, 1);
      expect(flaky.events, isEmpty);

      final UyavaTransportEvent second = UyavaTransportEvent(
        type: 'nodeEvent',
        payload: const <String, dynamic>{'nodeId': 'b'},
      );
      hub.publish(second);

      expect(healthy.events, containsAll(<UyavaTransportEvent>[first, second]));
      expect(flaky.events, contains(second));
      expect(flaky.attempts, 2);
    });

    test('honors transport scope filters via accepts()', () {
      final _RecordingTransport snapshotsOnly = _RecordingTransport(
        allowedScopes: <UyavaTransportScope>{UyavaTransportScope.snapshot},
      );
      final UyavaTransportHub hub = UyavaTransportHub(
        transports: <UyavaTransport>[snapshotsOnly],
      );

      final UyavaTransportEvent realtime = UyavaTransportEvent(
        type: 'nodeEvent',
        payload: const <String, dynamic>{},
        scope: UyavaTransportScope.realtime,
      );
      final UyavaTransportEvent snapshot = UyavaTransportEvent(
        type: 'snapshot.replaceGraph',
        payload: const <String, dynamic>{'nodes': 2},
        scope: UyavaTransportScope.snapshot,
      );

      hub.publish(realtime);
      hub.publish(snapshot);

      expect(
        snapshotsOnly.events,
        orderedEquals(<UyavaTransportEvent>[snapshot]),
      );
    });
  });
}

class _RecordingTransport extends UyavaTransport {
  _RecordingTransport({
    this.allowedScopes,
    this.channel = UyavaTransportChannel.webSocket,
  });

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

class _ThrowingTransport extends UyavaTransport {
  _ThrowingTransport({required this.failuresBeforeRecover});

  final int failuresBeforeRecover;
  int attempts = 0;
  final List<UyavaTransportEvent> events = <UyavaTransportEvent>[];

  @override
  UyavaTransportChannel get channel => UyavaTransportChannel.vmService;

  @override
  void send(UyavaTransportEvent event) {
    attempts += 1;
    if (attempts <= failuresBeforeRecover) {
      throw StateError('intentional failure');
    }
    events.add(event);
  }
}
