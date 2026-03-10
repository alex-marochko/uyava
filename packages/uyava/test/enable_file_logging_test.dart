import 'dart:io';

import 'package:test/test.dart';
import 'package:uyava/uyava.dart';

void main() {
  group('Uyava.enableFileLogging', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'uyava_enable_file_logging',
      );
      Uyava.replaceGraph();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      Uyava.replaceGraph();
      final bool hasVmService = Uyava.transports.any(
        (transport) => transport.channel == UyavaTransportChannel.vmService,
      );
      if (!hasVmService) {
        Uyava.registerTransport(
          const UyavaVmServiceTransport(eventKind: 'ext.uyava.event'),
        );
      }
    });

    test('registers file transport and flushes via shutdownTransports', () async {
      final int initialCount = Uyava.transports.length;

      final UyavaFileTransport transport = await Uyava.enableFileLogging(
        config: UyavaFileLoggerConfig(
          directoryPath: tempDir.path,
          flushInterval: const Duration(milliseconds: 50),
        ),
      );

      expect(
        Uyava.transports.length,
        initialCount + 1,
        reason:
            'enableFileLogging should register the transport when registerTransport=true.',
      );
      expect(Uyava.transports.contains(transport), isTrue);
      expect(
        Uyava.transports.where(
          (t) => t.channel == UyavaTransportChannel.localFile,
        ),
        isNotEmpty,
      );

      Uyava.replaceGraph(nodes: const <UyavaNode>[UyavaNode(id: 'alpha')]);

      await Uyava.shutdownTransports();

      final List<File> logFiles = tempDir
          .listSync()
          .whereType<File>()
          .where((File file) => file.path.endsWith('.uyava'))
          .toList();

      expect(
        logFiles,
        isNotEmpty,
        reason: 'shutdownTransports should flush pending log data to disk.',
      );
      expect(
        Uyava.transports,
        isEmpty,
        reason:
            'shutdownTransports should dispose and remove registered transports.',
      );
    });

    test('respects injected file transport starter', () async {
      final Directory dir = tempDir;
      int callCount = 0;

      Future<UyavaFileTransport> starter(UyavaFileLoggerConfig config) {
        callCount += 1;
        expect(config.directoryPath, dir.path);
        return UyavaFileTransport.start(config: config);
      }

      Uyava.setFileTransportStarter(starter);
      UyavaFileTransport? transport;
      try {
        transport = await Uyava.enableFileLogging(
          config: UyavaFileLoggerConfig(
            directoryPath: dir.path,
            flushInterval: const Duration(milliseconds: 20),
          ),
        );
        expect(callCount, 1);
      } finally {
        await transport?.dispose();
        if (transport != null) {
          Uyava.unregisterTransport(transport.channel);
        }
        Uyava.setFileTransportStarter(null);
      }
    });
  });
}
