import 'package:uyava/uyava.dart';

Future<UyavaFileTransport?> configureFileLogging() async => null;

void initializeFileLoggingLifecycle(UyavaFileTransport transport) {}

UyavaFileTransport? currentFileTransport() => null;

UyavaSeverity currentMinLogLevel() => UyavaSeverity.trace;

Future<UyavaLogArchive?> exportCurrentLogArchive({
  String? targetDirectoryPath,
}) async => null;

Future<UyavaLogArchive?> cloneActiveLogArchive({
  String? targetDirectoryPath,
}) async => null;

Stream<UyavaLogArchiveEvent>? archiveEvents() => null;

Future<void> updateGlobalErrorOptions(UyavaGlobalErrorOptions options) async {}

Future<bool> updateFileLoggingMinLevel(UyavaSeverity minLevel) async => false;

Future<void> logSyntheticRuntimeError({
  required String source,
  required Object error,
  StackTrace? stackTrace,
  Map<String, Object?>? context,
}) async {}

void registerGlobalErrorHandle(UyavaGlobalErrorHandle handle) {}

Future<void> shutdownFileLogging() async {}
