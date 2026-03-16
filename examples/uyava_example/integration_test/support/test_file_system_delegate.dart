import 'dart:convert';
import 'dart:io';

import 'package:uyava/uyava.dart';

import 'temp_logging_workspace.dart';

/// Test-only helper that manages a temporary logging directory and exposes
/// inspection utilities for integration tests.
class TestFileSystemDelegate {
  TestFileSystemDelegate._(this.workspace);

  final IntegrationLoggingWorkspace workspace;

  Directory get rootDirectory => workspace.rootDirectory;

  Directory? get exportInbox => workspace.exportInbox;

  Directory get exportsDirectory => workspace.exportsDirectory;

  String get panicMirrorPath => workspace.panicMirrorPath;

  String get streamingJournalPath => workspace.streamingJournalPath;

  /// Creates a delegate backed by a temporary workspace and configuration.
  static Future<TestFileSystemDelegate> create({
    String prefix = 'uyava_integration_delegate_',
    UyavaFileLoggerConfig Function(String directoryPath)? configBuilder,
    bool createExportInbox = true,
  }) async {
    final IntegrationLoggingWorkspace workspace =
        await IntegrationLoggingWorkspace.create(
          prefix: prefix,
          configBuilder: configBuilder,
          createExportInbox: createExportInbox,
        );
    return TestFileSystemDelegate._(workspace);
  }

  /// Wraps an existing workspace (e.g., created by the app itself).
  static TestFileSystemDelegate fromWorkspace(
    IntegrationLoggingWorkspace workspace,
  ) {
    return TestFileSystemDelegate._(workspace);
  }

  /// Returns `.uyava` archives in the logging root directory.
  List<File> rootArchives() {
    return _listFiles(rootDirectory, (File entity) {
      return entity.path.endsWith('.uyava');
    });
  }

  /// Returns `.uyava` archives produced in the `exports/` directory.
  List<File> exportedArchives() {
    final Directory directory = exportsDirectory;
    if (!directory.existsSync()) {
      return <File>[];
    }
    return _listFiles(directory, (File entity) {
      return entity.path.endsWith('.uyava');
    });
  }

  /// Reads the panic mirror file when present.
  Future<List<String>> readPanicMirrorLines() async {
    final File file = File(panicMirrorPath);
    if (!await file.exists()) {
      return <String>[];
    }
    return file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();
  }

  /// Reads the live streaming journal file when present.
  Future<List<String>> readStreamingJournalLines() async {
    final File file = File(streamingJournalPath);
    if (!await file.exists()) {
      return <String>[];
    }
    return file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();
  }

  /// Deletes all exported archives created during the test run.
  Future<void> clearExports() async {
    final Directory directory = exportsDirectory;
    if (!await directory.exists()) {
      return;
    }
    await for (final FileSystemEntity entity in directory.list()) {
      await entity.delete(recursive: true);
    }
  }

  /// Disposes the underlying workspace and removes the temporary directory.
  Future<void> dispose() => workspace.dispose();

  List<File> _listFiles(Directory directory, bool Function(File) predicate) {
    if (!directory.existsSync()) {
      return <File>[];
    }
    final List<File> files = <File>[];
    for (final FileSystemEntity entity in directory.listSync()) {
      if (entity is! File) {
        continue;
      }
      if (predicate(entity)) {
        files.add(entity);
      }
    }
    files.sort((File a, File b) => a.path.compareTo(b.path));
    return files;
  }
}
