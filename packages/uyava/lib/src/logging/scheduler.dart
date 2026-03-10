part of '../file_logger.dart';

class _FlushScheduler {
  _FlushScheduler({required Duration interval, required VoidCallback onTick}) {
    if (interval > Duration.zero) {
      _timer = Timer.periodic(interval, (_) => onTick());
    }
  }

  Timer? _timer;

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

class _FileWorkerClient {
  _FileWorkerClient({
    required this.config,
    required Directory directory,
    required _FileLoggerContext context,
    required _ArchiveCoordinator archiveCoordinator,
    required UyavaFileLoggerTestOverrides? testOverrides,
  }) : _directory = directory,
       _context = context,
       _archiveCoordinator = archiveCoordinator,
       _testOverrides = testOverrides,
       _dropFlushResponses = testOverrides?.dropFlushResponses ?? false;

  final UyavaFileLoggerConfig config;
  final Directory _directory;
  final _FileLoggerContext _context;
  final _ArchiveCoordinator _archiveCoordinator;
  final UyavaFileLoggerTestOverrides? _testOverrides;
  final bool _dropFlushResponses;

  bool _isDisposed = false;
  Isolate? _workerIsolate;
  late final ReceivePort _responsePort;
  StreamSubscription<dynamic>? _responseSubscription;
  SendPort? _workerSendPort;
  final Map<int, Completer<dynamic>> _pendingRequests =
      <int, Completer<dynamic>>{};
  final Completer<void> _readyCompleter = Completer<void>();
  int _nextRequestId = 0;
  _FileLoggerWorkerState? _syncWorkerState;
  Future<void> _syncWorkerPending = Future<void>.value();

  Future<void> initialize() async {
    _responsePort = ReceivePort();
    _responseSubscription = _responsePort.listen(
      _handleWorkerMessage,
      onError: _handleWorkerError,
    );

    final _FileLoggerWorkerBootstrap bootstrap = _FileLoggerWorkerBootstrap(
      responsePort: _responsePort.sendPort,
      directoryPath: _directory.path,
      sessionId: _context.sessionId,
      filePrefix: config.filePrefix,
      maxFileSizeBytes: config.maxFileSizeBytes,
      maxDurationMicros: config.maxDuration.inMicroseconds,
      maxFileCount: config.maxFileCount,
      maxExportCount: config.maxExportCount,
      maxExportTotalBytes: config.maxExportTotalBytes,
      retainLatestOnly: config.retainLatestOnly,
      configSummary: _context.configSummary,
      hostMetadata: _context.hostMetadata,
      crashSafePersistence: config.crashSafePersistence,
      panicMirrorFileName: config.panicMirrorFileName,
      streamingJournalEnabled: config.streamingJournalEnabled,
      streamingJournalFileName: config.streamingJournalFileName,
      streamingJournalFlushIntervalMicros:
          config.streamingJournalFlushInterval.inMicroseconds,
      dropFlushResponses: _dropFlushResponses,
    );

    final bool useSynchronousWorker =
        _testOverrides?.useSynchronousWorker ?? false;
    final FileLogIoAdapter? ioAdapterOverride = _testOverrides?.ioAdapter;

    if (useSynchronousWorker) {
      _syncWorkerState = _FileLoggerWorkerState(
        bootstrap: bootstrap,
        logIoAdapter: ioAdapterOverride,
      );
      await _syncWorkerState!.initialize();
      _handleWorkerMessage(<String, Object?>{
        'type': _messageReady,
        'sendPort': null,
      });
    } else {
      _workerIsolate = await Isolate.spawn<_FileLoggerWorkerBootstrap>(
        _fileLoggerWorker,
        bootstrap,
        onExit: _responsePort.sendPort,
        onError: _responsePort.sendPort,
        errorsAreFatal: false,
      );
    }

    await _readyCompleter.future;
  }

  void postRecord(Map<String, dynamic> record, int timestampMicros) {
    if (_isDisposed) {
      return;
    }
    if (_syncWorkerState != null) {
      _fireAndForgetSyncWorker(
        (state) => state.writeRecord(record, timestampMicros),
      );
      return;
    }
    final SendPort? port = _workerSendPort;
    if (port == null) {
      developer.log(
        'Uyava file worker is not ready for records.',
        name: 'Uyava',
      );
      return;
    }
    port.send(<String, Object?>{
      'type': _commandEvent,
      'record': record,
      'timestampMicros': timestampMicros,
    });
  }

  Future<void> flush({bool waitForResponse = true}) {
    if (_isDisposed) return Future<void>.value();
    if (_syncWorkerState != null) {
      if (waitForResponse) {
        return _scheduleSyncWorker<void>((_FileLoggerWorkerState state) {
          return state.flush();
        });
      }
      _fireAndForgetSyncWorker((state) => state.flush());
      return Future<void>.value();
    }
    final SendPort? port = _workerSendPort;
    if (port == null) {
      return Future.error(
        StateError('Uyava file worker is not ready for flush.'),
      );
    }
    if (!waitForResponse) {
      port.send(<String, Object?>{'type': _commandFlush});
      return Future<void>.value();
    }
    final Completer<dynamic> completer = Completer<dynamic>();
    final int requestId = _nextRequest();
    _pendingRequests[requestId] = completer;
    port.send(<String, Object?>{'type': _commandFlush, 'requestId': requestId});
    return completer.future.then((_) => null);
  }

  void requestAutoFlush() {
    if (_isDisposed) return;
    unawaited(flush(waitForResponse: false));
  }

  Future<UyavaLogArchive> exportArchive({String? targetDirectoryPath}) {
    if (_isDisposed) {
      return Future.error(
        StateError('Uyava file transport has already been disposed.'),
      );
    }
    if (_syncWorkerState != null) {
      return _scheduleSyncWorker<Map<String, Object?>>(
        (state) =>
            state.rotateAndExport(targetDirectoryPath: targetDirectoryPath),
      ).then((Map<String, Object?> map) {
        final UyavaLogArchive archive = _archiveCoordinator.archiveFromMap(map);
        _archiveCoordinator.cacheLatest(archive);
        return archive;
      });
    }
    final SendPort? port = _workerSendPort;
    if (port == null) {
      return Future.error(
        StateError('Uyava file worker is not ready for export.'),
      );
    }
    final Completer<dynamic> completer = Completer<dynamic>();
    final int requestId = _nextRequest();
    _pendingRequests[requestId] = completer;
    port.send(<String, Object?>{
      'type': _commandRotateExport,
      'requestId': requestId,
      'targetDirectoryPath': targetDirectoryPath,
    });
    return completer.future.then((dynamic value) {
      final UyavaLogArchive archive = value as UyavaLogArchive;
      _archiveCoordinator.cacheLatest(archive);
      return archive;
    });
  }

  Future<UyavaLogArchive> cloneActiveArchive({String? targetDirectoryPath}) {
    if (_isDisposed) {
      return Future.error(
        StateError('Uyava file transport has already been disposed.'),
      );
    }
    if (_syncWorkerState != null) {
      return _scheduleSyncWorker<Map<String, Object?>>(
        (state) =>
            state.cloneActiveArchive(targetDirectoryPath: targetDirectoryPath),
      ).then((Map<String, Object?> map) {
        final UyavaLogArchive archive = _archiveCoordinator.archiveFromMap(map);
        _archiveCoordinator.cacheLatest(archive);
        return archive;
      });
    }
    final SendPort? port = _workerSendPort;
    if (port == null) {
      return Future.error(
        StateError('Uyava file worker is not ready for cloning.'),
      );
    }
    final Completer<dynamic> completer = Completer<dynamic>();
    final int requestId = _nextRequest();
    _pendingRequests[requestId] = completer;
    port.send(<String, Object?>{
      'type': _commandCloneActive,
      'requestId': requestId,
      'targetDirectoryPath': targetDirectoryPath,
    });
    return completer.future.then((dynamic value) {
      final UyavaLogArchive archive = value as UyavaLogArchive;
      _archiveCoordinator.cacheLatest(archive);
      return archive;
    });
  }

  Future<UyavaLogArchive?> latestArchiveSnapshot({bool includeExports = true}) {
    if (_isDisposed) {
      return Future<UyavaLogArchive?>.value(
        _archiveCoordinator.cachedLatestArchive,
      );
    }
    if (_syncWorkerState != null) {
      return _scheduleSyncWorker<Map<String, Object?>?>(
        (state) async => state.latestArchive(includeExports: includeExports),
      ).then((Map<String, Object?>? map) {
        if (map == null) {
          return _archiveCoordinator.cachedLatestArchive;
        }
        final UyavaLogArchive archive = _archiveCoordinator.archiveFromMap(map);
        _archiveCoordinator.cacheLatest(archive);
        return archive;
      });
    }
    final SendPort? port = _workerSendPort;
    if (port == null) {
      return Future.error(
        StateError('Uyava file worker is not ready for snapshot.'),
      );
    }
    final Completer<dynamic> completer = Completer<dynamic>();
    final int requestId = _nextRequest();
    _pendingRequests[requestId] = completer;
    port.send(<String, Object?>{
      'type': _commandLatestArchive,
      'requestId': requestId,
      'includeExports': includeExports,
    });
    return completer.future.then((dynamic value) {
      final UyavaLogArchive? archive = value as UyavaLogArchive?;
      _archiveCoordinator.cacheLatest(archive);
      return archive;
    });
  }

  Future<void> mirrorPanicRecord(Map<String, dynamic> record) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    if (_syncWorkerState != null) {
      return _scheduleSyncWorker<void>(
        (state) => state.appendPanicRecord(record),
      );
    }
    final SendPort? port = _workerSendPort;
    if (port == null) {
      return Future.error(
        StateError('Uyava file worker is not ready for panic mirroring.'),
      );
    }
    final Completer<dynamic> completer = Completer<dynamic>();
    final int requestId = _nextRequest();
    _pendingRequests[requestId] = completer;
    port.send(<String, Object?>{
      'type': _commandPanicMirror,
      'requestId': requestId,
      'record': record,
    });
    return completer.future.then((_) => null);
  }

  Future<UyavaLogArchive?> panicSeal({required bool reopen}) {
    if (_isDisposed) {
      return Future<UyavaLogArchive?>.value(null);
    }
    if (_syncWorkerState != null) {
      return _scheduleSyncWorker<Map<String, Object?>?>(
        (state) => state.sealActiveFile(reopen: reopen),
      ).then((Map<String, Object?>? map) {
        if (map == null) {
          return null;
        }
        final UyavaLogArchive archive = _archiveCoordinator.archiveFromMap(map);
        _archiveCoordinator.cacheLatest(archive);
        return archive;
      });
    }
    final SendPort? port = _workerSendPort;
    if (port == null) {
      return Future.error(
        StateError('Uyava file worker is not ready for panic seal.'),
      );
    }
    final Completer<dynamic> completer = Completer<dynamic>();
    final int requestId = _nextRequest();
    _pendingRequests[requestId] = completer;
    port.send(<String, Object?>{
      'type': _commandPanicSeal,
      'requestId': requestId,
      'reopen': reopen,
    });
    return completer.future.then((dynamic value) {
      return value as UyavaLogArchive?;
    });
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    if (_syncWorkerState != null) {
      try {
        await _scheduleSyncWorker<void>((state) => state.dispose());
      } catch (error, stackTrace) {
        developer.log(
          'Uyava synchronous worker dispose failed: $error',
          name: 'Uyava',
          stackTrace: stackTrace,
        );
      }
    } else {
      final SendPort? port = _workerSendPort;
      if (port != null) {
        final Completer<dynamic> completer = Completer<dynamic>();
        final int requestId = _nextRequest();
        _pendingRequests[requestId] = completer;
        port.send(<String, Object?>{
          'type': _commandDispose,
          'requestId': requestId,
        });
        await completer.future.catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          developer.log(
            'Uyava file worker dispose failed: $error',
            name: 'Uyava',
            stackTrace: stackTrace,
          );
        });
      }
    }
    await _responseSubscription?.cancel();
    _responsePort.close();
    _workerSendPort = null;
    _syncWorkerState = null;
    if (_workerIsolate != null) {
      _workerIsolate!.kill(priority: Isolate.immediate);
      _workerIsolate = null;
    }
  }

  void _handleWorkerMessage(dynamic message) {
    if (message == null) {
      _workerSendPort = null;
      _failPendingRequests(
        'Uyava file worker exited before completing requests.',
      );
      return;
    }
    if (message is List && message.length == 2 && message.first is String) {
      _handleWorkerError(message);
      return;
    }
    if (message is! Map) {
      return;
    }
    final String? type = message['type'] as String?;
    if (type == _messageReady) {
      _workerSendPort = message['sendPort'] as SendPort?;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      return;
    }
    if (type == _messageResponse) {
      final int requestId = message['requestId'] as int;
      final Completer<dynamic>? completer = _pendingRequests.remove(requestId);
      if (completer == null) {
        return;
      }
      final bool success = message['success'] as bool? ?? true;
      if (!success) {
        final String error =
            message['error']?.toString() ??
            'Uyava file worker reported failure.';
        final String? stack = message['stack'] as String?;
        if (stack != null) {
          completer.completeError(
            StateError(error),
            StackTrace.fromString(stack),
          );
        } else {
          completer.completeError(StateError(error));
        }
        return;
      }
      if (message.containsKey('archive')) {
        final Map<String, Object?>? archiveMap =
            message['archive'] as Map<String, Object?>?;
        final UyavaLogArchive? archive = archiveMap != null
            ? _archiveCoordinator.archiveFromMap(archiveMap)
            : null;
        _archiveCoordinator.cacheLatest(archive);
        completer.complete(archive);
        return;
      }
      completer.complete(message['result']);
      return;
    }
    if (type == _messageArchiveEvent) {
      _archiveCoordinator.handleWorkerArchiveEvent(
        kindName: message['kind'] as String?,
        archiveMap: message['archive'] as Map<String, Object?>?,
      );
      return;
    }
    if (type == _messageFatal) {
      final String error =
          message['error']?.toString() ??
          'Uyava file worker terminated unexpectedly.';
      final String? stack = message['stack'] as String?;
      developer.log(
        error,
        name: 'Uyava',
        stackTrace: stack != null ? StackTrace.fromString(stack) : null,
      );
      _failPendingRequests('Uyava file worker fatal error: $error');
      return;
    }
  }

  void _failPendingRequests(String message) {
    if (_pendingRequests.isEmpty) {
      return;
    }
    final List<Completer<dynamic>> pending = List<Completer<dynamic>>.from(
      _pendingRequests.values,
    );
    _pendingRequests.clear();
    for (final Completer<dynamic> completer in pending) {
      if (completer.isCompleted) {
        continue;
      }
      completer.completeError(StateError(message));
    }
  }

  Future<T> _scheduleSyncWorker<T>(
    Future<T> Function(_FileLoggerWorkerState state) action,
  ) {
    final _FileLoggerWorkerState? state = _syncWorkerState;
    if (state == null) {
      return Future<T>.error(
        StateError('Uyava file sync worker is not initialized.'),
      );
    }

    final Completer<T> completer = Completer<T>();
    _syncWorkerPending = _syncWorkerPending.then((_) async {
      final _FileLoggerWorkerState? current = _syncWorkerState;
      if (current == null) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Uyava file sync worker was disposed.'),
          );
        }
        return;
      }
      try {
        final T result = await action(current);
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (error, stackTrace) {
        developer.log(
          'Uyava sync worker operation failed: $error',
          name: 'Uyava',
          error: error,
          stackTrace: stackTrace,
        );
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    });
    return completer.future;
  }

  void _fireAndForgetSyncWorker(
    Future<void> Function(_FileLoggerWorkerState state) action,
  ) {
    unawaited(_scheduleSyncWorker<void>(action).catchError((Object _) {}));
  }

  void _handleWorkerError(dynamic error) {
    if (error is List && error.length == 2) {
      final Object message = error[0];
      final Object stack = error[1];
      developer.log(
        'Uyava file worker error: $message',
        name: 'Uyava',
        stackTrace: stack is StackTrace
            ? stack
            : StackTrace.fromString(stack.toString()),
      );
      return;
    }
    developer.log('Uyava file worker error: $error', name: 'Uyava');
  }

  int _nextRequest() => _nextRequestId++;

  @visibleForTesting
  void debugSimulateWorkerExit() {
    _handleWorkerMessage(null);
  }
}
