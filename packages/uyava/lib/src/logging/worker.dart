part of '../file_logger.dart';

class _FileLoggerWorkerBootstrap {
  const _FileLoggerWorkerBootstrap({
    required this.responsePort,
    required this.directoryPath,
    required this.sessionId,
    required this.filePrefix,
    required this.maxFileSizeBytes,
    required this.maxDurationMicros,
    required this.maxFileCount,
    this.maxExportCount,
    this.maxExportTotalBytes,
    required this.retainLatestOnly,
    required this.configSummary,
    required this.hostMetadata,
    required this.crashSafePersistence,
    required this.panicMirrorFileName,
    required this.streamingJournalEnabled,
    required this.streamingJournalFileName,
    required this.streamingJournalFlushIntervalMicros,
    required this.dropFlushResponses,
  });

  final SendPort responsePort;
  final String directoryPath;
  final String sessionId;
  final String filePrefix;
  final int maxFileSizeBytes;
  final int maxDurationMicros;
  final int maxFileCount;
  final int? maxExportCount;
  final int? maxExportTotalBytes;
  final bool retainLatestOnly;
  final Map<String, Object?> configSummary;
  final Map<String, Object?> hostMetadata;
  final bool crashSafePersistence;
  final String panicMirrorFileName;
  final bool streamingJournalEnabled;
  final String streamingJournalFileName;
  final int streamingJournalFlushIntervalMicros;
  final bool dropFlushResponses;
}

void _fileLoggerWorker(_FileLoggerWorkerBootstrap bootstrap) async {
  final ReceivePort commandPort = ReceivePort();
  final _FileLoggerWorkerState state = _FileLoggerWorkerState(
    bootstrap: bootstrap,
  );

  try {
    await state.initialize();
  } catch (error, stack) {
    bootstrap.responsePort.send(<String, Object?>{
      'type': _messageFatal,
      'error': error.toString(),
      'stack': stack.toString(),
    });
    commandPort.close();
    return;
  }

  bootstrap.responsePort.send(<String, Object?>{
    'type': _messageReady,
    'sendPort': commandPort.sendPort,
  });

  await for (final dynamic raw in commandPort) {
    if (raw is! Map<String, Object?>) {
      continue;
    }
    final String? type = raw['type'] as String?;
    final int? requestId = raw['requestId'] as int?;
    try {
      switch (type) {
        case _commandEvent:
          await state.writeRecord(
            raw['record'] as Map<String, dynamic>,
            raw['timestampMicros'] as int,
          );
          break;
        case _commandFlush:
          await state.flush();
          if (requestId != null && !bootstrap.dropFlushResponses) {
            bootstrap.responsePort.send(<String, Object?>{
              'type': _messageResponse,
              'requestId': requestId,
              'success': true,
            });
          }
          break;
        case _commandRotateExport:
          final Map<String, Object?> archive = await state.rotateAndExport(
            targetDirectoryPath: raw['targetDirectoryPath'] as String?,
          );
          bootstrap.responsePort.send(<String, Object?>{
            'type': _messageResponse,
            'requestId': requestId,
            'success': true,
            'archive': archive,
          });
          break;
        case _commandCloneActive:
          final Map<String, Object?> archive = await state.cloneActiveArchive(
            targetDirectoryPath: raw['targetDirectoryPath'] as String?,
          );
          bootstrap.responsePort.send(<String, Object?>{
            'type': _messageResponse,
            'requestId': requestId,
            'success': true,
            'archive': archive,
          });
          break;
        case _commandLatestArchive:
          final Map<String, Object?>? archive = state.latestArchive(
            includeExports: raw['includeExports'] != false,
          );
          bootstrap.responsePort.send(<String, Object?>{
            'type': _messageResponse,
            'requestId': requestId,
            'success': true,
            'archive': archive,
          });
          break;
        case _commandPanicMirror:
          await state.appendPanicRecord(
            Map<String, dynamic>.from(raw['record'] as Map),
          );
          if (requestId != null) {
            bootstrap.responsePort.send(<String, Object?>{
              'type': _messageResponse,
              'requestId': requestId,
              'success': true,
            });
          }
          break;
        case _commandPanicSeal:
          final Map<String, Object?>? archive = await state.sealActiveFile(
            reopen: raw['reopen'] != false,
          );
          bootstrap.responsePort.send(<String, Object?>{
            'type': _messageResponse,
            'requestId': requestId,
            'success': true,
            'archive': archive,
          });
          break;
        case _commandDispose:
          await state.dispose();
          bootstrap.responsePort.send(<String, Object?>{
            'type': _messageResponse,
            'requestId': requestId,
            'success': true,
          });
          commandPort.close();
          return;
      }
    } catch (error, stack) {
      if (requestId != null) {
        bootstrap.responsePort.send(<String, Object?>{
          'type': _messageResponse,
          'requestId': requestId,
          'success': false,
          'error': error.toString(),
          'stack': stack.toString(),
        });
      } else {
        bootstrap.responsePort.send(<String, Object?>{
          'type': _messageFatal,
          'error': error.toString(),
          'stack': stack.toString(),
        });
      }
    }
  }
}
