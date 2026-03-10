part of '../file_logger.dart';

class UyavaFileTransport extends UyavaLocalFileTransport
    implements LogSink, ArchiveRotator, RealtimeThrottler {
  UyavaFileTransport._({required this.config, required Directory directory})
    : _directory = directory,
      _context = _FileLoggerContext(config),
      super(path: directory.path);

  final UyavaFileLoggerConfig config;
  final Directory _directory;
  final _FileLoggerContext _context;

  late final _ArchiveCoordinator _archiveCoordinator;
  late final _LogEventQueue _queue;
  late final _FileWorkerClient _workerClient;
  _FlushScheduler? _autoFlushScheduler;

  bool _isDisposed = false;

  static Future<UyavaFileTransport> start({
    required UyavaFileLoggerConfig config,
  }) async {
    final Directory directory = Directory(config.directoryPath);
    await directory.create(recursive: true);
    final UyavaFileTransport transport = UyavaFileTransport._(
      config: config,
      directory: directory,
    );
    await transport._initialize();
    return transport;
  }

  Future<void> _initialize() async {
    _archiveCoordinator = _ArchiveCoordinator();
    _queue = _LogEventQueue(
      config: config,
      hostMetadata: _context.hostMetadata,
    );
    _workerClient = _FileWorkerClient(
      config: config,
      directory: _directory,
      context: _context,
      archiveCoordinator: _archiveCoordinator,
      testOverrides: fileLoggerTestOverrides,
    );
    await _workerClient.initialize();

    if (config.flushInterval > Duration.zero) {
      _autoFlushScheduler = _FlushScheduler(
        interval: config.flushInterval,
        onTick: () {
          _sendDiscardAggregates();
          _workerClient.requestAutoFlush();
        },
      );
    }
  }

  Stream<UyavaDiscardStats> get discardStatsStream => _queue.discardStatsStream;

  UyavaDiscardStats? get latestDiscardStats => _queue.latestDiscardStats;

  Stream<UyavaLogArchiveEvent> get archiveEvents =>
      _archiveCoordinator.archiveEvents;

  @override
  bool accepts(UyavaTransportEvent event) {
    if (_isDisposed) {
      return false;
    }
    return _queue.accepts(event);
  }

  @override
  bool shouldAllow(UyavaTransportEvent event) => accepts(event);

  @override
  void send(UyavaTransportEvent event) {
    if (_isDisposed || !_queue.shouldAllow(event)) {
      return;
    }
    for (final _QueuedRecord record in _queue.prepareRecords(
      event,
      recordDiscardOnDrop: true,
    )) {
      _workerClient.postRecord(record.record, record.timestampMicros);
    }
  }

  Future<void> logRuntimeError({
    required String source,
    required Object error,
    required StackTrace stackTrace,
    bool isFatal = true,
    String? level,
    String? message,
    String? zoneDescription,
    Map<String, Object?>? context,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    if (_isDisposed) {
      return;
    }

    final Map<String, Object?> payload = buildRuntimeErrorPayload(
      source: source,
      error: error,
      stackTrace: stackTrace,
      isFatal: isFatal,
      level: level,
      message: message,
      zoneDescription: zoneDescription,
      context: context,
    );

    final UyavaTransportEvent event = UyavaTransportEvent(
      type: 'runtimeError',
      payload: payload,
      scope: UyavaTransportScope.diagnostic,
    );

    final List<_QueuedRecord> batch = _queue.prepareRecords(
      event,
      recordDiscardOnDrop: false,
    );

    for (final _QueuedRecord record in batch) {
      _workerClient.postRecord(record.record, record.timestampMicros);
    }

    if (config.crashSafePersistence && batch.isNotEmpty) {
      final Map<String, dynamic> record = batch.last.record;
      try {
        await _workerClient.mirrorPanicRecord(record);
      } catch (error, stack) {
        developer.log(
          'Uyava panic-tail mirroring failed: $error',
          name: 'Uyava',
          error: error,
          stackTrace: stack,
        );
      }
    }
    await _flushWithTimeout(timeout);

    if (config.crashSafePersistence) {
      try {
        final UyavaLogArchive? sealed = await _workerClient.panicSeal(
          reopen: !isFatal && !_isDisposed,
        );
        _archiveCoordinator.cacheLatest(sealed);
      } catch (error, stack) {
        developer.log(
          'Uyava panic-tail seal failed: $error',
          name: 'Uyava',
          error: error,
          stackTrace: stack,
        );
      }
    }
  }

  Future<void> _flushWithTimeout(Duration timeout) async {
    if (_isDisposed) {
      return;
    }
    Future<void> flushFuture;
    try {
      _sendDiscardAggregates();
      flushFuture = _workerClient.flush();
    } catch (error, stackTrace) {
      developer.log(
        'Uyava file transport flush failed to start: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    if (timeout <= Duration.zero) {
      await _awaitFlushIgnoringTimeout(flushFuture);
      return;
    }

    try {
      await flushFuture.timeout(timeout);
    } on TimeoutException {
      developer.log(
        'Uyava panic-tail flush timed out after ${timeout.inMilliseconds} ms.',
        name: 'Uyava',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Uyava panic-tail flush failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _awaitFlushIgnoringTimeout(Future<void> future) async {
    try {
      await future;
    } catch (error, stackTrace) {
      developer.log(
        'Uyava panic-tail flush failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> flush() {
    if (_isDisposed) return Future<void>.value();
    _sendDiscardAggregates();
    return _workerClient.flush();
  }

  @override
  Future<UyavaLogArchive> exportArchive({String? targetDirectoryPath}) {
    if (_isDisposed) {
      return Future.error(
        StateError('Uyava file transport has already been disposed.'),
      );
    }
    _sendDiscardAggregates();
    return _workerClient.exportArchive(
      targetDirectoryPath: targetDirectoryPath,
    );
  }

  @override
  Future<UyavaLogArchive> cloneActiveArchive({String? targetDirectoryPath}) {
    if (_isDisposed) {
      return Future.error(
        StateError('Uyava file transport has already been disposed.'),
      );
    }
    _sendDiscardAggregates();
    return _workerClient.cloneActiveArchive(
      targetDirectoryPath: targetDirectoryPath,
    );
  }

  @override
  Future<UyavaLogArchive?> latestArchiveSnapshot({bool includeExports = true}) {
    if (_isDisposed) {
      return Future<UyavaLogArchive?>.value(
        _archiveCoordinator.cachedLatestArchive,
      );
    }
    return _workerClient.latestArchiveSnapshot(includeExports: includeExports);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _autoFlushScheduler?.cancel();
    await _workerClient.dispose();
    await _queue.dispose();
    await _archiveCoordinator.dispose();
  }

  @visibleForTesting
  void debugSimulateWorkerExit() {
    _workerClient.debugSimulateWorkerExit();
  }

  void _sendDiscardAggregates() {
    for (final _QueuedRecord record in _queue.drainDiscardAggregates()) {
      _workerClient.postRecord(record.record, record.timestampMicros);
    }
  }
}
