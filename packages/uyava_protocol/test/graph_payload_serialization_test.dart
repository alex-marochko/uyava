import 'package:test/test.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('UyavaGraphNodePayload', () {
    test('sanitize normalizes tags, color, and shape', () {
      final result = UyavaGraphNodePayload.sanitize({
        'id': 'nodeA',
        'type': 'service',
        'label': '  Node A  ',
        'tags': ['Auth', 'auth', '  beta  ', '', 42],
        'color': '#ff00aa',
        'shape': ' Hexagon ',
      });

      expect(result.isValid, isTrue);
      final payload = result.payload!;
      expect(payload.id, 'nodeA');
      expect(payload.label, 'Node A');
      expect(payload.tags, ['Auth', 'beta']);
      expect(payload.tagsNormalized, ['auth', 'beta']);
      expect(payload.tagsCatalog, isNotNull);
      expect(payload.color, '#FF00AA');
      expect(payload.shape, 'hexagon');
      expect(payload.lifecycle, UyavaLifecycleState.unknown);
      expect(result.diagnostics, isEmpty);

      final roundTrip = UyavaGraphNodePayload.fromJson(payload.toJson());
      expect(roundTrip, payload);
    });

    test('sanitize reports invalid color/shape', () {
      final result = UyavaGraphNodePayload.sanitize({
        'id': 'nodeB',
        'type': 'service',
        'color': 'not-a-color',
        'shape': 'INVALID SHAPE',
      });

      final diagnosticCodes = result.diagnostics
          .map((d) => d.codeEnum)
          .whereType<UyavaGraphIntegrityCode>()
          .toSet();
      expect(
        diagnosticCodes,
        containsAll(<UyavaGraphIntegrityCode>{
          UyavaGraphIntegrityCode.nodesInvalidColor,
          UyavaGraphIntegrityCode.nodesInvalidShape,
        }),
      );
      expect(result.isValid, isTrue);
      final payload = result.payload;
      expect(payload, isNotNull);
      expect(payload!.color, isNull);
      expect(payload.shape, isNull);
    });
  });

  group('UyavaGraphEdgePayload', () {
    test('sanitize coerces booleans and round-trips JSON', () {
      final result = UyavaGraphEdgePayload.sanitize({
        'id': 'edge1',
        'source': 'a',
        'target': 'b',
        'remapped': 1,
        'bidirectional': true,
      });

      expect(result.diagnostics, isEmpty);
      expect(result.isValid, isTrue);
      final payload = result.payload!;
      expect(payload.remapped, isFalse, reason: 'non-true values become false');
      expect(payload.bidirectional, isTrue);

      final roundTrip = UyavaGraphEdgePayload.fromJson(payload.toJson());
      expect(roundTrip, payload);
    });
  });

  group('Event payloads', () {
    test('node event serializes timestamp and payload map', () {
      final DateTime now = DateTime.utc(2024, 5, 18, 10, 0);
      final entry = UyavaGraphNodeEventPayload(
        nodeId: 'nodeA',
        message: 'Node nodeA flushed an auth metric',
        severity: UyavaSeverity.warn,
        tags: const ['auth'],
        timestamp: now,
        sourceRef: 'package:app/main.dart:10:2',
        payload: const {'foo': 1},
      );

      final json = entry.toJson();
      expect(json['timestamp'], now.toIso8601String());
      expect(json['message'], 'Node nodeA flushed an auth metric');
      final decoded = UyavaGraphNodeEventPayload.fromJson(json);
      expect(decoded, entry);
    });

    test('edge event includes edge id with endpoints', () {
      final DateTime now = DateTime.utc(2024, 5, 18, 11, 0);
      final entry = UyavaGraphEdgeEventPayload(
        edgeId: 'edge1',
        from: 'a',
        to: 'b',
        message: 'Edge a→b delivered payment update',
        severity: UyavaSeverity.info,
        timestamp: now,
        sourceRef: 'package:app/main.dart:12:4',
      );

      final json = entry.toJson();
      expect(json['edge'], 'edge1');
      expect(json['from'], 'a');
      expect(json['to'], 'b');
      expect(json['message'], 'Edge a→b delivered payment update');
      final decoded = UyavaGraphEdgeEventPayload.fromJson(json);
      expect(decoded, entry);
    });
  });

  group('Diagnostic payload', () {
    test('encodes code enum name and decodes wire string', () {
      final DateTime timestamp = DateTime.utc(2024, 5, 18, 12, 30);
      final payload = UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.nodesInvalidColor.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.nodesInvalidColor,
        level: UyavaDiagnosticLevel.warning,
        nodeId: 'nodeA',
        context: const {'value': 'oops'},
        timestamp: timestamp,
      );

      final json = payload.toJson();
      expect(json['codeEnum'], UyavaGraphIntegrityCode.nodesInvalidColor.name);
      expect(json['level'], UyavaDiagnosticLevel.warning.toWireString());

      final decoded = UyavaGraphDiagnosticPayload.fromJson(json);
      expect(decoded.codeEnum, UyavaGraphIntegrityCode.nodesInvalidColor);
      expect(decoded.timestamp, timestamp);
      expect(decoded, payload);
    });

    test('decodes enum name to payload', () {
      final json = {
        'code': 'nodes.invalid_shape',
        'codeEnum': 'nodesInvalidShape',
        'level': 'warning',
      };
      final decoded = UyavaGraphDiagnosticPayload.fromJson(json);
      expect(decoded.codeEnum, UyavaGraphIntegrityCode.nodesInvalidShape);
      expect(decoded.level, UyavaDiagnosticLevel.warning);
    });
  });
}
