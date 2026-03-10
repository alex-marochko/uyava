part of '../file_logger.dart';

class _ArchiveCoordinator {
  final StreamController<UyavaLogArchiveEvent> _archiveEventController =
      StreamController<UyavaLogArchiveEvent>.broadcast(sync: true);

  UyavaLogArchive? _cachedLatestArchive;

  Stream<UyavaLogArchiveEvent> get archiveEvents =>
      _archiveEventController.stream;

  UyavaLogArchive? get cachedLatestArchive => _cachedLatestArchive;

  void handleWorkerArchiveEvent({
    required String? kindName,
    required Map<String, Object?>? archiveMap,
  }) {
    if (kindName == null || archiveMap == null) {
      return;
    }
    final UyavaLogArchiveEventKind? kind = _parseArchiveEventKind(kindName);
    if (kind == null) {
      developer.log(
        'Uyava file worker emitted unknown archive event kind $kindName',
        name: 'Uyava',
      );
      return;
    }
    final UyavaLogArchive archive = archiveFromMap(archiveMap);
    cacheLatest(archive);
    if (!_archiveEventController.isClosed) {
      _archiveEventController.add(
        UyavaLogArchiveEvent(kind: kind, archive: archive),
      );
    }
  }

  void cacheLatest(UyavaLogArchive? archive) {
    if (archive != null) {
      _cachedLatestArchive = archive;
    }
  }

  UyavaLogArchive archiveFromMap(Map<String, Object?> map) {
    return UyavaLogArchive(
      path: map['path'] as String,
      fileName: map['fileName'] as String,
      sizeBytes: map['sizeBytes'] as int,
      startedAt: DateTime.fromMicrosecondsSinceEpoch(
        map['startedAtMicros'] as int,
      ),
      completedAt: DateTime.fromMicrosecondsSinceEpoch(
        map['completedAtMicros'] as int,
      ),
      sourcePath: map['sourcePath'] as String?,
    );
  }

  UyavaLogArchiveEventKind? _parseArchiveEventKind(String value) {
    switch (value) {
      case 'rotation':
        return UyavaLogArchiveEventKind.rotation;
      case 'export':
        return UyavaLogArchiveEventKind.export;
      case 'clone':
        return UyavaLogArchiveEventKind.clone;
      case 'recovery':
        return UyavaLogArchiveEventKind.recovery;
      case _commandPanicSeal:
        return UyavaLogArchiveEventKind.panicSeal;
      default:
        return null;
    }
  }

  Future<void> dispose() async {
    await _archiveEventController.close();
  }
}
