import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'logging/console_config.dart';

export 'logging/console_config.dart';

part 'logging/console_sink.dart';
part 'logging/console_formatter.dart';
part 'logging/console_worker.dart';

/// Sink-backed console logger with lightweight buffering.
class UyavaConsoleLogger {
  UyavaConsoleLogger({required this.config, ConsoleSink? sink})
    : _worker = ConsoleLoggerWorker(
        config: config,
        sink: sink ?? IoConsoleSink(config.sink ?? stdout),
        colorEnabled: _resolveColorSupport(config.colorMode, config.sink),
      );

  final UyavaConsoleLoggerConfig config;
  final ConsoleLoggerWorker _worker;

  /// Number of records dropped due to buffer overflow.
  int get droppedRecordCount => _worker.droppedRecordCount;

  /// Adds a record to the console stream when it passes configured filters.
  void log(UyavaConsoleLogRecord record) => _worker.log(record);

  /// Subscribes to a diagnostics stream (e.g. [GraphDiagnosticsBuffer] output).
  ///
  /// The logger keeps the most recent subscription active; previous ones are
  /// cancelled. Use the returned [StreamSubscription] for additional lifecycle
  /// control when needed.
  StreamSubscription<dynamic>? attachDiagnosticsStream(
    Stream<dynamic> diagnostics,
  ) => _worker.attachDiagnosticsStream(diagnostics);

  /// Flushes any pending records and releases internal resources.
  Future<void> dispose() => _worker.dispose();
}

bool _resolveColorSupport(UyavaConsoleColorMode mode, IOSink? targetSink) {
  switch (mode) {
    case UyavaConsoleColorMode.always:
      return true;
    case UyavaConsoleColorMode.never:
      return false;
    case UyavaConsoleColorMode.auto:
      final IOSink sink = targetSink ?? stdout;
      if (identical(sink, stdout)) {
        return stdout.supportsAnsiEscapes;
      }
      if (identical(sink, stderr)) {
        return stderr.supportsAnsiEscapes;
      }
      return false;
  }
}
