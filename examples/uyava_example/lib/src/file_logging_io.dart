import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uyava/uyava.dart';

_FileLoggingLifecycle? _fileLoggingLifecycle;
UyavaGlobalErrorHandle? _globalErrorHandle;
UyavaFileTransport? _configuredTransport;
UyavaFileLoggerConfig? _loggerConfig;

Future<UyavaFileTransport?> configureFileLogging() async {
  if (kIsWeb) {
    return null;
  }

  try {
    final Directory directory = await Directory.systemTemp.createTemp(
      'uyava_example_logs',
    );
    debugPrint(
      'Uyava file logging enabled. Archives will be written to ${directory.path}',
    );
    final UyavaFileLoggerConfig config = UyavaFileLoggerConfig(
      directoryPath: directory.path,
      filePrefix: 'uyava_example',
      retainLatestOnly: true,
      flushInterval: const Duration(milliseconds: 200),
      crashSafePersistence: true,
      streamingJournalEnabled: true,
      streamingJournalFlushInterval: const Duration(milliseconds: 250),
    );
    final String panicMirrorPath =
        '${directory.path}${Platform.pathSeparator}panic-tail.jsonl';
    debugPrint(
      'Crash-safe persistence enabled. Panic mirror will be written to '
      '$panicMirrorPath',
    );
    final String streamingJournalPath =
        '${directory.path}${Platform.pathSeparator}panic-tail-active.jsonl';
    debugPrint(
      'Streaming journal enabled. Active JSONL mirror lives at '
      '$streamingJournalPath',
    );
    _loggerConfig = config;
    final UyavaFileTransport transport = await Uyava.enableFileLogging(
      config: config,
    );
    _configuredTransport = transport;
    return transport;
  } on FileSystemException catch (error, stackTrace) {
    debugPrint('Uyava file logging disabled: ${error.message}\n$stackTrace');
    return null;
  }
}

void initializeFileLoggingLifecycle(UyavaFileTransport transport) {
  _configuredTransport ??= transport;
  _fileLoggingLifecycle ??= _FileLoggingLifecycle(transport);
  final UyavaGlobalErrorHandle? pendingHandle = _globalErrorHandle;
  if (pendingHandle != null) {
    _fileLoggingLifecycle!.attachGlobalErrorHandle(pendingHandle);
  }
}

UyavaFileTransport? currentFileTransport() => _configuredTransport;

UyavaSeverity currentMinLogLevel() =>
    _loggerConfig?.minLevel ?? UyavaSeverity.trace;

Future<bool> updateFileLoggingMinLevel(UyavaSeverity minLevel) async {
  final UyavaFileTransport? existingTransport = _configuredTransport;
  final UyavaFileLoggerConfig? existingConfig = _loggerConfig;
  if (existingTransport == null || existingConfig == null) {
    debugPrint(
      'Uyava file logging: minLevel update skipped because transport is not configured.',
    );
    return false;
  }
  if (existingConfig.minLevel == minLevel) {
    return true;
  }

  final UyavaGlobalErrorOptions? previousOptions = _globalErrorHandle?.options;

  try {
    if (_fileLoggingLifecycle != null) {
      await _fileLoggingLifecycle!.shutdown();
    } else {
      await existingTransport.flush();
      await existingTransport.dispose();
      Uyava.unregisterTransport(existingTransport.channel);
      _configuredTransport = null;
    }
  } catch (error, stackTrace) {
    debugPrint(
      'Uyava file logging: failed to stop transport before minLevel update: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  final UyavaFileLoggerConfig nextConfig = existingConfig.copyWith(
    minLevel: minLevel,
  );

  try {
    final UyavaFileTransport nextTransport = await Uyava.enableFileLogging(
      config: nextConfig,
    );
    _configuredTransport = nextTransport;
    _loggerConfig = nextConfig;
    initializeFileLoggingLifecycle(nextTransport);
    if (previousOptions != null) {
      final UyavaGlobalErrorHandle handle =
          UyavaBootstrap.installGlobalErrorHandlers(
            transport: nextTransport,
            options: previousOptions,
          );
      registerGlobalErrorHandle(handle);
    }
    return true;
  } catch (error, stackTrace) {
    debugPrint(
      'Uyava file logging: failed to apply minLevel ${minLevel.name}: $error',
    );
    debugPrintStack(stackTrace: stackTrace);

    try {
      final UyavaFileTransport fallbackTransport =
          await Uyava.enableFileLogging(config: existingConfig);
      _configuredTransport = fallbackTransport;
      _loggerConfig = existingConfig;
      initializeFileLoggingLifecycle(fallbackTransport);
      if (previousOptions != null) {
        final UyavaGlobalErrorHandle handle =
            UyavaBootstrap.installGlobalErrorHandlers(
              transport: fallbackTransport,
              options: previousOptions,
            );
        registerGlobalErrorHandle(handle);
      }
    } catch (fallbackError, fallbackStackTrace) {
      debugPrint(
        'Uyava file logging: fallback transport failed to restore original configuration: $fallbackError',
      );
      debugPrintStack(stackTrace: fallbackStackTrace);
    }

    return false;
  }
}

Future<UyavaLogArchive?> exportCurrentLogArchive({
  String? targetDirectoryPath,
}) async {
  final UyavaFileTransport? transport = _configuredTransport;
  if (transport == null) {
    debugPrint(
      'Uyava file logging: export skipped because no transport is configured.',
    );
    return null;
  }

  try {
    final UyavaLogArchive archive = await Uyava.exportCurrentArchive(
      targetDirectoryPath: targetDirectoryPath,
    );
    debugPrint(
      'Uyava file logging: exported ${archive.fileName} '
      '(${archive.sizeBytes} bytes) to ${archive.path}',
    );
    return archive;
  } catch (error, stackTrace) {
    debugPrint('Uyava file logging: failed to export archive: $error');
    debugPrintStack(stackTrace: stackTrace);
    return null;
  }
}

Future<UyavaLogArchive?> cloneActiveLogArchive({
  String? targetDirectoryPath,
}) async {
  final UyavaFileTransport? transport = _configuredTransport;
  if (transport == null) {
    debugPrint(
      'Uyava file logging: clone skipped because no transport is configured.',
    );
    return null;
  }

  try {
    final UyavaLogArchive archive = await Uyava.cloneActiveArchive(
      targetDirectoryPath: targetDirectoryPath,
    );
    debugPrint(
      'Uyava file logging: cloned ${archive.fileName} '
      '(${archive.sizeBytes} bytes) to ${archive.path}',
    );
    return archive;
  } catch (error, stackTrace) {
    debugPrint('Uyava file logging: failed to clone archive: $error');
    debugPrintStack(stackTrace: stackTrace);
    return null;
  }
}

Stream<UyavaLogArchiveEvent>? archiveEvents() => Uyava.archiveEvents;

Future<void> updateGlobalErrorOptions(UyavaGlobalErrorOptions options) async {
  final UyavaFileTransport? transport = _configuredTransport;
  if (transport == null) {
    debugPrint(
      'Uyava file logging: cannot update global error options without a transport.',
    );
    return;
  }
  final UyavaGlobalErrorHandle newHandle =
      UyavaBootstrap.installGlobalErrorHandlers(
        transport: transport,
        options: options,
      );
  _fileLoggingLifecycle?.attachGlobalErrorHandle(newHandle);
  _globalErrorHandle?.dispose();
  _globalErrorHandle = newHandle;
}

void registerGlobalErrorHandle(UyavaGlobalErrorHandle handle) {
  _globalErrorHandle = handle;
  _fileLoggingLifecycle?.attachGlobalErrorHandle(handle);
}

Future<void> logSyntheticRuntimeError({
  required String source,
  required Object error,
  StackTrace? stackTrace,
  Map<String, Object?>? context,
}) async {
  final UyavaFileTransport? transport = _configuredTransport;
  if (transport == null) {
    debugPrint(
      'Uyava file logging: no transport configured, synthetic runtime error skipped.',
    );
    return;
  }
  try {
    await transport.logRuntimeError(
      source: source,
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      isFatal: false,
      message: error.toString(),
      context: context,
    );
  } catch (loggingError, loggingStackTrace) {
    debugPrint(
      'Uyava file logging: failed to persist synthetic runtime error: '
      '$loggingError',
    );
    debugPrintStack(stackTrace: loggingStackTrace);
  }
}

Future<void> shutdownFileLogging() async {
  if (_fileLoggingLifecycle != null) {
    await _fileLoggingLifecycle!.shutdown();
  } else if (_configuredTransport != null) {
    // Fallback: ensure transport is disposed if lifecycle never attached.
    try {
      await _configuredTransport!.flush();
      await _configuredTransport!.dispose();
      Uyava.unregisterTransport(_configuredTransport!.channel);
    } finally {
      _configuredTransport = null;
      _globalErrorHandle?.dispose();
      _globalErrorHandle = null;
    }
  }
}

class _FileLoggingLifecycle with WidgetsBindingObserver {
  _FileLoggingLifecycle(this.transport) {
    WidgetsBinding.instance.addObserver(this);
    final StreamSubscription<ProcessSignal>? sigintSubscription = _maybeWatch(
      ProcessSignal.sigint,
    );
    final StreamSubscription<ProcessSignal>? sigtermSubscription = _maybeWatch(
      ProcessSignal.sigterm,
    );
    _signalSubscriptions = <StreamSubscription<ProcessSignal>>[
      if (sigintSubscription != null) sigintSubscription,
      if (sigtermSubscription != null) sigtermSubscription,
    ];
    _appLifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await _shutdown();
        return ui.AppExitResponse.exit;
      },
    );
  }

  final UyavaFileTransport transport;
  final Completer<void> _shutdownCompleter = Completer<void>();
  late final List<StreamSubscription<ProcessSignal>> _signalSubscriptions;
  bool _didShutdown = false;
  late final AppLifecycleListener _appLifecycleListener;
  UyavaGlobalErrorHandle? _attachedHandle;

  void attachGlobalErrorHandle(UyavaGlobalErrorHandle handle) {
    _attachedHandle = handle;
  }

  StreamSubscription<ProcessSignal>? _maybeWatch(ProcessSignal signal) {
    try {
      return signal.watch().listen(_handleSignal);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appLifecycleListener.dispose();
    for (final subscription in _signalSubscriptions) {
      subscription.cancel();
    }
  }

  void _handleSignal(ProcessSignal signal) {
    _shutdown().whenComplete(() {
      exit(0);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(_shutdown());
    }
  }

  Future<void> shutdown() => _shutdown();

  Future<void> _shutdown() {
    if (_didShutdown) {
      return _shutdownCompleter.future;
    }
    _didShutdown = true;
    debugPrint('Uyava file logging: flushing transport at ${transport.path}');
    () async {
      try {
        await transport.flush();
        await transport.dispose();
        Uyava.unregisterTransport(transport.channel);
        final Directory directory = Directory(transport.path);
        if (await directory.exists()) {
          List<FileSystemEntity> files = <FileSystemEntity>[];
          try {
            files = directory.listSync();
          } on PathNotFoundException catch (_) {
            // Directory was removed concurrently (e.g., macOS sandbox cleanup).
            files = <FileSystemEntity>[];
          }
          for (final FileSystemEntity entity in files) {
            if (entity is File && entity.path.endsWith('.uyava')) {
              int sizeBytes = 0;
              try {
                sizeBytes = entity.lengthSync();
              } on PathNotFoundException catch (_) {
                sizeBytes = 0;
              }
              debugPrint(
                'Uyava file logging: ${entity.path} size=$sizeBytes bytes',
              );
            }
          }
        }
        debugPrint('Uyava file logging: transport closed.');
      } finally {
        _attachedHandle?.dispose();
        _attachedHandle = null;
        _globalErrorHandle = null;
        _configuredTransport = null;
        dispose();
        if (!_shutdownCompleter.isCompleted) {
          _shutdownCompleter.complete();
        }
        _fileLoggingLifecycle = null;
      }
    }();
    return _shutdownCompleter.future;
  }
}
