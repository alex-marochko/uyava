part of '../file_logger.dart';

mixin _StreamingJournalMixin on _FileLoggerWorkerBase {
  File? _streamingJournalFile;
  RandomAccessFile? _streamingJournalRaf;
  Timer? _streamingJournalFlushTimer;
  bool _streamingJournalDirty = false;

  void _appendToStreamingJournal(String jsonLine) {
    if (_streamingJournalRaf == null) {
      _openStreamingJournal();
    }
    try {
      _streamingJournalRaf!.writeStringSync('$jsonLine\n');
      _streamingJournalDirty = true;
    } catch (error, stackTrace) {
      developer.log(
        'Uyava streaming journal write failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void _flushStreamingJournal({bool force = false}) {
    if (_streamingJournalRaf == null) {
      return;
    }
    if (!_streamingJournalDirty && !force) {
      return;
    }
    try {
      _streamingJournalRaf!.flushSync();
      _streamingJournalDirty = false;
    } catch (error, stackTrace) {
      developer.log(
        'Uyava streaming journal flush failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void _openStreamingJournal() {
    if (!bootstrap.streamingJournalEnabled) {
      return;
    }
    _streamingJournalFlushTimer?.cancel();
    final File file = File(_streamingJournalPath);
    _streamingJournalFile = file;
    bool needsHeader = true;
    try {
      file.createSync(recursive: true);
      final bool isEmpty = file.lengthSync() == 0;
      _streamingJournalRaf = file.openSync(mode: FileMode.append);
      _streamingJournalDirty = false;
      needsHeader = isEmpty;
      if (needsHeader) {
        _writeStreamingHeader();
      }
      _streamingJournalFlushTimer = Timer.periodic(
        _streamingJournalFlushInterval,
        (_) => _flushStreamingJournal(),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Uyava streaming journal open failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
      _streamingJournalRaf = null;
    }
  }

  @override
  void _closeStreamingJournal({required bool keepFile}) {
    _streamingJournalFlushTimer?.cancel();
    _streamingJournalFlushTimer = null;
    if (_streamingJournalRaf != null) {
      try {
        _flushStreamingJournal(force: true);
        _streamingJournalRaf!.closeSync();
      } catch (error, stackTrace) {
        developer.log(
          'Uyava streaming journal close failed: $error',
          name: 'Uyava',
          error: error,
          stackTrace: stackTrace,
        );
      }
      _streamingJournalRaf = null;
    }
    if (!keepFile && _streamingJournalFile?.existsSync() == true) {
      try {
        _streamingJournalFile!.deleteSync();
      } catch (error, stackTrace) {
        developer.log(
          'Uyava streaming journal delete failed: $error',
          name: 'Uyava',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (!keepFile) {
      _streamingJournalFile = null;
    }
    _streamingJournalDirty = false;
  }

  Future<void> _recoverStreamingJournalIfPresent() async {
    final File file = File(_streamingJournalPath);
    if (!file.existsSync()) {
      return;
    }
    if (file.lengthSync() == 0) {
      try {
        file.deleteSync();
      } catch (_) {}
      return;
    }

    final String recoveredName = _buildRecoveredJournalName();
    final File destination = File(joinPath(_directory.path, recoveredName));
    IOSink? sink;
    try {
      sink = destination.openWrite();
      final CountingBytesSink counting = CountingBytesSink(sink);
      final ChunkedConversionSink<List<int>> gzipSink = GZipCodec(
        level: ZLibOption.defaultLevel,
      ).encoder.startChunkedConversion(counting);

      final FileStat stat = file.statSync();
      final DateTime openedAt = stat.changed;
      DateTime completedAt = stat.modified;
      if (completedAt.isBefore(openedAt)) {
        completedAt = openedAt;
      }

      final Map<String, dynamic> header = _sessionHeaderRecord(
        recoveredName,
        openedAt,
      );
      gzipSink.add(utf8.encode('${jsonEncode(header)}\n'));

      final Stream<String> lines = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final String line in lines) {
        if (line.trim().isEmpty) {
          continue;
        }
        gzipSink.add(utf8.encode('$line\n'));
      }

      gzipSink.close();

      final int sizeBytes = destination.existsSync()
          ? destination.lengthSync()
          : 0;

      final FileLogIoArchive recovered = FileLogIoArchive(
        file: destination,
        fileName: recoveredName,
        openedAt: openedAt,
        completedAt: completedAt,
        sizeBytes: sizeBytes,
      );
      _registerClosedArchive(recovered);
      final Map<String, Object?> archiveMap = _archiveToMap(
        archive: recovered,
        source: recovered.file,
      );
      _notifyArchiveEvent('recovery', archiveMap);
    } catch (error, stackTrace) {
      developer.log(
        'Uyava streaming journal recovery failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      try {
        file.deleteSync();
      } catch (_) {}
    }
  }

  void _writeStreamingHeader() {
    if (_streamingJournalRaf == null) {
      return;
    }
    final DateTime openedAt = _activeFile?.openedAt ?? DateTime.now();
    final Map<String, dynamic> header = _sessionHeaderRecord(
      _currentFileName,
      openedAt,
    );
    try {
      _streamingJournalRaf!.writeStringSync('${jsonEncode(header)}\n');
      _streamingJournalRaf!.flushSync();
    } catch (error, stackTrace) {
      developer.log(
        'Uyava streaming journal header write failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String get _streamingJournalPath =>
      joinPath(_directory.path, bootstrap.streamingJournalFileName);

  Duration get _streamingJournalFlushInterval =>
      Duration(microseconds: bootstrap.streamingJournalFlushIntervalMicros);

  String _buildRecoveredJournalName() {
    final int micros = DateTime.now().microsecondsSinceEpoch;
    return '${bootstrap.filePrefix}-${bootstrap.sessionId}-recovered-$micros.uyava';
  }
}
