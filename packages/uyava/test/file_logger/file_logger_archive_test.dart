import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:uyava/uyava.dart';

import 'file_logger_test_utils.dart';

void main() {
  group('UyavaFileTransport archives', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'uyava_file_logger_archive_test',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('exportArchive produces copy and continues logging', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          retainLatestOnly: true,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      final List<UyavaLogArchiveEvent> events = <UyavaLogArchiveEvent>[];
      final StreamSubscription<UyavaLogArchiveEvent> archiveSub = transport
          .archiveEvents
          .listen(events.add);

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'nodes': 1},
          timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
        ),
      );

      final UyavaLogArchive archive = await transport.exportArchive();
      final File exportedFile = File(archive.path);
      expect(exportedFile.existsSync(), isTrue);

      final List<Map<String, dynamic>> exportedRecords = await readLogRecords(
        exportedFile,
      );
      expect(exportedRecords, isNotEmpty);
      expect(exportedRecords.first['type'], 'sessionHeader');

      transport.send(
        UyavaTransportEvent(
          type: 'nodeEvent',
          scope: UyavaTransportScope.realtime,
          payload: const <String, dynamic>{'nodes': 2},
          timestamp: DateTime.parse('2024-01-01T00:01:00Z'),
        ),
      );
      await transport.flush();

      final List<Map<String, dynamic>> postExportRecords = await readLogRecords(
        exportedFile,
      );
      expect(postExportRecords.length, exportedRecords.length);

      final List<File> rootArchives = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.uyava'))
          .toList();
      expect(rootArchives.length, 1);
      expect(rootArchives.single.path, isNot(archive.path));

      expect(events, hasLength(2));
      expect(
        events.map((UyavaLogArchiveEvent e) => e.kind).toList(),
        <UyavaLogArchiveEventKind>[
          UyavaLogArchiveEventKind.rotation,
          UyavaLogArchiveEventKind.export,
        ],
      );

      await archiveSub.cancel();
      await transport.dispose();
    });

    test('exportArchive succeeds immediately after start', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      final UyavaLogArchive archive = await transport.exportArchive();
      final File exportedFile = File(archive.path);
      expect(exportedFile.existsSync(), isTrue);

      final List<Map<String, dynamic>> exportedRecords = await readLogRecords(
        exportedFile,
      );
      expect(exportedRecords, isNotEmpty);
      expect(exportedRecords.first['type'], 'sessionHeader');

      transport.send(
        UyavaTransportEvent(
          type: 'nodeEvent',
          scope: UyavaTransportScope.realtime,
          payload: const <String, dynamic>{'nodes': 1},
          timestamp: DateTime.parse('2024-01-01T00:02:00Z'),
        ),
      );
      await transport.flush();
      await transport.dispose();
    });

    test('cloneActiveArchive duplicates active log without rotation', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      final List<UyavaLogArchiveEvent> events = <UyavaLogArchiveEvent>[];
      final StreamSubscription<UyavaLogArchiveEvent> archiveSub = transport
          .archiveEvents
          .listen(events.add);

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'nodes': 2},
          timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
        ),
      );

      await transport.flush();

      final UyavaLogArchive clone = await transport.cloneActiveArchive();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(File(clone.path).existsSync(), isTrue);
      expect(events, hasLength(1));
      expect(events.single.kind, UyavaLogArchiveEventKind.clone);
      expect(events.single.archive.path, clone.path);

      final List<File> rootArchives = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.uyava'))
          .toList();
      expect(rootArchives.length, 1);

      final Directory exportsDir = Directory('${tempDir.path}/exports');
      expect(exportsDir.existsSync(), isTrue);
      final List<File> exports = exportsDir
          .listSync()
          .whereType<File>()
          .toList();
      expect(exports.length, 1);
      expect(exports.single.path, clone.path);
      expect(clone.sourcePath, rootArchives.single.path);

      await archiveSub.cancel();
      await transport.dispose();
    });

    test('cloneActiveArchive produces readable gzip snapshot', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
          maxFileSizeBytes: 8 * 1024,
        ),
      );

      for (int i = 0; i < 200; i++) {
        transport.send(
          UyavaTransportEvent(
            type: 'clone_test',
            payload: <String, Object?>{'value': i},
          ),
        );
      }

      final UyavaLogArchive clone = await transport.cloneActiveArchive();
      final List<Map<String, dynamic>> records = await readLogRecords(
        clone.toFile(),
      );
      expect(records.any((r) => r['type'] == 'clone_test'), isTrue);

      await transport.dispose();
    });

    test('cloneActiveArchive succeeds immediately after start', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
        ),
      );

      final UyavaLogArchive archive = await transport.cloneActiveArchive();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(File(archive.path).existsSync(), isTrue);
      final File exported = File(archive.path);
      expect(archive.sizeBytes, exported.lengthSync());

      transport.send(
        UyavaTransportEvent(
          type: 'nodeEvent',
          scope: UyavaTransportScope.realtime,
          payload: const <String, dynamic>{'nodes': 2},
          timestamp: DateTime.parse('2024-01-01T00:03:00Z'),
        ),
      );
      await transport.flush();
      await transport.dispose();
    });

    test(
      'latestArchiveSnapshot returns null when nothing closed yet',
      () async {
        final transport = await UyavaFileTransport.start(
          config: UyavaFileLoggerConfig(
            directoryPath: tempDir.path,
            flushInterval: const Duration(milliseconds: 20),
          ),
        );

        final UyavaLogArchive? latest = await transport.latestArchiveSnapshot(
          includeExports: true,
        );
        expect(latest, isNull);

        await transport.dispose();
      },
    );

    test(
      'latestArchiveSnapshot exposes exported archive without rotation',
      () async {
        final transport = await UyavaFileTransport.start(
          config: UyavaFileLoggerConfig(
            directoryPath: tempDir.path,
            flushInterval: const Duration(milliseconds: 20),
          ),
        );

        transport.send(
          UyavaTransportEvent(
            type: 'snapshot.replaceGraph',
            scope: UyavaTransportScope.snapshot,
            payload: const <String, dynamic>{'nodes': 5},
          ),
        );

        final UyavaLogArchive archive = await transport.exportArchive();

        final UyavaLogArchive? fromExport = await transport
            .latestArchiveSnapshot(includeExports: true);
        expect(fromExport, isNotNull);
        expect(fromExport!.path, archive.path);
        expect(fromExport.sizeBytes, archive.sizeBytes);

        final UyavaLogArchive? fromRoot = await transport.latestArchiveSnapshot(
          includeExports: false,
        );
        expect(fromRoot, isNotNull);
        expect(fromRoot!.path, archive.sourcePath);

        await transport.dispose();
      },
    );

    test(
      'latestArchiveSnapshot falls back to exports when retention deletes source',
      () async {
        final transport = await UyavaFileTransport.start(
          config: UyavaFileLoggerConfig(
            directoryPath: tempDir.path,
            retainLatestOnly: true,
            flushInterval: const Duration(milliseconds: 20),
          ),
        );

        transport.send(
          UyavaTransportEvent(
            type: 'snapshot.replaceGraph',
            scope: UyavaTransportScope.snapshot,
            payload: const <String, dynamic>{'nodes': 3},
          ),
        );

        final UyavaLogArchive archive = await transport.exportArchive();

        final UyavaLogArchive? exportsOnly = await transport
            .latestArchiveSnapshot(includeExports: true);
        expect(exportsOnly, isNotNull);
        expect(exportsOnly!.path, archive.path);

        final UyavaLogArchive? missingSource = await transport
            .latestArchiveSnapshot(includeExports: false);
        expect(missingSource, isNull);

        await transport.dispose();
      },
    );

    test(
      'exportArchive falls back to exports directory for root target',
      () async {
        final transport = await UyavaFileTransport.start(
          config: UyavaFileLoggerConfig(
            directoryPath: tempDir.path,
            retainLatestOnly: true,
            flushInterval: const Duration(milliseconds: 20),
          ),
        );

        transport.send(
          UyavaTransportEvent(
            type: 'snapshot.replaceGraph',
            payload: const <String, dynamic>{'nodes': 1},
            scope: UyavaTransportScope.snapshot,
          ),
        );

        final UyavaLogArchive archive = await transport.exportArchive(
          targetDirectoryPath: tempDir.path,
        );

        final String parentPath = File(archive.path).parent.path;
        expect(parentPath.endsWith('exports'), isTrue);

        await transport.dispose();
      },
    );

    test(
      'exportArchive generates unique file names for consecutive exports',
      () async {
        final transport = await UyavaFileTransport.start(
          config: UyavaFileLoggerConfig(
            directoryPath: tempDir.path,
            flushInterval: const Duration(milliseconds: 20),
          ),
        );

        transport.send(
          UyavaTransportEvent(
            type: 'snapshot.replaceGraph',
            payload: const <String, dynamic>{'nodes': 1},
            scope: UyavaTransportScope.snapshot,
          ),
        );

        final UyavaLogArchive first = await transport.exportArchive();

        transport.send(
          UyavaTransportEvent(
            type: 'snapshot.replaceGraph',
            payload: const <String, dynamic>{'nodes': 2},
            scope: UyavaTransportScope.snapshot,
          ),
        );

        final UyavaLogArchive second = await transport.exportArchive();

        expect(second.fileName, isNot(equals(first.fileName)));
        expect(File(second.path).existsSync(), isTrue);

        await transport.dispose();
      },
    );

    test('exportArchive enforces maxExportCount', () async {
      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
          maxExportCount: 2,
        ),
      );

      Future<UyavaLogArchive> exportWithNode(int nodeCount) async {
        transport.send(
          UyavaTransportEvent(
            type: 'snapshot.replaceGraph',
            scope: UyavaTransportScope.snapshot,
            payload: <String, dynamic>{'nodes': nodeCount},
            timestamp: DateTime.utc(2024, 1, 1, 0, nodeCount),
          ),
        );
        return transport.exportArchive();
      }

      final UyavaLogArchive first = await exportWithNode(1);
      final UyavaLogArchive second = await exportWithNode(2);
      final UyavaLogArchive third = await exportWithNode(3);

      final Directory exportsDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}exports',
      );
      final List<File> exports = exportsDir.existsSync()
          ? exportsDir.listSync().whereType<File>().toList()
          : <File>[];

      expect(exports.length, 2);
      final List<String> exportedNames = exports
          .map((File file) => file.uri.pathSegments.last)
          .toList();
      expect(exportedNames, contains(second.fileName));
      expect(exportedNames, contains(third.fileName));
      expect(File(first.path).existsSync(), isFalse);

      await transport.dispose();
    });

    test('exportArchive enforces maxExportTotalBytes', () async {
      final Directory exportsDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}exports',
      );
      await exportsDir.create(recursive: true);

      final File staleA = File(
        '${exportsDir.path}${Platform.pathSeparator}stale_a.uyava',
      );
      staleA.writeAsBytesSync(List<int>.filled(2048, 1));
      final File staleB = File(
        '${exportsDir.path}${Platform.pathSeparator}stale_b.uyava',
      );
      staleB.writeAsBytesSync(List<int>.filled(2048, 2));

      final transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 20),
          maxExportTotalBytes: 3 * 1024,
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'snapshot.replaceGraph',
          scope: UyavaTransportScope.snapshot,
          payload: const <String, dynamic>{'nodes': 99},
          timestamp: DateTime.utc(2024, 1, 1, 0, 0, 30),
        ),
      );

      final UyavaLogArchive fresh = await transport.exportArchive();

      final List<File> exports = exportsDir
          .listSync()
          .whereType<File>()
          .toList();
      final int totalBytes = exports.fold<int>(
        0,
        (int sum, File file) => sum + file.lengthSync(),
      );

      expect(totalBytes, lessThanOrEqualTo(3 * 1024));
      expect(File(fresh.path).existsSync(), isTrue);
      expect(staleA.existsSync() && staleB.existsSync(), isFalse);

      await transport.dispose();
    });
  });
}
