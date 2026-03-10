part of '../console_logger.dart';

/// Internal worker that buffers, formats, and writes console records.
class ConsoleLoggerWorker {
  ConsoleLoggerWorker({
    required this.config,
    required this.sink,
    required bool colorEnabled,
  }) : _colorEnabled = colorEnabled;

  final UyavaConsoleLoggerConfig config;
  final ConsoleSink sink;
  final bool _colorEnabled;
  final ListQueue<UyavaConsoleLogRecord> _buffer =
      ListQueue<UyavaConsoleLogRecord>();
  StreamSubscription<dynamic>? _diagnosticsSubscription;

  Timer? _flushTimer;
  bool _flushScheduled = false;
  bool _disposed = false;
  int _droppedRecordCount = 0;

  int get droppedRecordCount => _droppedRecordCount;

  void log(UyavaConsoleLogRecord record) {
    if (_disposed) {
      return;
    }
    if (!_shouldLog(record)) {
      return;
    }
    if (config.bufferCapacity == 0) {
      _writeLine(record);
      return;
    }
    _enqueue(record);
  }

  StreamSubscription<dynamic>? attachDiagnosticsStream(
    Stream<dynamic> diagnostics,
  ) {
    if (_disposed) {
      return null;
    }
    unawaited(_diagnosticsSubscription?.cancel());
    final StreamSubscription<dynamic> subscription = diagnostics.listen(
      _handleDiagnosticRecord,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'UyavaConsoleLogger diagnostics stream error.',
          name: 'Uyava',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _diagnosticsSubscription = subscription;
    return subscription;
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _diagnosticsSubscription?.cancel();
    _diagnosticsSubscription = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _flushScheduled = false;
    await _flushBuffer();
  }

  bool _shouldLog(UyavaConsoleLogRecord record) {
    if (record.severity.index < config.minLevel.index) {
      return false;
    }

    if (config.includeTypes.isNotEmpty &&
        !config.includeTypes.contains(record.type)) {
      return false;
    }

    if (config.excludeTypes.contains(record.type)) {
      return false;
    }

    return true;
  }

  void _enqueue(UyavaConsoleLogRecord record) {
    if (config.bufferCapacity <= _buffer.length) {
      _buffer.removeFirst();
      _droppedRecordCount += 1;
    }
    _buffer.add(record);
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_flushScheduled || _disposed) {
      return;
    }

    if (config.flushInterval <= Duration.zero) {
      unawaited(_flushBuffer());
      return;
    }

    _flushScheduled = true;
    _flushTimer = Timer(config.flushInterval, () {
      _flushScheduled = false;
      _flushTimer = null;
      unawaited(_flushBuffer());
    });
  }

  Future<void> _flushBuffer() async {
    if (_buffer.isEmpty) {
      return;
    }

    final List<UyavaConsoleLogRecord> drained =
        List<UyavaConsoleLogRecord>.from(_buffer);
    _buffer.clear();
    try {
      for (final UyavaConsoleLogRecord record in drained) {
        _writeLine(record);
      }
      await sink.flush();
    } catch (error, stackTrace) {
      developer.log(
        'UyavaConsoleLogger failed to write a record.',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _writeLine(UyavaConsoleLogRecord record) {
    final String line = UyavaConsoleFormatter.format(
      record,
      colorEnabled: _colorEnabled,
    );
    sink.write(line);
  }

  void _handleDiagnosticRecord(dynamic record) {
    final UyavaConsoleLogRecord? consoleRecord = _consoleRecordFromDiagnostic(
      record,
    );
    if (consoleRecord == null) {
      return;
    }
    log(consoleRecord);
  }

  UyavaConsoleLogRecord? _consoleRecordFromDiagnostic(dynamic record) {
    try {
      UyavaDiagnosticLevel? level;
      String? code;
      String? codeEnumLabel;
      List<String>? subjects;
      Map<String, Object?>? context;
      DateTime? timestamp;
      Object? source;

      if (record is Map) {
        final Map<dynamic, dynamic> mapRecord = record;
        final dynamic levelValue = mapRecord['level'];
        if (levelValue is UyavaDiagnosticLevel) {
          level = levelValue;
        }
        final dynamic codeValue = mapRecord['code'];
        if (codeValue is String) {
          code = codeValue;
        }
        final dynamic enumValue = mapRecord['codeEnum'];
        if (enumValue != null) {
          codeEnumLabel = enumValue is Enum
              ? enumValue.name
              : enumValue.toString();
        }
        final dynamic subjectsValue = mapRecord['subjects'];
        if (subjectsValue is Iterable) {
          subjects = subjectsValue
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toList(growable: false);
        }
        final dynamic contextValue = mapRecord['context'];
        if (contextValue is Map) {
          context = contextValue.map(
            (dynamic key, dynamic value) =>
                MapEntry(key.toString(), value as Object?),
          );
        }
        final dynamic timestampValue = mapRecord['timestamp'];
        if (timestampValue is DateTime) {
          timestamp = timestampValue;
        }
        source = mapRecord['source'];
      } else {
        final dynamic dyn = record;
        final dynamic levelValue = dyn.level;
        if (levelValue is UyavaDiagnosticLevel) {
          level = levelValue;
        }
        final dynamic codeValue = dyn.code;
        if (codeValue is String) {
          code = codeValue;
        }
        final dynamic enumValue = dyn.codeEnum;
        if (enumValue != null) {
          codeEnumLabel = enumValue is Enum
              ? enumValue.name
              : enumValue.toString();
        }
        final dynamic subjectsValue = dyn.subjects;
        if (subjectsValue is Iterable) {
          subjects = subjectsValue
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toList(growable: false);
        }
        final dynamic contextValue = dyn.context;
        if (contextValue is Map) {
          context = contextValue.map(
            (dynamic key, dynamic value) =>
                MapEntry(key.toString(), value as Object?),
          );
        }
        final dynamic timestampValue = dyn.timestamp;
        if (timestampValue is DateTime) {
          timestamp = timestampValue;
        }
        source = dyn.source;
      }

      if (level == null || code == null) {
        return null;
      }

      final Map<String, Object?> resolvedContext = <String, Object?>{};
      if (source != null) {
        resolvedContext['source'] = _enumLabel(source);
      }
      if (context != null && context.isNotEmpty) {
        resolvedContext.addAll(context);
      }

      return UyavaConsoleLogRecord(
        timestamp: (timestamp ?? DateTime.now()).toUtc(),
        severity: _diagnosticSeverity(level),
        type: UyavaEventTypes.graphDiagnostics,
        code: codeEnumLabel?.isNotEmpty == true ? codeEnumLabel : code,
        subjects: subjects ?? const <String>[],
        context: resolvedContext,
      );
    } catch (error, stackTrace) {
      developer.log(
        'UyavaConsoleLogger failed to process diagnostic record.',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static UyavaSeverity _diagnosticSeverity(UyavaDiagnosticLevel level) {
    switch (level) {
      case UyavaDiagnosticLevel.info:
        return UyavaSeverity.info;
      case UyavaDiagnosticLevel.warning:
        return UyavaSeverity.warn;
      case UyavaDiagnosticLevel.error:
        return UyavaSeverity.error;
    }
  }

  static String _enumLabel(Object value) {
    if (value is Enum) {
      return value.name;
    }
    final String raw = value.toString();
    final int dotIndex = raw.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < raw.length - 1) {
      return raw.substring(dotIndex + 1);
    }
    return raw;
  }
}
