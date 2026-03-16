import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

@internal
abstract class FileLogIoAdapter {
  const FileLogIoAdapter();

  Future<FileLogIoHandle> openLogFile({
    required String directoryPath,
    required String fileName,
    required Map<String, dynamic> headerRecord,
    required DateTime openedAt,
  });

  Future<void> appendLine(FileLogIoHandle handle, String jsonLine);

  Future<void> flush(FileLogIoHandle handle);

  Future<FileLogIoArchive> close(FileLogIoHandle handle);
}

@internal
class FileLogIoHandle {
  FileLogIoHandle({
    required this.file,
    required this.fileName,
    required this.openedAt,
    required this.sink,
    required this.countingSink,
  });

  final File file;
  final String fileName;
  final DateTime openedAt;
  final IOSink sink;
  final CountingBytesSink countingSink;

  int get bytesWritten => countingSink.bytesWritten;
}

class GzipLogIoAdapter extends FileLogIoAdapter {
  GzipLogIoAdapter();

  @override
  Future<FileLogIoHandle> openLogFile({
    required String directoryPath,
    required String fileName,
    required Map<String, dynamic> headerRecord,
    required DateTime openedAt,
  }) async {
    final String path = joinPath(directoryPath, fileName);
    final File file = File(path);
    final IOSink sink = file.openWrite();
    final CountingBytesSink countingSink = CountingBytesSink(sink);

    final List<int> headerBytes = _encoder.convert(
      utf8.encode('${jsonEncode(headerRecord)}\n'),
    );
    countingSink.add(headerBytes);
    await sink.flush();

    return FileLogIoHandle(
      file: file,
      fileName: fileName,
      openedAt: openedAt,
      sink: sink,
      countingSink: countingSink,
    );
  }

  @override
  Future<void> appendLine(FileLogIoHandle handle, String jsonLine) async {
    final List<int> encoded = _encoder.convert(utf8.encode('$jsonLine\n'));
    handle.countingSink.add(encoded);
  }

  @override
  Future<void> flush(FileLogIoHandle handle) async {
    await handle.sink.flush();
  }

  @override
  Future<FileLogIoArchive> close(FileLogIoHandle handle) async {
    await handle.sink.close();
    final DateTime completedAt = DateTime.now();
    final int sizeBytes = handle.file.existsSync()
        ? handle.file.lengthSync()
        : 0;
    return FileLogIoArchive(
      file: handle.file,
      fileName: handle.fileName,
      openedAt: handle.openedAt,
      completedAt: completedAt,
      sizeBytes: sizeBytes,
    );
  }

  final ZLibEncoder _encoder = ZLibEncoder(
    gzip: true,
    level: ZLibOption.defaultLevel,
  );
}

class FileLogIoArchive {
  FileLogIoArchive({
    required this.file,
    required this.fileName,
    required this.openedAt,
    required this.completedAt,
    required this.sizeBytes,
  });

  final File file;
  final String fileName;
  final DateTime openedAt;
  final DateTime completedAt;
  final int sizeBytes;
}

class CountingBytesSink implements Sink<List<int>> {
  CountingBytesSink(this.delegate);

  final IOSink delegate;
  int bytesWritten = 0;

  @override
  void add(List<int> data) {
    bytesWritten += data.length;
    delegate.add(data);
  }

  @override
  void close() {
    delegate.close();
  }
}

String joinPath(String directory, String fileName) {
  if (directory.endsWith(Platform.pathSeparator)) {
    return '$directory$fileName';
  }
  return '$directory${Platform.pathSeparator}$fileName';
}
