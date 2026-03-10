import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:uyava/uyava.dart';

import 'file_logger_test_utils.dart';

void main() {
  group('Uyava file logger filters & rotation', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'uyava_file_logger_filters_rotation_test',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('rotates files and enforces retention', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          maxFileSizeBytes: 512,
          maxFileCount: 1,
          flushInterval: const Duration(milliseconds: 200),
        ),
      );

      for (int i = 0; i < 50; i++) {
        transport.send(
          UyavaTransportEvent(
            type: 'snapshot.replaceGraph',
            scope: UyavaTransportScope.snapshot,
            payload: <String, dynamic>{'index': i},
            timestamp: DateTime.now(),
          ),
        );
      }

      await transport.flush();
      await transport.dispose();

      final List<File> files = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.uyava'))
          .toList();

      expect(files.length, 1);
      final List<Map<String, dynamic>> records = await readLogRecords(
        files.single,
      );
      expect(records, isNotEmpty);
      expect(records.first['type'], 'sessionHeader');
    });

    test('skips realtime events when realtime logging disabled', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          realtimeEnabled: false,
          flushInterval: const Duration(milliseconds: 50),
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'nodeEvent',
          scope: UyavaTransportScope.realtime,
          payload: const <String, dynamic>{'id': 'primary'},
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'nodes': 1},
        ),
      );

      await transport.flush();
      await transport.dispose();

      final File file = tempDir.listSync().whereType<File>().singleWhere(
        (File f) => f.path.endsWith('.uyava'),
      );
      final List<Map<String, dynamic>> records = await readLogRecords(file);

      expect(
        records.any(
          (Map<String, dynamic> record) => record['type'] == 'nodeEvent',
        ),
        isFalse,
        reason:
            'Realtime events should be filtered out when realtime logging is disabled.',
      );

      final Map<String, dynamic> discardRecord = records.singleWhere(
        (Map<String, dynamic> record) =>
            record['type'] == '_control.aggregateRealtimeDiscard',
      );
      final Map<String, dynamic> discardPayload = Map<String, dynamic>.from(
        discardRecord['payload'] as Map,
      );
      expect(discardPayload['reason'], 'realtime_disabled');
      expect(discardPayload['count'], 1);
    });

    test('filters events below configured minLevel', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          minLevel: UyavaSeverity.warn,
          flushInterval: const Duration(milliseconds: 50),
        ),
      );

      final DateTime base = DateTime.utc(2024, 1, 1);
      transport.send(
        UyavaTransportEvent(
          type: UyavaEventTypes.nodeEvent,
          scope: UyavaTransportScope.realtime,
          payload: UyavaGraphNodeEventPayload(
            nodeId: 'n1',
            message: 'info pulse',
            severity: UyavaSeverity.info,
            timestamp: base,
          ).toJson(),
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: UyavaEventTypes.nodeEvent,
          scope: UyavaTransportScope.realtime,
          payload: UyavaGraphNodeEventPayload(
            nodeId: 'n1',
            message: 'error pulse',
            severity: UyavaSeverity.error,
            timestamp: base.add(const Duration(seconds: 1)),
          ).toJson(),
        ),
      );

      await transport.flush();
      await transport.dispose();

      final File file = tempDir.listSync().whereType<File>().singleWhere(
        (File f) => f.path.endsWith('.uyava'),
      );
      final List<Map<String, dynamic>> records = await readLogRecords(file);

      final Iterable<Map<String, dynamic>> nodeEvents = records.where(
        (Map<String, dynamic> record) =>
            record['type'] == UyavaEventTypes.nodeEvent,
      );
      expect(nodeEvents.length, 1);

      final Map<String, dynamic> payload = Map<String, dynamic>.from(
        nodeEvents.single['payload'] as Map,
      );
      expect(payload['severity'], 'error');

      final Map<String, dynamic> discardRecord = records.singleWhere(
        (Map<String, dynamic> record) =>
            record['type'] == '_control.aggregateRealtimeDiscard',
      );
      final Map<String, dynamic> discardPayload = Map<String, dynamic>.from(
        discardRecord['payload'] as Map,
      );
      expect(discardPayload['reason'], 'severity_min_level');
      expect(discardPayload['count'], 1);
    });

    test('applies realtime sampling to discard matching events', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          realtimeSamplingRate: 0.0,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      for (int i = 0; i < 5; i++) {
        transport.send(
          UyavaTransportEvent(
            type: 'sampledRealtime',
            scope: UyavaTransportScope.realtime,
            payload: <String, dynamic>{'index': i},
          ),
        );
      }

      await transport.flush();

      final UyavaDiscardStats? stats = transport.latestDiscardStats;
      expect(stats, isNotNull);
      expect(stats!.totalCount, 5);
      expect(stats.countFor('realtime_sampling'), 5);

      await transport.dispose();

      final File file = tempDir.listSync().whereType<File>().singleWhere(
        (File f) => f.path.endsWith('.uyava'),
      );
      final List<Map<String, dynamic>> records = await readLogRecords(file);

      expect(
        records.where(
          (Map<String, dynamic> record) => record['type'] == 'sampledRealtime',
        ),
        isEmpty,
      );

      final Map<String, dynamic> discardRecord = records.singleWhere(
        (Map<String, dynamic> record) =>
            record['type'] == '_control.aggregateRealtimeDiscard',
      );
      final Map<String, dynamic> discardPayload = Map<String, dynamic>.from(
        discardRecord['payload'] as Map,
      );
      expect(discardPayload['reason'], 'realtime_sampling');
      expect(discardPayload['count'], 5);
    });

    test('enforces realtime burst limits within a one-second window', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          realtimeBurstLimitPerSecond: 1,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'burstEvent',
          scope: UyavaTransportScope.realtime,
          payload: const <String, dynamic>{'index': 0},
        ),
      );
      transport.send(
        UyavaTransportEvent(
          type: 'burstEvent',
          scope: UyavaTransportScope.realtime,
          payload: const <String, dynamic>{'index': 1},
        ),
      );

      await transport.flush();

      final UyavaDiscardStats? stats = transport.latestDiscardStats;
      expect(stats, isNotNull);
      expect(stats!.totalCount, 1);
      expect(stats.countFor('realtime_burst'), 1);
      expect(stats.lastReason, 'realtime_burst');

      await transport.dispose();

      final File file = tempDir.listSync().whereType<File>().singleWhere(
        (File f) => f.path.endsWith('.uyava'),
      );
      final List<Map<String, dynamic>> records = await readLogRecords(file);

      final Iterable<Map<String, dynamic>> burstEvents = records.where(
        (Map<String, dynamic> record) => record['type'] == 'burstEvent',
      );
      expect(burstEvents.length, 1);

      final Map<String, dynamic> discardRecord = records.singleWhere(
        (Map<String, dynamic> record) =>
            record['type'] == '_control.aggregateRealtimeDiscard',
      );
      final Map<String, dynamic> discardPayload = Map<String, dynamic>.from(
        discardRecord['payload'] as Map,
      );
      expect(discardPayload['reason'], 'realtime_burst');
      expect(discardPayload['count'], 1);
    });

    test('rotates files when exceeding duration threshold', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          maxDuration: const Duration(milliseconds: 5),
          flushInterval: const Duration(milliseconds: 50),
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'index': 0},
          timestamp: DateTime.now(),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'index': 1},
          timestamp: DateTime.now().add(const Duration(minutes: 1)),
        ),
      );

      await transport.flush();
      await transport.dispose();

      final List<File> files = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.uyava'))
          .toList();

      expect(files.length, greaterThanOrEqualTo(2));
      for (final File file in files) {
        final List<Map<String, dynamic>> records = await readLogRecords(file);
        expect(records.first['type'], 'sessionHeader');
        expect(records.length, greaterThan(1));
      }
    });

    test('rotates under sustained load and caps retention', () async {
      setUyavaFileLoggerTestOverrides(
        const UyavaFileLoggerTestOverrides(useSynchronousWorker: true),
      );
      addTearDown(() {
        setUyavaFileLoggerTestOverrides(null);
      });

      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          maxFileSizeBytes: 512,
          maxFileCount: 3,
          maxDuration: const Duration(milliseconds: 10),
          flushInterval: Duration.zero,
        ),
      );
      addTearDown(() async {
        await transport.dispose();
      });

      final List<UyavaLogArchiveEvent> events = <UyavaLogArchiveEvent>[];
      final StreamSubscription<UyavaLogArchiveEvent> archiveSub = transport
          .archiveEvents
          .listen(events.add);
      addTearDown(() async {
        await archiveSub.cancel();
      });

      final Map<String, dynamic> payload = <String, dynamic>{
        'nodes': List<int>.filled(128, 1),
        'message': 'x' * 1024,
      };

      final DateTime baseTime = DateTime.now().toUtc();
      for (int i = 0; i < 40; i += 1) {
        transport.send(
          UyavaTransportEvent(
            type: 'stressEvent',
            scope: UyavaTransportScope.realtime,
            payload: <String, dynamic>{...payload, 'index': i},
            timestamp: baseTime.add(Duration(milliseconds: i * 50)),
          ),
        );
      }

      await transport.flush();

      final List<File> archives = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.uyava'))
          .toList();
      // Active + closed archives should respect maxFileCount + 1 window.
      expect(archives.length, inInclusiveRange(1, 4));

      final int rotationCount = events
          .where(
            (UyavaLogArchiveEvent e) =>
                e.kind == UyavaLogArchiveEventKind.rotation,
          )
          .length;
      expect(rotationCount, greaterThanOrEqualTo(1));

      final UyavaLogArchive? latest = await transport.latestArchiveSnapshot(
        includeExports: false,
      );
      expect(latest, isNotNull);
      expect(File(latest!.path).existsSync(), isTrue);
      expect(latest.sizeBytes, greaterThan(0));
    });
  });
}
