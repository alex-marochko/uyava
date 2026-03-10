part of '../file_logger.dart';

/// Contract for any sink capable of persisting SDK events.
abstract class LogSink {
  void send(UyavaTransportEvent event);
  Future<void> flush();
  Future<void> dispose();
}

/// Handles archive lifecycle actions such as rotation, cloning, and export.
abstract class ArchiveRotator {
  Future<UyavaLogArchive> exportArchive({String? targetDirectoryPath});
  Future<UyavaLogArchive> cloneActiveArchive();
  Future<UyavaLogArchive?> latestArchiveSnapshot({bool includeExports = true});
}

/// Governs real-time throttling decisions before events reach disk.
abstract class RealtimeThrottler {
  bool shouldAllow(UyavaTransportEvent event);
}

const String _commandEvent = 'event';
const String _commandFlush = 'flush';
const String _commandRotateExport = 'rotate_export';
const String _commandCloneActive = 'clone_active';
const String _commandLatestArchive = 'latest_archive';
const String _commandPanicMirror = 'panic_mirror';
const String _commandPanicSeal = 'panic_seal';
const String _commandDispose = 'dispose';

const String _messageReady = 'ready';
const String _messageResponse = 'response';
const String _messageArchiveEvent = 'archive_event';
const String _messageFatal = 'fatal';
