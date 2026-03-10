import 'package:uyava/uyava.dart';

import 'file_logging_stub.dart'
    if (dart.library.io) 'file_logging_io.dart'
    as impl;

Future<UyavaFileTransport?> configureFileLogging() =>
    impl.configureFileLogging();

void initializeFileLoggingLifecycle(UyavaFileTransport transport) =>
    impl.initializeFileLoggingLifecycle(transport);

UyavaFileTransport? currentFileTransport() => impl.currentFileTransport();

UyavaSeverity currentMinLogLevel() => impl.currentMinLogLevel();

Future<UyavaLogArchive?> exportCurrentLogArchive({
  String? targetDirectoryPath,
}) => impl.exportCurrentLogArchive(targetDirectoryPath: targetDirectoryPath);

Future<UyavaLogArchive?> cloneActiveLogArchive({String? targetDirectoryPath}) =>
    impl.cloneActiveLogArchive(targetDirectoryPath: targetDirectoryPath);

Stream<UyavaLogArchiveEvent>? archiveEvents() => impl.archiveEvents();

Future<void> updateGlobalErrorOptions(UyavaGlobalErrorOptions options) =>
    impl.updateGlobalErrorOptions(options);

Future<bool> updateFileLoggingMinLevel(UyavaSeverity minLevel) =>
    impl.updateFileLoggingMinLevel(minLevel);

Future<void> logSyntheticRuntimeError({
  required String source,
  required Object error,
  StackTrace? stackTrace,
  Map<String, Object?>? context,
}) => impl.logSyntheticRuntimeError(
  source: source,
  error: error,
  stackTrace: stackTrace,
  context: context,
);

void registerGlobalErrorHandle(UyavaGlobalErrorHandle handle) =>
    impl.registerGlobalErrorHandle(handle);

Future<void> shutdownFileLogging() => impl.shutdownFileLogging();
