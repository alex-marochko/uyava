import 'dart:io';

import 'package:uyava/uyava.dart';

/// Manages a temporary directory and file logger configuration for integration tests.
class IntegrationLoggingWorkspace {
  IntegrationLoggingWorkspace._({
    required this.rootDirectory,
    required this.config,
    this.exportInbox,
  });

  /// Root directory where archives, journals, and panic mirrors are written.
  final Directory rootDirectory;

  /// Optional directory that integration tests can use as an export target.
  final Directory? exportInbox;

  /// File logger configuration scoped to [rootDirectory].
  final UyavaFileLoggerConfig config;

  /// Resolved path to the panic mirror JSONL file.
  String get panicMirrorPath => _resolve(config.panicMirrorFileName);

  /// Resolved path to the streaming journal file.
  String get streamingJournalPath => _resolve(config.streamingJournalFileName);

  /// Directory created by the transport to store exported archives.
  Directory get exportsDirectory =>
      Directory('${rootDirectory.path}${Platform.pathSeparator}exports');

  /// Creates a temporary workspace and derives a logger config bound to it.
  static Future<IntegrationLoggingWorkspace> create({
    String prefix = 'uyava_integration_logging_',
    UyavaFileLoggerConfig Function(String directoryPath)? configBuilder,
    bool createExportInbox = true,
  }) async {
    final Directory root = await Directory.systemTemp.createTemp(prefix);
    final Directory? inbox = createExportInbox
        ? await Directory(
            '${root.path}${Platform.pathSeparator}export_inbox',
          ).create(recursive: true)
        : null;

    final UyavaFileLoggerConfig config = configBuilder != null
        ? configBuilder(root.path)
        : UyavaFileLoggerConfig(
            directoryPath: root.path,
            filePrefix: 'uyava_integration',
            retainLatestOnly: false,
            flushInterval: const Duration(milliseconds: 150),
            crashSafePersistence: true,
            streamingJournalEnabled: true,
            streamingJournalFlushInterval: const Duration(milliseconds: 300),
          );

    return IntegrationLoggingWorkspace._(
      rootDirectory: root,
      config: config,
      exportInbox: inbox,
    );
  }

  /// Wraps an existing [UyavaFileLoggerConfig] and directory for inspection.
  static IntegrationLoggingWorkspace fromConfig({
    required UyavaFileLoggerConfig config,
    Directory? exportInbox,
  }) {
    return IntegrationLoggingWorkspace._(
      rootDirectory: Directory(config.directoryPath),
      config: config,
      exportInbox: exportInbox,
    );
  }

  /// Deletes the workspace recursively.
  Future<void> dispose() async {
    try {
      if (await rootDirectory.exists()) {
        await rootDirectory.delete(recursive: true);
      }
    } on FileSystemException catch (error) {
      final int? code = error.osError?.errorCode;
      if (code != 2) {
        rethrow;
      }
    }
  }

  String _resolve(String fileName) =>
      '${rootDirectory.path}${Platform.pathSeparator}$fileName';
}
