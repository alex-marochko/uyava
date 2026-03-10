import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:uyava/uyava.dart';

import 'file_logger_test_utils.dart';

void main() {
  group('Uyava file logger streaming & panic handling', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'uyava_file_logger_streaming_panic_test',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('streaming journal mirrors active records', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          streamingJournalEnabled: true,
          streamingJournalFlushInterval: const Duration(milliseconds: 10),
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'nodes': 1},
          timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
        ),
      );

      await transport.flush();

      final File journal = File(
        '${tempDir.path}${Platform.pathSeparator}panic-tail-active.jsonl',
      );
      expect(journal.existsSync(), isTrue);
      final List<Map<String, dynamic>> journalRecords = journal
          .readAsLinesSync()
          .where((String line) => line.trim().isNotEmpty)
          .map((String line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      expect(journalRecords.length, greaterThanOrEqualTo(2));
      expect(journalRecords.first['type'], 'sessionHeader');
      expect(journalRecords.last['type'], 'snapshot.replaceGraph');

      final UyavaLogArchive archive = await transport.exportArchive();
      expect(File(archive.path).existsSync(), isTrue);

      final List<Map<String, dynamic>> reopenedRecords = journal
          .readAsLinesSync()
          .where((String line) => line.trim().isNotEmpty)
          .map((String line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      expect(reopenedRecords.length, 1);
      expect(reopenedRecords.single['type'], 'sessionHeader');

      await transport.dispose();
    });

    test('streaming journal recovers orphaned file on startup', () async {
      final File orphan = File(
        '${tempDir.path}${Platform.pathSeparator}panic-tail-active.jsonl',
      );
      orphan.createSync(recursive: true);
      orphan.writeAsStringSync(
        '{"type":"runtimeError","payload":{"message":"orphan"}}\n',
      );

      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          streamingJournalEnabled: true,
          streamingJournalFlushInterval: const Duration(milliseconds: 10),
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      await transport.latestArchiveSnapshot(includeExports: false);

      final List<File> archives = tempDir
          .listSync()
          .whereType<File>()
          .where((File file) => file.path.endsWith('.uyava'))
          .toList();
      expect(
        archives.any((File file) => file.path.contains('recovered')),
        isTrue,
        reason:
            'Expected recovered archive, found: ${archives.map((f) => f.path).toList()}',
      );

      final File recovered = archives.firstWhere(
        (File file) => file.path.contains('recovered'),
      );
      final List<Map<String, dynamic>> recoveredRecords = await readLogRecords(
        recovered,
      );
      expect(
        recoveredRecords.any(
          (Map<String, dynamic> record) => record['type'] == 'runtimeError',
        ),
        isTrue,
      );

      final File journal = File(
        '${tempDir.path}${Platform.pathSeparator}panic-tail-active.jsonl',
      );
      final List<String> journalLines = journal
          .readAsLinesSync()
          .where((String line) => line.trim().isNotEmpty)
          .toList();
      expect(journalLines.length, 1);

      await transport.dispose();
    });

    test('panic logging mirrors record and seals gzip archive', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          crashSafePersistence: true,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      await transport.logRuntimeError(
        source: 'test',
        error: StateError('panic'),
        stackTrace: StackTrace.current,
        message: 'panic message',
        isFatal: true,
        timeout: const Duration(milliseconds: 500),
      );

      await transport.dispose();

      final File mirror = File(
        '${tempDir.path}${Platform.pathSeparator}panic-tail.jsonl',
      );
      expect(mirror.existsSync(), isTrue);
      final List<String> mirrorLines = mirror
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty)
          .toList();
      expect(mirrorLines, isNotEmpty);
      final Map<String, dynamic> mirrorRecord =
          jsonDecode(mirrorLines.last) as Map<String, dynamic>;
      expect(mirrorRecord['type'], 'runtimeError');
      expect(
        (mirrorRecord['payload'] as Map<String, dynamic>)['message'],
        contains('panic message'),
      );

      final File sealedArchive = tempDir
          .listSync()
          .whereType<File>()
          .firstWhere((File f) => f.path.endsWith('.uyava'));
      final List<Map<String, dynamic>> records = await readLogRecords(
        sealedArchive,
      );
      expect(records.any((r) => r['type'] == 'runtimeError'), isTrue);
    });

    test('panic mirror survives retainLatestOnly cleanup', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          crashSafePersistence: true,
          retainLatestOnly: true,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      await transport.logRuntimeError(
        source: 'test',
        error: StateError('fatal retain latest'),
        stackTrace: StackTrace.current,
        isFatal: true,
        timeout: const Duration(milliseconds: 500),
      );

      await transport.dispose();

      final File mirror = File(
        '${tempDir.path}${Platform.pathSeparator}panic-tail.jsonl',
      );
      expect(mirror.existsSync(), isTrue);

      final List<File> archives = tempDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.uyava'))
          .toList();
      expect(archives, isNotEmpty);
    });

    test('panic logging reopens stream for non-fatal errors', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          crashSafePersistence: true,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      await transport.logRuntimeError(
        source: 'test',
        error: StateError('recoverable'),
        stackTrace: StackTrace.current,
        message: 'recoverable issue',
        isFatal: false,
        timeout: const Duration(milliseconds: 500),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'nodes': 2},
        ),
      );

      await transport.flush();
      await transport.dispose();

      final List<File> archives = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.uyava'))
          .toList();
      expect(archives, isNotEmpty);

      final Set<String> recordTypes = <String>{};
      for (final File archive in archives) {
        final List<Map<String, dynamic>> records = await readLogRecords(
          archive,
        );
        for (final Map<String, dynamic> record in records) {
          recordTypes.add(record['type'] as String);
        }
      }

      expect(recordTypes.contains('runtimeError'), isTrue);
      expect(recordTypes.contains('snapshot.replaceGraph'), isTrue);
    });

    test('logRuntimeError completes when flush response is dropped', () async {
      setUyavaFileLoggerTestOverrides(
        const UyavaFileLoggerTestOverrides(dropFlushResponses: true),
      );
      addTearDown(() {
        setUyavaFileLoggerTestOverrides(null);
      });

      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          crashSafePersistence: true,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      await transport.logRuntimeError(
        source: 'test',
        error: StateError('timeout flush'),
        stackTrace: StackTrace.current,
        message: 'flush without response',
        isFatal: true,
        timeout: const Duration(milliseconds: 50),
      );

      final File mirror = File(
        '${tempDir.path}${Platform.pathSeparator}panic-tail.jsonl',
      );
      expect(mirror.existsSync(), isTrue);

      await transport.dispose();

      final File sealedArchive = tempDir
          .listSync()
          .whereType<File>()
          .firstWhere((File f) => f.path.endsWith('.uyava'));
      final List<Map<String, dynamic>> records = await readLogRecords(
        sealedArchive,
      );
      expect(records.any((r) => r['type'] == 'runtimeError'), isTrue);
    });

    test('archiveEvents emit panicSeal after fatal runtime error', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          crashSafePersistence: true,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      final List<UyavaLogArchiveEvent> events = <UyavaLogArchiveEvent>[];
      final StreamSubscription<UyavaLogArchiveEvent> subscription = transport
          .archiveEvents
          .listen(events.add);

      await transport.logRuntimeError(
        source: 'test',
        error: StateError('fatal seal'),
        stackTrace: StackTrace.current,
        isFatal: true,
        timeout: const Duration(milliseconds: 200),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(
        events.map((UyavaLogArchiveEvent e) => e.kind),
        contains(UyavaLogArchiveEventKind.panicSeal),
      );

      final UyavaLogArchive? latest = await transport.latestArchiveSnapshot(
        includeExports: false,
      );
      expect(latest, isNotNull);
      expect(File(latest!.path).existsSync(), isTrue);

      await transport.dispose();
    });

    test('flush resolves with error when worker exits mid-flight', () async {
      setUyavaFileLoggerTestOverrides(
        const UyavaFileLoggerTestOverrides(dropFlushResponses: true),
      );
      addTearDown(() {
        setUyavaFileLoggerTestOverrides(null);
      });

      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );
      addTearDown(() async {
        await transport.dispose();
      });

      final Future<void> flushFuture = transport.flush();

      // Simulate the worker isolate exiting without answering the flush call.
      transport.debugSimulateWorkerExit();

      await expectLater(
        flushFuture,
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            contains('exited before completing'),
          ),
        ),
      );
    });
  });
}
