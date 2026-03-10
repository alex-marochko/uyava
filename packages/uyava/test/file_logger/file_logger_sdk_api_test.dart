import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:uyava/uyava.dart';

import 'file_logger_test_utils.dart';

void main() {
  group('Uyava file logger SDK API', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'uyava_file_logger_sdk_api_test',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'Uyava.exportCurrentArchive delegates to active file transport',
      () async {
        final UyavaFileTransport transport = await Uyava.enableFileLogging(
          config: UyavaFileLoggerConfig(
            directoryPath: tempDir.path,
            flushInterval: const Duration(milliseconds: 20),
          ),
        );

        addTearDown(() async {
          await transport.dispose();
          Uyava.unregisterTransport(UyavaTransportChannel.localFile);
        });

        transport.send(
          UyavaTransportEvent(
            type: 'snapshot.replaceGraph',
            payload: const <String, dynamic>{'nodes': 3},
            scope: UyavaTransportScope.snapshot,
          ),
        );

        final UyavaLogArchive archive = await Uyava.exportCurrentArchive();
        expect(File(archive.path).existsSync(), isTrue);
      },
    );

    test(
      'Uyava.exportCurrentArchive succeeds before any events are logged',
      () async {
        final UyavaFileTransport transport = await Uyava.enableFileLogging(
          config: UyavaFileLoggerConfig(
            directoryPath: tempDir.path,
            flushInterval: const Duration(milliseconds: 20),
          ),
        );

        addTearDown(() async {
          await transport.dispose();
          Uyava.unregisterTransport(UyavaTransportChannel.localFile);
        });

        final UyavaLogArchive archive = await Uyava.exportCurrentArchive();

        expect(File(archive.path).existsSync(), isTrue);
        final List<Map<String, dynamic>> records = await readLogRecords(
          File(archive.path),
        );
        expect(records, isNotEmpty);
        expect(records.first['type'], 'sessionHeader');
      },
    );

    test('Uyava.cloneActiveArchive forwards to file logger', () async {
      final UyavaFileTransport transport = await Uyava.enableFileLogging(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      addTearDown(() async {
        await Uyava.shutdownTransports();
      });

      final List<UyavaLogArchiveEvent> events = <UyavaLogArchiveEvent>[];
      final StreamSubscription<UyavaLogArchiveEvent> subscription = Uyava
          .archiveEvents!
          .listen(events.add);

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'nodes': 1},
          timestamp: DateTime.utc(2024, 1, 1),
        ),
      );

      await transport.flush();

      final List<File> beforeClone = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.uyava'))
          .toList();
      expect(beforeClone.length, 1);

      final UyavaLogArchive clone = await Uyava.cloneActiveArchive();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events.length, 1);
      expect(events.single.kind, UyavaLogArchiveEventKind.clone);
      expect(events.single.archive.path, clone.path);
      expect(File(clone.path).existsSync(), isTrue);
      expect(clone.sourcePath, beforeClone.single.path);

      final List<File> afterClone = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.uyava'))
          .toList();
      expect(afterClone.length, 1);

      await subscription.cancel();
    });

    test('Uyava exposes discard stats stream and latest snapshot', () async {
      expect(Uyava.discardStatsStream, isNull);
      expect(Uyava.latestDiscardStats, isNull);

      final UyavaFileTransport transport = await Uyava.enableFileLogging(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
          realtimeEnabled: false,
        ),
      );

      addTearDown(() async {
        await Uyava.shutdownTransports();
      });

      final Stream<UyavaDiscardStats>? statsStream = Uyava.discardStatsStream;
      expect(statsStream, isNotNull);

      final List<UyavaDiscardStats> updates = <UyavaDiscardStats>[];
      final StreamSubscription<UyavaDiscardStats> subscription = statsStream!
          .listen(updates.add);

      transport.send(
        UyavaTransportEvent(
          type: 'nodeEvent',
          scope: UyavaTransportScope.realtime,
          payload: const <String, dynamic>{'message': 'discard me'},
        ),
      );

      await Future<void>.delayed(Duration.zero);

      final UyavaDiscardStats? latest = Uyava.latestDiscardStats;
      expect(latest, isNotNull);
      expect(latest!.totalCount, 1);
      expect(latest.reasonCounts['realtime_disabled'], 1);

      expect(updates, isNotEmpty);
      expect(updates.single.totalCount, 1);

      await subscription.cancel();
    });

    test('writes session header and events', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 200),
        ),
      );

      final event = UyavaTransportEvent(
        type: 'snapshot.replaceGraph',
        payload: <String, dynamic>{'nodes': 1},
        scope: UyavaTransportScope.snapshot,
        timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      transport.send(event);
      await transport.flush();
      await transport.dispose();

      final File file = tempDir.listSync().whereType<File>().singleWhere(
        (File f) => f.path.endsWith('.uyava'),
      );

      final List<Map<String, dynamic>> records = await readLogRecords(file);
      expect(records, hasLength(2));
      expect(records.first['type'], 'sessionHeader');
      final Map<String, dynamic> payload = Map<String, dynamic>.from(
        records.last['payload'] as Map,
      );
      expect(payload['nodes'], 1);
      expect(records.last['scope'], 'snapshot');
      expect(records.last['sequenceId'], isNotEmpty);
    });

    test('redacts payloads and records discarded events', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 200),
          redaction: UyavaRedactionConfig(
            allowRawData: false,
            dropFields: const <String>['payload.secret'],
            maskFields: const <String>['payload.token'],
            customHandler: (context) {
              if (context.payload['dropMe'] == true) {
                return null;
              }
              final Map<String, dynamic> next = Map<String, dynamic>.from(
                context.payload,
              );
              next['processed'] = true;
              return next;
            },
          ),
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: <String, dynamic>{
            'rawData': <String, dynamic>{'foo': 'bar'},
            'payload': <String, dynamic>{'secret': 'hide', 'token': 'abc'},
            'dropMe': false,
          },
          timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'nodeEvent',
          scope: UyavaTransportScope.realtime,
          payload: const <String, dynamic>{'dropMe': true},
          timestamp: DateTime.parse('2024-01-01T00:00:01Z'),
        ),
      );

      await transport.flush();
      await transport.dispose();

      final File file = tempDir.listSync().whereType<File>().singleWhere(
        (File f) => f.path.endsWith('.uyava'),
      );
      final List<Map<String, dynamic>> records = await readLogRecords(file);

      expect(
        records.map((r) => r['type']),
        contains('_control.aggregateRealtimeDiscard'),
      );

      final Map<String, dynamic> eventRecord = Map<String, dynamic>.from(
        records.firstWhere(
          (r) =>
              r['type'] != 'sessionHeader' &&
              r['type'] != '_control.aggregateRealtimeDiscard',
        ),
      );
      final Map<String, dynamic> payload = Map<String, dynamic>.from(
        eventRecord['payload'] as Map,
      );
      expect(payload.containsKey('rawData'), isFalse);
      expect((payload['payload'] as Map)['secret'], isNull);
      expect((payload['payload'] as Map)['token'], '***');
      expect(payload['processed'], isTrue);

      final List<dynamic> redactedKeys =
          eventRecord['redactedKeys'] as List<dynamic>;
      expect(
        redactedKeys,
        containsAll(<String>['rawData', 'payload.secret', 'payload.token']),
      );
    });

    test('redaction filters tags and indexed paths', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 50),
          redaction: UyavaRedactionConfig(
            allowRawData: true,
            tagsAllowList: const <String>['foo', 'baz'],
            tagsDenyList: const <String>['blocked'],
            maskFields: const <String>['items[1].secret'],
            dropFields: const <String>['list[0]'],
          ),
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: <String, dynamic>{
            'tags': <String>['Foo', 'blocked', 'Baz'],
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'secret': 'keep'},
              <String, dynamic>{'secret': 'mask-me'},
            ],
            'list': <String>['drop-me', 'keep-me'],
          },
          timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
        ),
      );

      await transport.flush();
      await transport.dispose();

      final File file = tempDir.listSync().whereType<File>().singleWhere(
        (File f) => f.path.endsWith('.uyava'),
      );
      final List<Map<String, dynamic>> records = await readLogRecords(file);
      final Map<String, dynamic> eventRecord = Map<String, dynamic>.from(
        records.singleWhere(
          (Map<String, dynamic> record) =>
              record['type'] == 'snapshot.replaceGraph',
        ),
      );
      final Map<String, dynamic> payload = Map<String, dynamic>.from(
        eventRecord['payload'] as Map,
      );

      expect(payload['tags'], <String>['Foo', 'Baz']);
      final List<dynamic> items = payload['items'] as List<dynamic>;
      expect((items.first as Map)['secret'], 'keep');
      expect((items[1] as Map)['secret'], '***');

      final List<dynamic> list = payload['list'] as List<dynamic>;
      expect(list, <String>['keep-me']);

      final List<dynamic> redactedKeys =
          eventRecord['redactedKeys'] as List<dynamic>;
      expect(redactedKeys, containsAll(<String>['items[1].secret', 'list[0]']));
    });

    test('discard stats expose lifetime counts and stream updates', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
          includeTypes: const <String>['bar'],
          realtimeEnabled: false,
        ),
      );

      final List<UyavaDiscardStats> updates = <UyavaDiscardStats>[];
      final StreamSubscription<UyavaDiscardStats> subscription = transport
          .discardStatsStream
          .listen(updates.add);

      transport.send(
        UyavaTransportEvent(
          type: 'foo',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'nodes': 1},
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'bar',
          scope: UyavaTransportScope.realtime,
          payload: const <String, dynamic>{'nodes': 2},
        ),
      );

      await Future<void>.delayed(Duration.zero);

      final UyavaDiscardStats? latest = transport.latestDiscardStats;
      expect(latest, isNotNull);
      expect(latest!.totalCount, 2);
      expect(latest.lastReason, 'realtime_disabled');
      expect(latest.countFor('include_filter'), 1);
      expect(latest.countFor('realtime_disabled'), 1);

      expect(updates, hasLength(2));
      expect(updates.last.totalCount, 2);

      await subscription.cancel();
      await transport.dispose();
    });
  });
}
