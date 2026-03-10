import 'dart:async';
import 'dart:developer' as developer;

/// Identifies a transport channel that can deliver Uyava events.
enum UyavaTransportChannel { vmService, webSocket, localFile }

/// Marks the intent of an event for selective routing or persistence.
enum UyavaTransportScope { realtime, snapshot, diagnostic }

/// Immutable envelope that transports receive.
class UyavaTransportEvent {
  UyavaTransportEvent({
    required this.type,
    required Map<String, dynamic> payload,
    DateTime? timestamp,
    this.scope = UyavaTransportScope.realtime,
    this.sequenceId,
  }) : timestamp = timestamp ?? DateTime.now(),
       payload = Map<String, dynamic>.unmodifiable(payload);

  final String type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final UyavaTransportScope scope;
  final String? sequenceId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      if (scope != UyavaTransportScope.realtime) 'scope': scope.name,
      if (sequenceId != null) 'sequenceId': sequenceId,
    };
  }
}

/// Defines the contract for pushing Uyava events to an external sink.
abstract class UyavaTransport {
  const UyavaTransport();

  UyavaTransportChannel get channel;

  bool accepts(UyavaTransportEvent event) => true;

  void send(UyavaTransportEvent event);

  Future<void> flush() => Future<void>.value();

  Future<void> dispose() => Future<void>.value();
}

/// Coordinates multiple transports and shields the SDK from transport failures.
class UyavaTransportHub {
  UyavaTransportHub({List<UyavaTransport>? transports}) {
    if (transports != null) {
      for (final transport in transports) {
        register(transport);
      }
    }
  }

  final List<UyavaTransport> _transports = <UyavaTransport>[];
  StreamController<UyavaTransportEvent>? _eventTapController;

  List<UyavaTransport> get transports =>
      List<UyavaTransport>.unmodifiable(_transports);

  /// Broadcast stream emitting every event routed through the hub.
  ///
  /// The stream is synchronous, so listeners receive events immediately after
  /// transports accept them. Consumers should apply their own throttling when
  /// necessary.
  Stream<UyavaTransportEvent> get events {
    return (_eventTapController ??=
            StreamController<UyavaTransportEvent>.broadcast(sync: true))
        .stream;
  }

  void register(UyavaTransport transport, {bool replace = true}) {
    if (replace) {
      _transports.removeWhere(
        (existing) => existing.channel == transport.channel,
      );
    }
    _transports.add(transport);
  }

  void unregister(UyavaTransportChannel channel) {
    _transports.removeWhere((transport) => transport.channel == channel);
  }

  void publish(UyavaTransportEvent event) {
    final StreamController<UyavaTransportEvent>? tapController =
        _eventTapController;
    if (tapController != null && !tapController.isClosed) {
      try {
        tapController.add(event);
      } catch (error, stackTrace) {
        developer.log(
          'Uyava transport hub tap failed to forward ${event.type}.',
          name: 'Uyava',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    for (final transport in _transports) {
      if (!transport.accepts(event)) {
        continue;
      }
      try {
        transport.send(event);
      } catch (error, stackTrace) {
        developer.log(
          'Uyava transport ${transport.channel} failed to deliver ${event.type}.',
          name: 'Uyava',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> shutdown() async {
    for (final transport in List<UyavaTransport>.from(_transports)) {
      try {
        await transport.dispose();
      } catch (error, stackTrace) {
        developer.log(
          'Uyava transport ${transport.channel} failed to dispose cleanly.',
          name: 'Uyava',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    _transports.clear();
    await _eventTapController?.close();
    _eventTapController = null;
  }
}

/// Default VM Service transport used by the SDK today.
class UyavaVmServiceTransport extends UyavaTransport {
  const UyavaVmServiceTransport({required this.eventKind});

  final String eventKind;

  @override
  UyavaTransportChannel get channel => UyavaTransportChannel.vmService;

  @override
  void send(UyavaTransportEvent event) {
    developer.postEvent(eventKind, event.toJson());
  }
}

/// Base for WebSocket transports (io or web implementations can extend this).
abstract class UyavaWebSocketTransport extends UyavaTransport {
  const UyavaWebSocketTransport({required this.uri});

  final Uri uri;

  @override
  UyavaTransportChannel get channel => UyavaTransportChannel.webSocket;
}

/// Base for transports writing event streams to a local file.
abstract class UyavaLocalFileTransport extends UyavaTransport {
  const UyavaLocalFileTransport({required this.path});

  final String path;

  @override
  UyavaTransportChannel get channel => UyavaTransportChannel.localFile;
}

/// Builder signature for lazy transport creation (e.g., deferred connects).
typedef UyavaTransportFactory = UyavaTransport Function();
