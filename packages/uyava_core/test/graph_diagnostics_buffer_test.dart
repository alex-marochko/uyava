import 'package:test/test.dart';
import 'package:uyava_core/src/models/graph_diagnostics_buffer.dart';
import 'package:uyava_core/src/models/graph_integrity.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('GraphDiagnosticsBuffer', () {
    test('deduplicates repeated app diagnostics', () {
      var ticks = 0;
      DateTime fakeClock() =>
          DateTime.utc(2024, 1, 1).add(Duration(seconds: ticks++));
      final buffer = GraphDiagnosticsBuffer(clock: fakeClock);

      buffer.addAppDiagnostic(
        code: UyavaGraphIntegrityCode.nodesDuplicateId.toWireString(),
        level: UyavaDiagnosticLevel.warning,
        subjects: const ['alpha', 'alpha', ''],
        codeEnum: UyavaGraphIntegrityCode.nodesDuplicateId,
      );

      buffer.addAppDiagnostic(
        code: UyavaGraphIntegrityCode.nodesDuplicateId.toWireString(),
        level: UyavaDiagnosticLevel.warning,
        subjects: const ['alpha'],
        codeEnum: UyavaGraphIntegrityCode.nodesDuplicateId,
      );

      final records = buffer.records;
      expect(records, hasLength(1));
      expect(records.first.subjects, ['alpha']);
      expect(records.first.timestamp, DateTime.utc(2024, 1, 1, 0, 0, 1));
      expect(records.first.codeEnum, UyavaGraphIntegrityCode.nodesDuplicateId);
    });

    test('captures source metadata for app diagnostics', () {
      var ticks = 0;
      DateTime fakeClock() =>
          DateTime.utc(2024, 2, 1).add(Duration(seconds: ticks++));
      final buffer = GraphDiagnosticsBuffer(clock: fakeClock);

      buffer.addAppDiagnostic(
        code: 'ext.demo',
        level: UyavaDiagnosticLevel.info,
        subjects: const ['alpha'],
        sourceId: 'vmService',
        sourceType: 'vmService',
      );
      buffer.addAppDiagnostic(
        code: 'ext.demo',
        level: UyavaDiagnosticLevel.info,
        subjects: const ['alpha'],
        sourceId: 'replay',
        sourceType: 'replayFile',
      );

      final records = buffer.records;
      expect(records, hasLength(2));
      expect(records.first.sourceId, 'vmService');
      expect(records.first.sourceType, 'vmService');
      expect(records.last.sourceId, 'replay');
      expect(records.last.sourceType, 'replayFile');
    });

    test('replaceCoreIssues clears previous core entries but keeps others', () {
      var ticks = 0;
      DateTime fakeClock() =>
          DateTime.utc(2024, 1, 1).add(Duration(seconds: ticks++));
      final buffer = GraphDiagnosticsBuffer(clock: fakeClock);

      buffer.replaceCoreIssues([
        const GraphIntegrityIssue(
          code: UyavaGraphIntegrityCode.nodesMissingId,
          level: UyavaDiagnosticLevel.error,
          nodeId: 'n1',
        ),
      ]);

      buffer.addAppDiagnostic(
        code: 'sdk.custom_warning',
        level: UyavaDiagnosticLevel.warning,
        subjects: const ['edge-1'],
      );

      buffer.replaceCoreIssues([
        const GraphIntegrityIssue(
          code: UyavaGraphIntegrityCode.edgesMissingSource,
          level: UyavaDiagnosticLevel.error,
          edgeId: 'e1',
        ),
      ]);

      final records = buffer.records;
      expect(records, hasLength(2));

      final appRecord = records.first;
      final coreRecord = records.last;

      expect(appRecord.source, GraphDiagnosticSource.app);
      expect(appRecord.code, 'sdk.custom_warning');
      expect(appRecord.codeEnum, isNull);

      expect(coreRecord.source, GraphDiagnosticSource.core);
      expect(
        coreRecord.code,
        UyavaGraphIntegrityCode.edgesMissingSource.toWireString(),
      );
      expect(coreRecord.codeEnum, UyavaGraphIntegrityCode.edgesMissingSource);
      expect(coreRecord.timestamp, DateTime.utc(2024, 1, 1, 0, 0, 2));
    });

    test(
      'context canonicalization treats reordered maps as the same entry',
      () {
        var ticks = 0;
        DateTime fakeClock() =>
            DateTime.utc(2024, 1, 1).add(Duration(seconds: ticks++));
        final buffer = GraphDiagnosticsBuffer(clock: fakeClock);

        buffer.addAppDiagnostic(
          code: UyavaGraphIntegrityCode.nodesInvalidColor.toWireString(),
          level: UyavaDiagnosticLevel.warning,
          subjects: const ['alpha'],
          context: const {'previous': '#ffffff', 'next': '#000000'},
          codeEnum: UyavaGraphIntegrityCode.nodesInvalidColor,
        );

        buffer.addAppDiagnostic(
          code: UyavaGraphIntegrityCode.nodesInvalidColor.toWireString(),
          level: UyavaDiagnosticLevel.warning,
          subjects: const ['alpha'],
          context: const {'next': '#000000', 'previous': '#ffffff'},
          codeEnum: UyavaGraphIntegrityCode.nodesInvalidColor,
        );

        final records = buffer.records;
        expect(records, hasLength(1));
        expect(records.single.timestamp, DateTime.utc(2024, 1, 1, 0, 0, 1));
      },
    );

    test('infers enum when only wire code supplied', () {
      var ticks = 0;
      DateTime fakeClock() =>
          DateTime.utc(2024, 1, 1).add(Duration(seconds: ticks++));
      final buffer = GraphDiagnosticsBuffer(clock: fakeClock);

      buffer.addAppDiagnostic(
        code: UyavaGraphIntegrityCode.nodesInvalidColor.toWireString(),
        level: UyavaDiagnosticLevel.warning,
        subjects: const ['alpha'],
      );

      final record = buffer.records.single;
      expect(record.codeEnum, UyavaGraphIntegrityCode.nodesInvalidColor);
      expect(
        record.code,
        UyavaGraphIntegrityCode.nodesInvalidColor.toWireString(),
      );
    });

    test('addAppDiagnosticPayload canonicalizes payload values', () {
      var ticks = 0;
      DateTime fakeClock() =>
          DateTime.utc(2024, 1, 1).add(Duration(seconds: ticks++));
      final buffer = GraphDiagnosticsBuffer(clock: fakeClock);

      final payload = UyavaGraphDiagnosticPayload(
        code: 'nodes.invalid_color',
        codeEnum: UyavaGraphIntegrityCode.nodesInvalidColor,
        level: UyavaDiagnosticLevel.warning,
        nodeId: 'alpha',
        context: const {'input': '#12'},
        timestamp: DateTime.utc(2024, 3, 10, 12, 30, 0),
      );

      buffer.addAppDiagnosticPayload(payload);

      final record = buffer.records.single;
      expect(record.source, GraphDiagnosticSource.app);
      expect(record.code, 'nodes.invalid_color');
      expect(record.codeEnum, UyavaGraphIntegrityCode.nodesInvalidColor);
      expect(record.subjects, ['alpha']);
      expect(record.context, {'input': '#12'});
      expect(record.timestamp, DateTime.utc(2024, 3, 10, 12, 30, 0));
    });

    test('addAppDiagnosticPayload allows timestamp override', () {
      var ticks = 0;
      DateTime fakeClock() =>
          DateTime.utc(2024, 1, 1).add(Duration(seconds: ticks++));
      final buffer = GraphDiagnosticsBuffer(clock: fakeClock);

      final payload = UyavaGraphDiagnosticPayload(
        code: 'edges.dangling_source',
        codeEnum: UyavaGraphIntegrityCode.edgesDanglingSource,
        level: UyavaDiagnosticLevel.error,
        edgeId: 'edge-42',
      );

      final override = DateTime.utc(2024, 5, 1, 8, 0, 0);
      buffer.addAppDiagnosticPayload(payload, timestamp: override);

      final record = buffer.records.single;
      expect(record.timestamp, override);
      expect(record.subjects, ['edge-42']);
    });

    test('trims oldest records when maxRecords is set', () {
      final buffer = GraphDiagnosticsBuffer(
        clock: () => DateTime.utc(2024, 1, 1),
        maxRecords: 2,
      );

      buffer.addAppDiagnostic(
        code: 'a',
        level: UyavaDiagnosticLevel.info,
        subjects: const ['s1'],
      );
      buffer.addAppDiagnostic(
        code: 'b',
        level: UyavaDiagnosticLevel.info,
        subjects: const ['s2'],
      );
      buffer.addAppDiagnostic(
        code: 'c',
        level: UyavaDiagnosticLevel.info,
        subjects: const ['s3'],
      );

      final records = buffer.records;
      expect(records, hasLength(2));
      expect(records.first.code, 'b');
      expect(records.last.code, 'c');
      expect(buffer.totalTrimmed, 1);
    });
  });
}
