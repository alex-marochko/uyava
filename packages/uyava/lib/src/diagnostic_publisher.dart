import 'dart:developer' as developer;

import 'package:uyava_protocol/uyava_protocol.dart';

import 'transport.dart';

typedef DiagnosticPublisher =
    void Function(UyavaGraphDiagnosticPayload payload);

DiagnosticPublisher _publisher = _vmServiceDiagnosticPublisher;

void publishDiagnostic(UyavaGraphDiagnosticPayload payload) {
  final UyavaGraphDiagnosticPayload normalized = payload.timestamp == null
      ? payload.copyWith(timestamp: DateTime.now().toUtc())
      : payload;
  _publisher(normalized);
}

void setDiagnosticPublisher(DiagnosticPublisher publisher) {
  _publisher = publisher;
}

void resetDiagnosticPublisher() {
  _publisher = _vmServiceDiagnosticPublisher;
}

void _vmServiceDiagnosticPublisher(UyavaGraphDiagnosticPayload payload) {
  final UyavaTransportEvent event = UyavaTransportEvent(
    type: UyavaEventTypes.graphDiagnostics,
    payload: payload.toJson(),
    scope: UyavaTransportScope.diagnostic,
    timestamp: payload.timestamp ?? DateTime.now().toUtc(),
  );
  try {
    developer.postEvent('ext.uyava.event', event.toJson());
  } catch (_) {
    // Best-effort diagnostics; failures are logged by downstream listeners.
  }
}
