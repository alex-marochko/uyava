part of '../file_logger.dart';

abstract class _FileLoggerWorkerBase {
  const _FileLoggerWorkerBase({
    required this.bootstrap,
    required this.ioAdapter,
  });

  final _FileLoggerWorkerBootstrap bootstrap;
  final FileLogIoAdapter ioAdapter;

  Directory get _directory;
  FileLogIoHandle? get _activeFile;
  bool get _disposed;

  void _notifyArchiveEvent(String kind, Map<String, Object?> archive);
  Future<void> _ensureFile(DateTime eventTimestamp);
  Future<FileLogIoArchive?> _closeActiveFile();
  Future<void> _openNextLogFile();
  Future<void> _enforceRetention();
  void _closeStreamingJournal({required bool keepFile});
  void _openStreamingJournal();
  void _flushStreamingJournal({bool force = false});
  void _registerClosedArchive(FileLogIoArchive archive);
  Map<String, Object?> _archiveToMap({
    required FileLogIoArchive archive,
    required File source,
  });
  Map<String, dynamic> _sessionHeaderRecord(String fileName, DateTime openedAt);
  String get _currentFileName;
}

class _FileLoggerWorkerState extends _FileLoggerWorkerBase
    with _ArchiveManagerMixin, _StreamingJournalMixin {
  _FileLoggerWorkerState({
    required super.bootstrap,
    FileLogIoAdapter? logIoAdapter,
  }) : super(ioAdapter: logIoAdapter ?? GzipLogIoAdapter());

  @override
  late final Directory _directory;
  @override
  FileLogIoHandle? _activeFile;
  int _fileIndex = 0;
  @override
  bool _disposed = false;

  File? _panicMirrorFile;

  Future<void> initialize() async {
    _directory = Directory(bootstrap.directoryPath);
    await _directory.create(recursive: true);

    if (bootstrap.streamingJournalEnabled) {
      await _recoverStreamingJournalIfPresent();
    }

    await _openNextLogFile();

    if (bootstrap.streamingJournalEnabled) {
      _openStreamingJournal();
    }

    await _enforceExportDirectoryRetention();
  }

  Future<void> writeRecord(
    Map<String, dynamic> record,
    int timestampMicros,
  ) async {
    if (_disposed) return;
    await _ensureFile(DateTime.fromMicrosecondsSinceEpoch(timestampMicros));
    final FileLogIoHandle? handle = _activeFile;
    if (handle == null) return;
    final String jsonLine = jsonEncode(record);
    await ioAdapter.appendLine(handle, jsonLine);
    if (bootstrap.streamingJournalEnabled) {
      _appendToStreamingJournal(jsonLine);
    }
  }

  Future<void> flush() async {
    if (_disposed) return;
    if (_activeFile != null) {
      await ioAdapter.flush(_activeFile!);
    }
    if (bootstrap.streamingJournalEnabled) {
      _flushStreamingJournal();
    }
  }

  Future<void> appendPanicRecord(Map<String, dynamic> record) async {
    if (!bootstrap.crashSafePersistence) {
      return;
    }
    _panicMirrorFile ??= File(
      joinPath(_directory.path, bootstrap.panicMirrorFileName),
    );
    try {
      if (!_panicMirrorFile!.existsSync()) {
        _panicMirrorFile!.createSync(recursive: true);
      }
      final RandomAccessFile raf = _panicMirrorFile!.openSync(
        mode: FileMode.append,
      );
      try {
        raf.writeStringSync('${jsonEncode(record)}\n');
        raf.flushSync();
      } finally {
        raf.closeSync();
      }
    } catch (error, stackTrace) {
      developer.log(
        'Uyava panic mirror write failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Map<String, dynamic> _sessionHeaderRecord(
    String fileName,
    DateTime openedAt,
  ) {
    return <String, dynamic>{
      'type': 'sessionHeader',
      'schemaVersion': 1,
      'sessionId': bootstrap.sessionId,
      'fileName': fileName,
      'startedAt': openedAt.toIso8601String(),
      'hostMetadata': bootstrap.hostMetadata,
      'config': bootstrap.configSummary,
    };
  }

  Future<Map<String, Object?>?> sealActiveFile({required bool reopen}) async {
    if (_disposed) {
      return null;
    }
    final FileLogIoArchive? closed = await _closeActiveFile();
    if (closed == null) {
      return null;
    }
    _registerClosedArchive(closed);
    if (bootstrap.streamingJournalEnabled) {
      _closeStreamingJournal(keepFile: !reopen);
    }
    final Map<String, Object?> archive = _archiveToMap(
      archive: closed,
      source: closed.file,
    );
    _notifyArchiveEvent(_commandPanicSeal, archive);
    if (reopen) {
      await _openNextLogFile();
      if (bootstrap.streamingJournalEnabled) {
        _openStreamingJournal();
      }
    }
    await _enforceRetention();
    return archive;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final FileLogIoArchive? closed = await _closeActiveFile();
    if (closed != null) {
      _registerClosedArchive(closed);
    }
    if (bootstrap.streamingJournalEnabled) {
      _closeStreamingJournal(keepFile: false);
    }
  }

  @override
  Future<void> _ensureFile(DateTime eventTimestamp) async {
    if (_activeFile == null) {
      await _openNextLogFile();
      return;
    }
    final Duration limit = Duration(microseconds: bootstrap.maxDurationMicros);
    final DateTime openedAt = _activeFile!.openedAt;
    if (eventTimestamp.difference(openedAt) >= limit) {
      await _rotateFile();
    }
    if (_activeFile!.bytesWritten >= bootstrap.maxFileSizeBytes) {
      await _rotateFile();
    }
  }

  Future<void> _rotateFile() async {
    final FileLogIoArchive? closed = await _closeActiveFile();
    if (closed != null) {
      _registerClosedArchive(closed);
      final Map<String, Object?> archiveMap = _archiveToMap(
        archive: closed,
        source: closed.file,
      );
      _notifyArchiveEvent('rotation', archiveMap);
      if (bootstrap.streamingJournalEnabled) {
        _closeStreamingJournal(keepFile: false);
      }
    }
    await _openNextLogFile();
    if (bootstrap.streamingJournalEnabled) {
      _openStreamingJournal();
    }
    await _enforceRetention();
  }

  @override
  Future<FileLogIoArchive?> _closeActiveFile() async {
    final FileLogIoHandle? handle = _activeFile;
    if (handle == null) {
      return null;
    }

    final FileLogIoArchive archive = await ioAdapter.close(handle);
    _activeFile = null;
    return archive;
  }

  @override
  Future<void> _openNextLogFile() async {
    final String fileName = _buildFileName(_fileIndex++);
    final DateTime openedAt = DateTime.now();
    final Map<String, dynamic> header = _sessionHeaderRecord(
      fileName,
      openedAt,
    );
    _activeFile = await ioAdapter.openLogFile(
      directoryPath: _directory.path,
      fileName: fileName,
      headerRecord: header,
      openedAt: openedAt,
    );
  }

  @override
  Future<void> _enforceRetention() async {
    if (bootstrap.retainLatestOnly) {
      final List<FileSystemEntity> entries = _directory.listSync();
      for (final FileSystemEntity entity in entries) {
        if (entity is! File) {
          continue;
        }
        final String path = entity.path;
        if (path.endsWith(_currentFileName)) {
          continue;
        }
        if (path.endsWith(bootstrap.panicMirrorFileName)) {
          continue;
        }
        if (bootstrap.streamingJournalEnabled &&
            path.endsWith(bootstrap.streamingJournalFileName)) {
          continue;
        }
        if (path.contains(
          '${Platform.pathSeparator}exports${Platform.pathSeparator}',
        )) {
          continue;
        }
        try {
          await entity.delete();
        } catch (_) {
          continue;
        }
      }
      _pruneClosedArchives();
      return;
    }

    final List<File> candidates = _directory
        .listSync()
        .whereType<File>()
        .where((File file) => file.path.endsWith('.uyava'))
        .toList();
    if (candidates.length <= bootstrap.maxFileCount) {
      return;
    }
    candidates.sort((File a, File b) {
      final DateTime aChanged = a.statSync().changed;
      final DateTime bChanged = b.statSync().changed;
      return aChanged.compareTo(bChanged);
    });
    final int excess = candidates.length - bootstrap.maxFileCount;
    for (int i = 0; i < excess; i++) {
      try {
        candidates[i].deleteSync();
      } catch (_) {
        continue;
      }
    }
    _pruneClosedArchives();
  }

  @override
  void _notifyArchiveEvent(String kind, Map<String, Object?> archive) {
    bootstrap.responsePort.send(<String, Object?>{
      'type': _messageArchiveEvent,
      'kind': kind,
      'archive': archive,
    });
  }

  @override
  String get _currentFileName =>
      _activeFile?.fileName ?? _buildFileName(_fileIndex - 1);

  String _buildFileName(int index) {
    final String padded = index.toString().padLeft(4, '0');
    return '${bootstrap.filePrefix}-${bootstrap.sessionId}-$padded.uyava';
  }
}
