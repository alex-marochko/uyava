part of 'package:uyava/uyava.dart';

extension _UyavaTransportOps on _UyavaRuntime {
  List<UyavaTransport> get transports => transportHub.transports;

  void registerTransport(
    UyavaTransport transport, {
    bool replaceExisting = true,
  }) {
    transportHub.register(transport, replace: replaceExisting);
  }

  void unregisterTransport(UyavaTransportChannel channel) {
    transportHub.unregister(channel);
  }

  Future<void> shutdownTransports() async {
    await disableConsoleLogging();
    await transportHub.shutdown();
  }

  Future<UyavaFileTransport> enableFileLogging({
    required UyavaFileLoggerConfig config,
    bool registerTransport = true,
    bool replaceExisting = true,
  }) async {
    final UyavaFileTransport transport = await fileTransportStarter(config);
    if (registerTransport) {
      transportHub.register(transport, replace: replaceExisting);
    }
    return transport;
  }

  UyavaConsoleLogger enableConsoleLogging({
    UyavaConsoleLoggerConfig? config,
    Stream<dynamic>? diagnosticsStream,
  }) {
    final UyavaConsoleLogger logger = UyavaConsoleLogger(
      config: config ?? UyavaConsoleLoggerConfig(),
    );
    if (diagnosticsStream != null) {
      logger.attachDiagnosticsStream(diagnosticsStream);
    }
    _attachConsoleLogger(logger);
    return logger;
  }

  Future<void> disableConsoleLogging() async {
    final UyavaConsoleLogger? logger = consoleLogger;
    consoleLogger = null;
    await consoleTransportTap?.cancel();
    consoleTransportTap = null;
    if (logger != null) {
      await logger.dispose();
    }
  }

  Future<UyavaLogArchive> exportCurrentArchive({String? targetDirectoryPath}) {
    final UyavaFileTransport? transport = _primaryFileTransport();
    if (transport == null) {
      throw StateError(
        'Uyava export requested but no file transport is registered.',
      );
    }
    return transport.exportArchive(targetDirectoryPath: targetDirectoryPath);
  }

  Future<UyavaLogArchive> cloneActiveArchive({String? targetDirectoryPath}) {
    final UyavaFileTransport? transport = _primaryFileTransport();
    if (transport == null) {
      throw StateError(
        'Uyava clone requested but no file transport is registered.',
      );
    }
    return transport.cloneActiveArchive(
      targetDirectoryPath: targetDirectoryPath,
    );
  }

  Future<UyavaLogArchive?> latestArchiveSnapshot({bool includeExports = true}) {
    final UyavaFileTransport? transport = _primaryFileTransport();
    if (transport == null) {
      return Future<UyavaLogArchive?>.value(null);
    }
    return transport.latestArchiveSnapshot(includeExports: includeExports);
  }

  Stream<UyavaLogArchiveEvent>? get archiveEvents {
    return _primaryFileTransport()?.archiveEvents;
  }

  Stream<UyavaDiscardStats>? get discardStatsStream {
    return _primaryFileTransport()?.discardStatsStream;
  }

  UyavaDiscardStats? get latestDiscardStats {
    return _primaryFileTransport()?.latestDiscardStats;
  }

  UyavaFileTransport? _primaryFileTransport() {
    final Iterable<UyavaFileTransport> fileTransports = transportHub.transports
        .whereType<UyavaFileTransport>();
    if (fileTransports.isEmpty) {
      return null;
    }
    return fileTransports.first;
  }

  void _attachConsoleLogger(UyavaConsoleLogger next) {
    final UyavaConsoleLogger? previous = consoleLogger;
    consoleLogger = next;

    // Cancel previous listeners to avoid duplicate delivery.
    unawaited(consoleTransportTap?.cancel());
    consoleTransportTap = transportHub.events.listen(_handleTransportEvent);

    if (previous != null && !identical(previous, next)) {
      unawaited(previous.dispose());
    }
  }

  void _handleTransportEvent(UyavaTransportEvent event) {
    final UyavaConsoleLogger? logger = consoleLogger;
    if (logger == null) {
      return;
    }
    final UyavaConsoleLogRecord? record = _consoleRecordFromTransport(event);
    if (record == null) {
      return;
    }
    logger.log(record);
  }
}
