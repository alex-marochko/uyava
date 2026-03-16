import 'package:flutter_test/flutter_test.dart';
import 'package:uyava/uyava.dart';

void main() {
  final List<Map<String, dynamic>> captured = [];

  setUp(() {
    captured.clear();
    Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
      captured.add({'type': type, 'payload': payload});
    };
  });

  tearDown(() {
    Uyava.postEventObserver = null;
  });

  test('emitEdgeEvent posts edgeEvent with required edge id only', () {
    Uyava.emitEdgeEvent(edge: 'edge_a', message: 'edge_a fired');

    expect(captured, hasLength(1));
    final event = captured.single;
    expect(event['type'], UyavaEventTypes.edgeEvent);
    final payload = event['payload'] as Map<String, dynamic>;
    expect(payload['edge'], 'edge_a');
    expect(payload['message'], 'edge_a fired');
    expect(payload.containsKey('severity'), isFalse);
    expect(payload.containsKey('from'), isFalse);
    expect(payload.containsKey('to'), isFalse);
  });

  test('emitEdgeEvent includes optional severity and sourceRef', () {
    Uyava.emitEdgeEvent(
      edge: 'edge_b',
      message: 'edge_b routed',
      severity: UyavaSeverity.warn,
      sourceRef: 'package:test/source.dart:10:2',
    );

    expect(captured, hasLength(1));
    final payload = captured.single['payload'] as Map<String, dynamic>;
    expect(payload['edge'], 'edge_b');
    expect(payload['message'], 'edge_b routed');
    expect(payload['severity'], UyavaSeverity.warn.name);
    expect(payload['sourceRef'], 'package:test/source.dart:10:2');
  });
}
