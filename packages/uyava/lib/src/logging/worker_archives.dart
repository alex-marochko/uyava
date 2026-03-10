part of '../file_logger.dart';

mixin _ArchiveManagerMixin on _FileLoggerWorkerBase {
  final List<FileLogIoArchive> _closedArchives = <FileLogIoArchive>[];
  final List<Map<String, Object?>> _exportedArchives = <Map<String, Object?>>[];

  Future<Map<String, Object?>> rotateAndExport({
    String? targetDirectoryPath,
  }) async {
    if (_disposed) {
      throw StateError('File logger worker already disposed.');
    }
    await _ensureFile(DateTime.now());
    final FileLogIoArchive? closed = await _closeActiveFile();
    if (closed == null) {
      throw StateError('Export requested before initialization.');
    }
    _registerClosedArchive(closed);
    final Map<String, Object?> sealedArchive = _archiveToMap(
      archive: closed,
      source: closed.file,
    );
    _notifyArchiveEvent('rotation', sealedArchive);
    if (bootstrap.streamingJournalEnabled) {
      _closeStreamingJournal(keepFile: false);
    }
    await _openNextLogFile();
    if (bootstrap.streamingJournalEnabled) {
      _openStreamingJournal();
    }
    final File destination = await _copyArchive(
      closed: closed,
      targetDirectoryPath: targetDirectoryPath,
    );
    final Map<String, Object?> archiveMap = _archiveToMap(
      archive: FileLogIoArchive(
        file: destination,
        fileName: destination.uri.pathSegments.last,
        openedAt: closed.openedAt,
        completedAt: closed.completedAt,
        sizeBytes: destination.existsSync() ? destination.lengthSync() : 0,
      ),
      source: closed.file,
    );
    _exportedArchives.add(archiveMap);
    _pruneExportedArchives();
    await _enforceExportDirectoryRetention(preserve: destination);
    _notifyArchiveEvent('export', archiveMap);
    await _enforceRetention();
    return archiveMap;
  }

  Future<Map<String, Object?>> cloneActiveArchive({
    String? targetDirectoryPath,
  }) async {
    if (_disposed) {
      throw StateError('File logger worker already disposed.');
    }
    await _ensureFile(DateTime.now());
    final FileLogIoHandle? active = _activeFile;
    if (active == null) {
      throw StateError('Clone requested before initialization.');
    }
    await ioAdapter.flush(active);
    if (bootstrap.streamingJournalEnabled) {
      _flushStreamingJournal(force: true);
    }
    final File source = File(joinPath(_directory.path, _currentFileName));
    if (!source.existsSync()) {
      throw StateError('Active archive file missing on disk.');
    }
    final DateTime openedAt = active.openedAt;
    final DateTime snapshotAt = DateTime.now();
    int sizeBytes = 0;
    try {
      sizeBytes = source.lengthSync();
    } catch (_) {}
    final FileLogIoArchive snapshot = FileLogIoArchive(
      file: source,
      fileName: _currentFileName,
      openedAt: openedAt,
      completedAt: snapshotAt,
      sizeBytes: sizeBytes,
    );
    final File destination = await _copyArchive(
      closed: snapshot,
      targetDirectoryPath: targetDirectoryPath,
    );
    final Map<String, Object?> archiveMap = _archiveToMap(
      archive: FileLogIoArchive(
        file: destination,
        fileName: destination.uri.pathSegments.last,
        openedAt: openedAt,
        completedAt: snapshotAt,
        sizeBytes: destination.existsSync() ? destination.lengthSync() : 0,
      ),
      source: source,
    );
    _exportedArchives.add(archiveMap);
    _pruneExportedArchives();
    await _enforceExportDirectoryRetention(preserve: destination);
    _notifyArchiveEvent('clone', archiveMap);
    return archiveMap;
  }

  Map<String, Object?>? latestArchive({required bool includeExports}) {
    _pruneClosedArchives();
    if (includeExports) {
      _pruneExportedArchives();
    }
    final List<Map<String, Object?>> candidates = <Map<String, Object?>>[];
    for (final FileLogIoArchive archive in _closedArchives) {
      candidates.add(_archiveToMap(archive: archive, source: archive.file));
    }
    if (includeExports) {
      candidates.addAll(_exportedArchives);
    }
    if (candidates.isEmpty) {
      return null;
    }
    Map<String, Object?> best = candidates.first;
    for (int i = 1; i < candidates.length; i++) {
      final Map<String, Object?> candidate = candidates[i];
      if ((candidate['completedAtMicros'] as int) >
          (best['completedAtMicros'] as int)) {
        best = candidate;
        continue;
      }
      if ((candidate['completedAtMicros'] as int) ==
          (best['completedAtMicros'] as int)) {
        final bool candidateIsExport =
            candidate['sourcePath'] != candidate['path'];
        final bool bestIsExport = best['sourcePath'] != best['path'];
        if (candidateIsExport && !bestIsExport) {
          best = candidate;
        }
      }
    }
    return best;
  }

  Future<File> _copyArchive({
    required FileLogIoArchive closed,
    String? targetDirectoryPath,
  }) async {
    Directory destination = targetDirectoryPath != null
        ? Directory(targetDirectoryPath)
        : Directory(joinPath(_directory.path, 'exports'));
    final String loggingRoot = _directory.absolute.path;
    if (destination.absolute.path == loggingRoot) {
      destination = Directory(joinPath(_directory.path, 'exports'));
    }
    await destination.create(recursive: true);

    final String originalName = closed.fileName;
    File destinationFile = File(joinPath(destination.path, originalName));
    int attempt = 1;
    while (destinationFile.existsSync()) {
      final String candidate = _withExportSuffix(originalName, attempt);
      destinationFile = File(joinPath(destination.path, candidate));
      attempt += 1;
    }

    await closed.file.copy(destinationFile.path);
    return destinationFile;
  }

  @override
  void _registerClosedArchive(FileLogIoArchive archive) {
    _closedArchives.add(archive);
    _pruneClosedArchives();
  }

  void _pruneClosedArchives() {
    _closedArchives.removeWhere((archive) => !archive.file.existsSync());
    if (_closedArchives.length > bootstrap.maxFileCount + 1) {
      final int removeCount =
          _closedArchives.length - (bootstrap.maxFileCount + 1);
      _closedArchives.removeRange(0, removeCount);
    }
  }

  void _pruneExportedArchives() {
    _exportedArchives.removeWhere((archive) {
      final String? path = archive['path'] as String?;
      return path == null || !File(path).existsSync();
    });
    const int maxExportHistory = 16;
    if (_exportedArchives.length > maxExportHistory) {
      final int removeCount = _exportedArchives.length - maxExportHistory;
      _exportedArchives.removeRange(0, removeCount);
    }
  }

  @override
  Map<String, Object?> _archiveToMap({
    required FileLogIoArchive archive,
    required File source,
  }) {
    final int sizeBytes = archive.file.existsSync()
        ? archive.file.lengthSync()
        : archive.sizeBytes;
    return <String, Object?>{
      'path': archive.file.path,
      'fileName': archive.file.uri.pathSegments.last,
      'sizeBytes': sizeBytes,
      'startedAtMicros': archive.openedAt.microsecondsSinceEpoch,
      'completedAtMicros': archive.completedAt.microsecondsSinceEpoch,
      'sourcePath': source.path,
    };
  }

  Future<void> _enforceExportDirectoryRetention({File? preserve}) async {
    final int? maxCount = bootstrap.maxExportCount;
    final int? maxBytes = bootstrap.maxExportTotalBytes;
    if (maxCount == null && maxBytes == null) {
      return;
    }
    final Directory exportsDir = Directory(
      joinPath(_directory.path, 'exports'),
    );
    if (!exportsDir.existsSync()) {
      return;
    }
    List<FileSystemEntity> rawEntries;
    try {
      rawEntries = exportsDir.listSync();
    } catch (error, stackTrace) {
      developer.log(
        'Uyava export retention scan failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    final List<_ExportFileEntry> entries = rawEntries.whereType<File>().map((
      File file,
    ) {
      final FileStat stat = file.statSync();
      return _ExportFileEntry(
        file: file,
        sizeBytes: stat.size,
        changedAt: stat.changed,
      );
    }).toList();
    if (entries.isEmpty) {
      return;
    }
    entries.sort(
      (_ExportFileEntry a, _ExportFileEntry b) =>
          a.changedAt.compareTo(b.changedAt),
    );
    int totalBytes = 0;
    for (final _ExportFileEntry entry in entries) {
      totalBytes += entry.sizeBytes;
    }

    while (entries.isNotEmpty &&
        ((maxCount != null && entries.length > maxCount) ||
            (maxBytes != null && totalBytes > maxBytes))) {
      final _ExportFileEntry candidate = entries.first;
      if (preserve != null && candidate.file.path == preserve.path) {
        break;
      }
      entries.removeAt(0);
      totalBytes -= candidate.sizeBytes;
      try {
        candidate.file.deleteSync();
      } catch (error, stackTrace) {
        developer.log(
          'Uyava export retention delete failed: $error',
          name: 'Uyava',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _pruneExportedArchives();
  }

  String _withExportSuffix(String fileName, int attempt) {
    if (attempt <= 0) {
      return fileName;
    }
    final int dotIndex = fileName.lastIndexOf('.');
    final String name = dotIndex == -1
        ? fileName
        : fileName.substring(0, dotIndex);
    final String extension = dotIndex == -1 ? '' : fileName.substring(dotIndex);
    return '${name}_export$attempt$extension';
  }
}

class _ExportFileEntry {
  const _ExportFileEntry({
    required this.file,
    required this.sizeBytes,
    required this.changedAt,
  });

  final File file;
  final int sizeBytes;
  final DateTime changedAt;
}
