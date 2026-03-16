import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:uyava/src/logging/io_adapters.dart';
import 'package:uyava/uyava.dart';

void main() {
  group('File logger worker scheduling', () {
    late Directory tempDir;
    late FakeLogIoAdapter adapter;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('uyava_file_logger_fake');
      adapter = FakeLogIoAdapter(tempDir);
      setUyavaFileLoggerTestOverrides(
        UyavaFileLoggerTestOverrides(
          useSynchronousWorker: true,
          ioAdapter: adapter,
        ),
      );
    });

    tearDown(() async {
      setUyavaFileLoggerTestOverrides(null);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'rotates when exceeding size budget without filesystem adapter',
      () async {
        final UyavaFileTransport transport = await UyavaFileTransport.start(
          config: UyavaFileLoggerConfig(
            directoryPath: tempDir.path,
            maxFileSizeBytes: 64,
            flushInterval: Duration.zero,
          ),
        );

        transport.send(
          UyavaTransportEvent(
            type: 'alpha',
            payload: <String, Object?>{'value': 'a' * 80},
          ),
        );
        transport.send(
          UyavaTransportEvent(
            type: 'beta',
            payload: <String, Object?>{'value': 'b' * 80},
          ),
        );

        await transport.flush();
        await transport.dispose();

        expect(
          adapter.closedArchives.length,
          greaterThan(1),
          reason:
              'Rotation should close an archive before final dispose when size'
              ' threshold is hit.',
        );
      },
    );

    test('flush delegates to injected adapter', () async {
      final UyavaFileTransport transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: Duration.zero,
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'delta',
          payload: const <String, Object?>{'value': 1},
        ),
      );

      await transport.flush();

      expect(adapter.flushCount, greaterThan(0));

      await transport.dispose();
    });

    test('auto flush scheduler triggers periodic flushes', () async {
      final UyavaFileTransport transport = await UyavaFileTransport.start(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 10),
        ),
      );

      transport.send(
        UyavaTransportEvent(
          type: 'auto_flush',
          payload: const <String, Object?>{'value': 1},
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(
        adapter.flushCount,
        greaterThan(0),
        reason:
            'Auto flush scheduler should invoke flush without manual calls.',
      );

      await transport.dispose();
    });
  });
}

class FakeLogIoAdapter extends FileLogIoAdapter {
  FakeLogIoAdapter(this.root);

  final Directory root;
  final List<FileLogIoArchive> closedArchives = <FileLogIoArchive>[];
  int flushCount = 0;
  int openCount = 0;

  @override
  Future<FileLogIoHandle> openLogFile({
    required String directoryPath,
    required String fileName,
    required Map<String, dynamic> headerRecord,
    required DateTime openedAt,
  }) async {
    openCount += 1;
    final File file = File(joinPath(root.path, fileName));
    await file.create(recursive: true);
    final IOSink sink = file.openWrite();
    final CountingBytesSink countingSink = CountingBytesSink(sink);

    countingSink.add(
      ZLibEncoder(
        gzip: true,
      ).convert(utf8.encode('${jsonEncode(headerRecord)}\n')),
    );
    await sink.flush();

    return FileLogIoHandle(
      file: file,
      fileName: fileName,
      openedAt: openedAt,
      sink: sink,
      countingSink: countingSink,
    );
  }

  @override
  Future<void> appendLine(FileLogIoHandle handle, String jsonLine) async {
    handle.countingSink.add(
      ZLibEncoder(gzip: true).convert(utf8.encode('$jsonLine\n')),
    );
  }

  @override
  Future<void> flush(FileLogIoHandle handle) async {
    flushCount += 1;
    await handle.sink.flush();
  }

  @override
  Future<FileLogIoArchive> close(FileLogIoHandle handle) async {
    await handle.sink.close();
    final FileLogIoArchive archive = FileLogIoArchive(
      file: handle.file,
      fileName: handle.fileName,
      openedAt: handle.openedAt,
      completedAt: DateTime.now(),
      sizeBytes: handle.file.existsSync()
          ? handle.file.lengthSync()
          : handle.bytesWritten,
    );
    closedArchives.add(archive);
    return archive;
  }
}
