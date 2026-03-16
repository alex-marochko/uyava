import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'file_logger.dart';
import 'diagnostic_publisher.dart';

/// Controls which global error hooks are installed and how they behave.
class UyavaGlobalErrorOptions {
  const UyavaGlobalErrorOptions({
    this.enableFlutterError = true,
    this.enablePlatformDispatcher = true,
    this.enableZonedErrors = true,
    this.delegateOriginalHandlers = true,
    this.propagateToZone = true,
    this.enableIsolateErrors = false,
    this.captureCurrentIsolateErrors = true,
    this.emitNonFatalDiagnostics = true,
    this.autoGuardZone = false,
    this.flushTimeout = const Duration(milliseconds: 500),
  });

  /// Whether to install a wrapper around [FlutterError.onError].
  final bool enableFlutterError;

  /// Whether to install a wrapper around [ui.PlatformDispatcher.onError].
  final bool enablePlatformDispatcher;

  /// Whether [UyavaBootstrap.runZoned] wires a guarded zone to capture async
  /// errors for the registered transport.
  final bool enableZonedErrors;

  /// If true, previously registered handlers are invoked after Uyava records
  /// the error so that existing logging/reporting continues to function.
  final bool delegateOriginalHandlers;

  /// If true, the manager asks the parent zone to treat the error as
  /// unhandled after recording it. Guards call
  /// [Zone.handleUncaughtError] in the parent zone to preserve default crash
  /// semantics.
  final bool propagateToZone;

  /// Whether to listen for unhandled errors delivered through isolate error
  /// ports (e.g., spawned workers) and forward them to the configured
  /// transport.
  ///
  /// When enabled, Uyava exposes [UyavaBootstrap.isolateErrorPort] and
  /// [UyavaBootstrap.attachIsolateErrorListener] so callers can opt into
  /// forwarding background isolate errors without binding the capture path to
  /// the Flutter error hooks.
  final bool enableIsolateErrors;

  /// Whether to attach the isolate error listener to the current isolate. This
  /// helps catch uncaught async errors when applications skip
  /// [UyavaBootstrap.runZoned], but can be disabled to avoid duplicate logging
  /// if callers already forward main isolate errors through other hooks.
  final bool captureCurrentIsolateErrors;

  /// Whether to emit diagnostics for errors treated as non-fatal. Non-fatal
  /// captures still serialize the runtimeError payload; this flag only controls
  /// the diagnostic side channel.
  final bool emitNonFatalDiagnostics;

  /// Whether to automatically create a guarded zone when [runZoned] is not
  /// used. When enabled, installs a lightweight [runZonedGuarded] wrapper
  /// around global hooks to capture async uncaught errors and logs a warning
  /// that the app skipped [UyavaBootstrap.runZoned].
  final bool autoGuardZone;

  /// Maximum amount of time the transport should spend flushing during panic
  /// handling. Enforced in later implementation stages when transports are
  /// wired to the handlers.
  final Duration flushTimeout;

  UyavaGlobalErrorOptions copyWith({
    bool? enableFlutterError,
    bool? enablePlatformDispatcher,
    bool? enableZonedErrors,
    bool? delegateOriginalHandlers,
    bool? propagateToZone,
    bool? enableIsolateErrors,
    bool? captureCurrentIsolateErrors,
    bool? emitNonFatalDiagnostics,
    bool? autoGuardZone,
    Duration? flushTimeout,
  }) {
    return UyavaGlobalErrorOptions(
      enableFlutterError: enableFlutterError ?? this.enableFlutterError,
      enablePlatformDispatcher:
          enablePlatformDispatcher ?? this.enablePlatformDispatcher,
      enableZonedErrors: enableZonedErrors ?? this.enableZonedErrors,
      delegateOriginalHandlers:
          delegateOriginalHandlers ?? this.delegateOriginalHandlers,
      propagateToZone: propagateToZone ?? this.propagateToZone,
      enableIsolateErrors: enableIsolateErrors ?? this.enableIsolateErrors,
      captureCurrentIsolateErrors:
          captureCurrentIsolateErrors ?? this.captureCurrentIsolateErrors,
      emitNonFatalDiagnostics:
          emitNonFatalDiagnostics ?? this.emitNonFatalDiagnostics,
      autoGuardZone: autoGuardZone ?? this.autoGuardZone,
      flushTimeout: flushTimeout ?? this.flushTimeout,
    );
  }
}

const Object _skipFatalPropagationZoneKey = Object();

typedef UyavaFatalDispatcher =
    void Function(Object error, StackTrace stackTrace);

UyavaFatalDispatcher _fatalDispatcher = _defaultFatalDispatcher;

void _defaultFatalDispatcher(Object error, StackTrace stackTrace) {
  Zone.root.scheduleMicrotask(() async {
    try {
      final ServicesBinding binding = ServicesBinding.instance;
      try {
        final ui.AppExitResponse response = await binding.exitApplication(
          ui.AppExitType.cancelable,
        );
        if (response != ui.AppExitResponse.exit) {
          await binding.exitApplication(ui.AppExitType.required);
        }
      } catch (_) {
        // Fallback to required exit if cancelable flow is unsupported.
        try {
          await binding.exitApplication(ui.AppExitType.required);
        } catch (_) {}
      }
    } catch (_) {
      // Binding not available; continue to crash the isolate.
    }
    Error.throwWithStackTrace(error, stackTrace);
  });
}

const String _panicDiagnosticCode = 'logging.panic_tail_captured';
const String _panicDiagnosticSummary =
    'Global error captured, panic tail recorded';

class _PanicDiagnosticSnapshot {
  const _PanicDiagnosticSnapshot({
    this.payloadBytes,
    this.panicMirrorPath,
    this.panicMirrorBytes,
    this.archive,
    this.loggingError,
  });

  final int? payloadBytes;
  final String? panicMirrorPath;
  final int? panicMirrorBytes;
  final UyavaLogArchive? archive;
  final Object? loggingError;

  bool get hasTail => payloadBytes != null;

  _PanicDiagnosticSnapshot copyWith({
    int? payloadBytes,
    String? panicMirrorPath,
    int? panicMirrorBytes,
    UyavaLogArchive? archive,
    Object? loggingError,
  }) {
    return _PanicDiagnosticSnapshot(
      payloadBytes: payloadBytes ?? this.payloadBytes,
      panicMirrorPath: panicMirrorPath ?? this.panicMirrorPath,
      panicMirrorBytes: panicMirrorBytes ?? this.panicMirrorBytes,
      archive: archive ?? this.archive,
      loggingError: loggingError ?? this.loggingError,
    );
  }
}

/// Handle returned by [UyavaBootstrap.installGlobalErrorHandlers].
abstract class UyavaGlobalErrorHandle {
  /// Disables the installed handlers and restores the previous callbacks when
  /// no other active handles remain.
  void dispose();

  /// Whether [dispose] was already called on this handle.
  bool get isDisposed;

  /// Transport the handler is bound to.
  UyavaFileTransport get transport;

  /// Options that were active when this handle was created.
  UyavaGlobalErrorOptions get options;
}

/// Installs global error handlers that forward uncaught failures to Uyava's
/// transports.
class UyavaBootstrap {
  UyavaBootstrap._();

  static _UyavaGlobalErrorManager? _manager;

  /// Installs global error hooks and returns a handle that restores the
  /// previous handlers once all callers dispose their handles.
  static UyavaGlobalErrorHandle installGlobalErrorHandlers({
    required UyavaFileTransport transport,
    UyavaGlobalErrorOptions options = const UyavaGlobalErrorOptions(),
  }) {
    final _UyavaGlobalErrorManager? existing = _manager;
    if (existing != null && !existing.isDisposed) {
      if (!identical(existing.transport, transport)) {
        throw StateError(
          'Global error handlers are already installed for a different transport.',
        );
      }
      return existing.retain(options: options);
    }

    final _UyavaGlobalErrorManager manager = _UyavaGlobalErrorManager(
      transport: transport,
      options: options,
    );
    _manager = manager;
    return manager.primaryHandle;
  }

  /// Removes all installed handlers immediately, regardless of outstanding
  /// handles. This is primarily intended for tests and hot reload scenarios.
  static void removeGlobalErrorHandlers() {
    _manager?.dispose();
    _manager = null;
  }

  /// Overrides the fatal error dispatcher used to bubble fatal errors once
  /// logging completes. Intended for tests so they can intercept the
  /// propagation without terminating the process.
  @visibleForTesting
  static void debugOverrideFatalDispatcher(UyavaFatalDispatcher? dispatcher) {
    _fatalDispatcher = dispatcher ?? _defaultFatalDispatcher;
  }

  /// Runs [body] inside a guarded zone so that asynchronous errors are routed
  /// through the Uyava error manager. The returned value is the same as
  /// [runZonedGuarded].
  static Future<R> runZoned<R>(
    FutureOr<R> Function() body, {
    required UyavaFileTransport transport,
    UyavaGlobalErrorOptions options = const UyavaGlobalErrorOptions(),
    ZoneSpecification? zoneSpecification,
    Map<Object?, Object?>? zoneValues,
  }) {
    final _UyavaGlobalErrorManager manager = _ensureManager(
      transport: transport,
      options: options,
    );
    if (!manager.options.enableZonedErrors) {
      return Future<R>.value(body());
    }

    final List<_PendingZoneError> pending = <_PendingZoneError>[];

    void zoneErrorHandler(Object error, StackTrace stackTrace) {
      final Zone errorZone = Zone.current;
      if (manager.isDisposed) {
        final Zone? parent = errorZone.parent;
        if (parent != null) {
          parent.handleUncaughtError(error, stackTrace);
        } else {
          Zone.root.handleUncaughtError(error, stackTrace);
        }
        return;
      }
      final Future<void> logging = manager.handleZonedError(error, stackTrace);
      final _PendingZoneError pendingError = _PendingZoneError(
        error: error,
        stackTrace: stackTrace,
        logging: logging,
        zone: errorZone,
      );
      pending.add(pendingError);

      if (manager.options.propagateToZone) {
        logging.whenComplete(() {
          if (!pendingError.bodyCompleted) {
            manager._propagateFatal(error, stackTrace);
          }
        });
      }
    }

    final FutureOr<Object?> result = runZonedGuarded<FutureOr<Object?>>(
      body,
      zoneErrorHandler,
      zoneSpecification: zoneSpecification,
      zoneValues: zoneValues,
    );

    return Future<Object?>.value(result)
        .then((Object? value) async {
          if (pending.isEmpty) {
            return value as R;
          }

          for (final _PendingZoneError pendingError in pending) {
            pendingError.bodyCompleted = true;
            try {
              await pendingError.logging.timeout(manager.options.flushTimeout);
            } on TimeoutException {
              // Logging already reports timeouts; avoid double-printing.
            }
          }

          final _PendingZoneError first = pending.first;
          Error.throwWithStackTrace(first.error, first.stackTrace);
        })
        .then<R>((Object? value) => value as R);
  }

  static _UyavaGlobalErrorManager _ensureManager({
    required UyavaFileTransport transport,
    required UyavaGlobalErrorOptions options,
  }) {
    final _UyavaGlobalErrorManager? existing = _manager;
    if (existing != null && !existing.isDisposed) {
      if (!identical(existing.transport, transport)) {
        throw StateError(
          'Global error handlers are already installed for a different transport.',
        );
      }
      existing.updateOptions(options);
      return existing;
    }
    final _UyavaGlobalErrorManager manager = _UyavaGlobalErrorManager(
      transport: transport,
      options: options,
    );
    _manager = manager;
    return manager;
  }

  /// Send port that receives forwarded isolate errors when
  /// [UyavaGlobalErrorOptions.enableIsolateErrors] is enabled.
  static SendPort? get isolateErrorPort => _manager?.isolateErrorPort;

  /// Registers an isolate with the shared error listener so unhandled errors
  /// from that isolate are forwarded to Uyava transports.
  ///
  /// Returns `false` when isolate forwarding is disabled or no handlers are
  /// currently installed.
  static bool attachIsolateErrorListener(Isolate isolate) {
    final _UyavaGlobalErrorManager? manager = _manager;
    if (manager == null) {
      return false;
    }
    return manager.attachIsolateErrorListener(isolate);
  }

  /// Exposes the zone key that disables fatal propagation. This is intended
  /// for tests that need to observe logging without crashing the process.
  static Object get debugSkipFatalPropagationZoneKey =>
      _skipFatalPropagationZoneKey;

  /// Forces reinstallation of the [FlutterError.presentError] hook if a manager
  /// is active. Intended for environments that override `presentError` after
  /// Uyava installs its handlers (e.g., host-specific wrappers).
  static void ensurePresentErrorHook() {
    final _UyavaGlobalErrorManager? manager = _manager;
    manager?._ensurePresentErrorHook();
  }
}

enum _UyavaGlobalErrorSource { flutter, platformDispatcher, zone, isolate }

class _UyavaGlobalErrorManager {
  _UyavaGlobalErrorManager({
    required this.transport,
    required UyavaGlobalErrorOptions options,
  }) : _options = options {
    _install();
    _handles.add(_UyavaGlobalErrorHandleImpl(this, options));
  }

  final UyavaFileTransport transport;
  UyavaGlobalErrorOptions _options;

  UyavaGlobalErrorOptions get options => _options;

  bool _isDisposed = false;
  FlutterExceptionHandler? _previousFlutterHandler;
  bool Function(Object, StackTrace)? _previousPlatformHandler;
  FlutterExceptionHandler? _previousPresentError;
  bool _installedFlutterHook = false;
  bool _installedPlatformHook = false;
  bool _installedPresentErrorHook = false;
  bool _fatalTriggered = false;
  bool _flutterHandlerHijackedLogged = false;
  bool _autoGuardEnabled = false;
  bool _autoGuardWarningLogged = false;
  _IsolateErrorListener? _isolateErrors;
  final _RecentErrorDeduper _deduper = _RecentErrorDeduper();

  final List<_UyavaGlobalErrorHandleImpl> _handles =
      <_UyavaGlobalErrorHandleImpl>[];

  _UyavaGlobalErrorHandleImpl get primaryHandle => _handles.first;

  bool get isDisposed => _isDisposed;

  void updateOptions(UyavaGlobalErrorOptions options) {
    if (options.enableFlutterError != _options.enableFlutterError ||
        options.enablePlatformDispatcher != _options.enablePlatformDispatcher) {
      throw StateError(
        'Global error handler toggles cannot change while handlers are installed.',
      );
    }
    final bool isolateOptionsChanged =
        options.enableIsolateErrors != _options.enableIsolateErrors ||
        options.captureCurrentIsolateErrors !=
            _options.captureCurrentIsolateErrors;
    if (!options.autoGuardZone) {
      _autoGuardEnabled = false;
    }
    _options = options;
    if (isolateOptionsChanged) {
      _configureIsolateListener();
    }
    _maybeActivateAutoGuard();
  }

  UyavaGlobalErrorHandle retain({required UyavaGlobalErrorOptions options}) {
    updateOptions(options);
    final _UyavaGlobalErrorHandleImpl handle = _UyavaGlobalErrorHandleImpl(
      this,
      options,
    );
    _handles.add(handle);
    return handle;
  }

  void _install() {
    if (_options.enableFlutterError) {
      _previousFlutterHandler = FlutterError.onError;
      FlutterError.onError = _handleFlutterError;
      _installedFlutterHook = true;
      _ensurePresentErrorHook();
    }
    if (_options.enablePlatformDispatcher) {
      _previousPlatformHandler = ui.PlatformDispatcher.instance.onError;
      ui.PlatformDispatcher.instance.onError = _handlePlatformDispatcherError;
      _installedPlatformHook = true;
    }
    _configureIsolateListener();
    _maybeActivateAutoGuard();
  }

  void _restore() {
    if (_installedFlutterHook) {
      FlutterError.onError = _previousFlutterHandler;
    }
    if (_installedPlatformHook) {
      ui.PlatformDispatcher.instance.onError = _previousPlatformHandler;
    }
    if (_installedPresentErrorHook) {
      FlutterError.presentError =
          _previousPresentError ?? FlutterError.dumpErrorToConsole;
    }
    unawaited(_isolateErrors?.close());
    _isolateErrors = null;
  }

  void _ensurePresentErrorHook() {
    _previousPresentError = FlutterError.presentError;
    FlutterError.presentError = _handleFlutterPresentError;
    _installedPresentErrorHook = true;
  }

  Future<void> handleZonedError(Object error, StackTrace stackTrace) {
    return _recordError(
      source: _UyavaGlobalErrorSource.zone,
      error: error,
      stackTrace: stackTrace,
      isFatal: _options.propagateToZone,
    );
  }

  SendPort? get isolateErrorPort => _isolateErrors?.port;

  bool attachIsolateErrorListener(Isolate isolate) {
    final _IsolateErrorListener? listener = _isolateErrors;
    if (listener == null) {
      return false;
    }
    listener.attach(isolate);
    return true;
  }

  void _configureIsolateListener() {
    if (_isDisposed) {
      return;
    }
    final bool listenToCurrent =
        _options.captureCurrentIsolateErrors || _autoGuardEnabled;
    final bool shouldListen = _options.enableIsolateErrors || _autoGuardEnabled;
    if (!shouldListen) {
      unawaited(_isolateErrors?.close());
      _isolateErrors = null;
      return;
    }
    _isolateErrors ??= _IsolateErrorListener(
      onError: _handleIsolateError,
      listenToCurrent: listenToCurrent,
    );
    _isolateErrors!.toggleCurrent(listenToCurrent);
  }

  void _maybeActivateAutoGuard() {
    if (_isDisposed || !_options.autoGuardZone || !_options.enableZonedErrors) {
      return;
    }
    if (!_autoGuardWarningLogged) {
      developer.log(
        'Uyava autoGuardZone enabled: UyavaBootstrap.runZoned was not used; '
        'attaching isolate listener to capture uncaught async errors.',
        name: 'Uyava',
      );
      _autoGuardWarningLogged = true;
    }
    _autoGuardEnabled = true;
    _configureIsolateListener();
  }

  void _handleFlutterError(FlutterErrorDetails details) async {
    final Object error = details.exception;
    final StackTrace stackTrace =
        details.stack ?? StackTrace.fromString('Stack trace unavailable');
    await _recordError(
      source: _UyavaGlobalErrorSource.flutter,
      error: error,
      stackTrace: stackTrace,
      flutterDetails: details,
      isFatal: _options.propagateToZone,
      message: details.exceptionAsString(),
    );

    if (_options.delegateOriginalHandlers) {
      final FlutterExceptionHandler? handler = _previousFlutterHandler;
      if (handler != null) {
        handler(details);
      } else {
        FlutterError.presentError(details);
      }
    }

    if (_options.propagateToZone) {
      _propagateFatal(error, stackTrace);
    }
  }

  void _handleFlutterPresentError(FlutterErrorDetails details) {
    final bool handlerDetached =
        _installedFlutterHook &&
        !identical(FlutterError.onError, _handleFlutterError);
    if (!_isDisposed) {
      if (handlerDetached && !_flutterHandlerHijackedLogged) {
        developer.log(
          'Uyava detected FlutterError.onError was replaced after installation; '
          'falling back to presentError guard.',
          name: 'Uyava',
        );
        _flutterHandlerHijackedLogged = true;
      }
      developer.log(
        'Uyava presentError guard logging runtimeError diagnostic.',
        name: 'Uyava',
        error: details.exception,
        stackTrace:
            details.stack ?? StackTrace.fromString('Stack trace unavailable'),
      );
      unawaited(
        _recordError(
          source: _UyavaGlobalErrorSource.flutter,
          error: details.exception,
          stackTrace:
              details.stack ?? StackTrace.fromString('Stack trace unavailable'),
          flutterDetails: details,
          isFatal: _options.propagateToZone,
          message: details.exceptionAsString(),
          dedupe: false,
          contextExtras: <String, Object?>{
            'presentErrorGuard': true,
            if (handlerDetached) 'onErrorHandlerHijacked': true,
          },
        ),
      );
    }

    final FlutterExceptionHandler? delegate = _previousPresentError;
    if (delegate != null) {
      delegate(details);
    } else {
      FlutterError.dumpErrorToConsole(details);
    }
  }

  bool _handlePlatformDispatcherError(Object error, StackTrace stackTrace) {
    final Future<void> logging = _recordError(
      source: _UyavaGlobalErrorSource.platformDispatcher,
      error: error,
      stackTrace: stackTrace,
      isFatal: _options.propagateToZone,
    );

    if (_options.propagateToZone) {
      logging.whenComplete(() {
        _propagateFatal(error, stackTrace);
      });
    }

    bool handled = false;
    if (_options.delegateOriginalHandlers) {
      final bool Function(Object, StackTrace)? handler =
          _previousPlatformHandler;
      if (handler != null) {
        handled = handler(error, stackTrace);
      }
    }
    return handled;
  }

  Future<void> _handleIsolateError(Object? message) async {
    if (_isDisposed) {
      return;
    }
    final _IsolateErrorPayload normalized = _normalizeIsolateError(message);
    await _recordError(
      source: _UyavaGlobalErrorSource.isolate,
      error: normalized.error,
      stackTrace: normalized.stackTrace,
      isFatal: false,
      message: normalized.message,
      contextExtras: <String, Object?>{
        'isolateForwarded': true,
        ...normalized.context,
      },
      dedupe: true,
    );
  }

  Future<void> _recordError({
    required _UyavaGlobalErrorSource source,
    required Object error,
    required StackTrace stackTrace,
    required bool isFatal,
    FlutterErrorDetails? flutterDetails,
    String? message,
    Map<String, Object?>? contextExtras,
    bool dedupe = false,
  }) async {
    if (_isDisposed) {
      return;
    }

    final bool seenBefore = _deduper.mark(error: error, stackTrace: stackTrace);
    if (dedupe && seenBefore) {
      return;
    }

    final String zoneDescription = _describeZone();
    final Map<String, Object?> context = <String, Object?>{
      'source': source.name,
      'zoneId': Zone.current.hashCode,
      if (flutterDetails != null)
        'flutter': _flutterContextDetails(flutterDetails),
      if (contextExtras != null) ...contextExtras,
    };
    context.removeWhere((String key, Object? value) {
      if (value == null) return true;
      if (value is Map && value.isEmpty) return true;
      if (value is Iterable && value.isEmpty) return true;
      if (value is String && value.isEmpty) return true;
      return false;
    });

    final String resolvedMessage =
        message ?? flutterDetails?.exceptionAsString() ?? error.toString();

    final Map<String, Object?> runtimePayload = buildRuntimeErrorPayload(
      source: source.name,
      error: error,
      stackTrace: stackTrace,
      isFatal: isFatal,
      zoneDescription: zoneDescription,
      message: resolvedMessage,
      context: context.isEmpty ? null : context,
    );

    _PanicDiagnosticSnapshot snapshot = _PanicDiagnosticSnapshot(
      payloadBytes: _estimateJsonBytes(runtimePayload),
      panicMirrorPath: transport.config.crashSafePersistence
          ? _panicMirrorPath(transport)
          : null,
    );

    try {
      await transport.logRuntimeError(
        source: source.name,
        error: error,
        stackTrace: stackTrace,
        isFatal: isFatal,
        zoneDescription: zoneDescription,
        message: resolvedMessage,
        context: context.isEmpty ? null : context,
        timeout: _options.flushTimeout,
      );
      snapshot = await _collectPanicArtifacts(
        initial: snapshot,
        transport: transport,
        timeout: _options.flushTimeout,
      );
    } catch (loggingError, loggingStack) {
      developer.log(
        'Uyava global error logging failed: $loggingError',
        name: 'Uyava',
        error: loggingError,
        stackTrace: loggingStack,
      );
      snapshot = _PanicDiagnosticSnapshot(
        payloadBytes: null,
        panicMirrorPath: snapshot.panicMirrorPath,
        panicMirrorBytes: null,
        archive: null,
        loggingError: loggingError,
      );
    } finally {
      final bool shouldEmitDiagnostic =
          isFatal || _options.emitNonFatalDiagnostics;
      if (shouldEmitDiagnostic) {
        _emitPanicDiagnostic(
          source: source,
          error: error,
          stackTrace: stackTrace,
          message: resolvedMessage,
          runtimeContext: context,
          snapshot: snapshot,
          isFatal: isFatal,
          level: isFatal
              ? UyavaDiagnosticLevel.error
              : UyavaDiagnosticLevel.warning,
        );
      }
    }
  }

  void _propagateFatal(Object error, StackTrace stackTrace) {
    if (Zone.current[_skipFatalPropagationZoneKey] == true) {
      return;
    }
    if (_fatalTriggered) {
      return;
    }
    _fatalTriggered = true;
    dispose();
    _fatalDispatcher(error, stackTrace);
  }

  void releaseHandle(_UyavaGlobalErrorHandleImpl handle) {
    if (_isDisposed) {
      return;
    }
    _handles.remove(handle);
    if (_handles.isEmpty) {
      dispose();
    }
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _restore();
    for (final _UyavaGlobalErrorHandleImpl handle in _handles) {
      handle.markDisposed();
    }
    _handles.clear();
    if (identical(UyavaBootstrap._manager, this)) {
      UyavaBootstrap._manager = null;
    }
  }
}

class _PendingZoneError {
  _PendingZoneError({
    required this.error,
    required this.stackTrace,
    required this.logging,
    required this.zone,
  });

  final Object error;
  final StackTrace stackTrace;
  final Future<void> logging;
  final Zone zone;

  bool bodyCompleted = false;
}

class _IsolateErrorPayload {
  const _IsolateErrorPayload({
    required this.error,
    required this.stackTrace,
    required this.message,
    required this.context,
  });

  final Object error;
  final StackTrace stackTrace;
  final String message;
  final Map<String, Object?> context;
}

class _RecentErrorDeduper {
  static const int _maxDigests = 20;
  final List<String> _digests = <String>[];

  bool mark({required Object error, required StackTrace stackTrace}) {
    final String digest =
        '${error.runtimeType}:${error.toString()}:${stackTrace.toString().hashCode}';
    if (_digests.contains(digest)) {
      return true;
    }
    _digests.add(digest);
    if (_digests.length > _maxDigests) {
      _digests.removeAt(0);
    }
    return false;
  }
}

class _IsolateErrorListener {
  _IsolateErrorListener({required this.onError, required bool listenToCurrent})
    : _port = ReceivePort('uyava_isolate_errors') {
    _subscription = _port.listen(onError);
    if (listenToCurrent) {
      _attachCurrent();
    }
  }

  final ReceivePort _port;
  final void Function(Object? message) onError;
  late final StreamSubscription<dynamic> _subscription;
  final Set<Isolate> _attachedIsolates = <Isolate>{};
  bool _listeningToCurrent = false;
  bool _closed = false;

  SendPort get port => _port.sendPort;

  void toggleCurrent(bool enabled) {
    if (_closed) {
      return;
    }
    if (enabled) {
      _attachCurrent();
    } else {
      _detachCurrent();
    }
  }

  void attach(Isolate isolate) {
    if (_closed || _attachedIsolates.contains(isolate)) {
      return;
    }
    _attachedIsolates.add(isolate);
    isolate.addErrorListener(_port.sendPort);
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    for (final Isolate isolate in _attachedIsolates) {
      isolate.removeErrorListener(_port.sendPort);
    }
    _attachedIsolates.clear();
    _detachCurrent();
    await _subscription.cancel();
    _port.close();
  }

  void _attachCurrent() {
    if (_closed || _listeningToCurrent) {
      return;
    }
    Isolate.current.addErrorListener(_port.sendPort);
    _listeningToCurrent = true;
  }

  void _detachCurrent() {
    if (_closed || !_listeningToCurrent) {
      return;
    }
    Isolate.current.removeErrorListener(_port.sendPort);
    _listeningToCurrent = false;
  }
}

_IsolateErrorPayload _normalizeIsolateError(Object? raw) {
  Object error;
  StackTrace stackTrace;
  String message;
  final Map<String, Object?> context = <String, Object?>{};

  if (raw is List && raw.length >= 2) {
    final Object? rawError = raw[0];
    final Object? rawStack = raw[1];
    final String errorText = rawError?.toString() ?? 'Isolate error';
    final String stackText = rawStack?.toString() ?? '';
    error = rawStack is String
        ? RemoteError(errorText, stackText)
        : rawError ?? StateError('Isolate error');
    stackTrace = rawStack is StackTrace
        ? rawStack
        : StackTrace.fromString(
            stackText.isNotEmpty ? stackText : 'Stack trace unavailable',
          );
    message = errorText;
    context['isolateError'] = errorText;
    context['isolateErrorType'] = rawError?.runtimeType.toString();
  } else if (raw is RemoteError) {
    error = raw;
    message = raw.toString();
    final Object remoteStack = raw.stackTrace;
    stackTrace = remoteStack is StackTrace
        ? remoteStack
        : StackTrace.fromString(remoteStack.toString());
  } else if (raw is Error) {
    error = raw;
    message = raw.toString();
    stackTrace = raw.stackTrace ?? StackTrace.fromString(raw.toString());
  } else if (raw is Object) {
    error = raw;
    message = raw.toString();
    stackTrace = StackTrace.fromString('Stack trace unavailable');
  } else {
    error = StateError('Isolate error $raw');
    message = error.toString();
    stackTrace = StackTrace.fromString('Stack trace unavailable');
  }

  context.removeWhere(_pruneContextEntry);

  return _IsolateErrorPayload(
    error: error,
    stackTrace: stackTrace,
    message: message,
    context: context,
  );
}

Future<_PanicDiagnosticSnapshot> _collectPanicArtifacts({
  required _PanicDiagnosticSnapshot initial,
  required UyavaFileTransport transport,
  required Duration timeout,
}) async {
  int? mirrorBytes = initial.panicMirrorBytes;
  if (initial.panicMirrorPath != null) {
    try {
      final File mirror = File(initial.panicMirrorPath!);
      if (await mirror.exists()) {
        mirrorBytes = await mirror.length();
      }
    } catch (error, stackTrace) {
      developer.log(
        'Uyava panic mirror inspection failed: $error',
        name: 'Uyava',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  UyavaLogArchive? archive = initial.archive;
  try {
    archive = await transport
        .latestArchiveSnapshot(includeExports: true)
        .timeout(timeout, onTimeout: () => archive);
  } catch (error, stackTrace) {
    developer.log(
      'Uyava panic archive lookup failed: $error',
      name: 'Uyava',
      error: error,
      stackTrace: stackTrace,
    );
  }

  return initial.copyWith(panicMirrorBytes: mirrorBytes, archive: archive);
}

void _emitPanicDiagnostic({
  required _UyavaGlobalErrorSource source,
  required Object error,
  required StackTrace stackTrace,
  required String message,
  required Map<String, Object?> runtimeContext,
  required _PanicDiagnosticSnapshot snapshot,
  required bool isFatal,
  required UyavaDiagnosticLevel level,
}) {
  final Map<String, Object?> panicTail = <String, Object?>{
    'available': snapshot.hasTail,
    if (snapshot.payloadBytes != null) 'payloadBytes': snapshot.payloadBytes,
    if (snapshot.panicMirrorBytes != null)
      'panicMirrorBytes': snapshot.panicMirrorBytes,
    if (snapshot.panicMirrorPath != null)
      'panicMirrorPath': snapshot.panicMirrorPath,
  }..removeWhere(_pruneContextEntry);

  final Map<String, Object?> context = <String, Object?>{
    'summary': _panicDiagnosticSummary,
    'source': source.name,
    'fatal': isFatal,
    'errorType': error.runtimeType.toString(),
    'message': message,
    'stackTrace': stackTrace.toString(),
    if (runtimeContext.isNotEmpty) 'runtimeContext': runtimeContext,
    'panicTail': panicTail,
    if (snapshot.archive != null)
      'archive': <String, Object?>{
        'path': snapshot.archive!.path,
        'fileName': snapshot.archive!.fileName,
        'sizeBytes': snapshot.archive!.sizeBytes,
      },
    if (snapshot.loggingError != null)
      'loggingError': snapshot.loggingError.toString(),
  }..removeWhere(_pruneContextEntry);

  publishDiagnostic(
    UyavaGraphDiagnosticPayload(
      code: _panicDiagnosticCode,
      level: level,
      context: context,
    ),
  );
}

String? _panicMirrorPath(UyavaFileTransport transport) {
  final String base = transport.path;
  if (base.isEmpty) return null;
  return '$base${Platform.pathSeparator}${transport.config.panicMirrorFileName}';
}

int? _estimateJsonBytes(Map<String, Object?> payload) {
  try {
    return utf8.encode(jsonEncode(payload)).length;
  } catch (_) {
    try {
      return utf8.encode(payload.toString()).length;
    } catch (_) {
      return 0;
    }
  }
}

bool _pruneContextEntry(String key, Object? value) {
  if (value == null) return true;
  if (value is Map && value.isEmpty) return true;
  if (value is Iterable && value.isEmpty) return true;
  if (value is String && value.isEmpty) return true;
  return false;
}

Map<String, Object?> _flutterContextDetails(FlutterErrorDetails details) {
  final Map<String, Object?> data = <String, Object?>{
    if (details.library != null) 'library': details.library,
    if (details.context != null) 'context': details.context!.toDescription(),
    if (details.informationCollector != null)
      'information': details.informationCollector!()
          .map((DiagnosticsNode node) => node.toDescription())
          .where((String value) => value.isNotEmpty)
          .toList(growable: false),
    if (details.silent) 'silent': details.silent,
  };
  data.removeWhere((String key, Object? value) {
    if (value == null) return true;
    if (value is Iterable && value.isEmpty) return true;
    if (value is String && value.isEmpty) return true;
    return false;
  });
  return data;
}

String _describeZone() {
  final Zone zone = Zone.current;
  if (identical(zone, Zone.root)) {
    return 'root';
  }
  final Object? named = zone[#uyavaZoneName];
  if (named is String && named.isNotEmpty) {
    return named;
  }
  return 'zone#${zone.hashCode}';
}

class _UyavaGlobalErrorHandleImpl implements UyavaGlobalErrorHandle {
  _UyavaGlobalErrorHandleImpl(this._manager, this._options);

  final _UyavaGlobalErrorManager _manager;
  final UyavaGlobalErrorOptions _options;
  bool _isDisposed = false;

  @override
  UyavaFileTransport get transport => _manager.transport;

  @override
  UyavaGlobalErrorOptions get options => _options;

  @override
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _manager.releaseHandle(this);
  }

  void markDisposed() {
    _isDisposed = true;
  }
}
