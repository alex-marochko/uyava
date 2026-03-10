import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava/uyava.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UyavaFileTransport transport;
  FlutterExceptionHandler? originalFlutterHandler;
  bool Function(Object, StackTrace)? originalPlatformHandler;

  setUp(() async {
    originalFlutterHandler = FlutterError.onError;
    originalPlatformHandler = ui.PlatformDispatcher.instance.onError;
    tempDir = await Directory.systemTemp.createTemp('uyava_error_handlers');
    transport = await UyavaFileTransport.start(
      config: UyavaFileLoggerConfig(
        directoryPath: tempDir.path,
        flushInterval: const Duration(milliseconds: 50),
        retainLatestOnly: true,
      ),
    );
    UyavaBootstrap.debugOverrideFatalDispatcher(null);
  });

  tearDown(() async {
    UyavaBootstrap.removeGlobalErrorHandlers();
    Uyava.postEventObserver = null;
    Uyava.resetStateForTesting();
    FlutterError.onError = originalFlutterHandler;
    ui.PlatformDispatcher.instance.onError = originalPlatformHandler;
    await transport.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('install and dispose restore previous handlers', () async {
    bool delegatedFlutter = false;
    void customFlutterHandler(FlutterErrorDetails details) {
      delegatedFlutter = true;
    }

    FlutterError.onError = customFlutterHandler;

    bool delegatedPlatform = false;
    bool customPlatformHandler(Object error, StackTrace stack) {
      delegatedPlatform = true;
      return true;
    }

    ui.PlatformDispatcher.instance.onError = customPlatformHandler;

    final UyavaGlobalErrorHandle handle =
        UyavaBootstrap.installGlobalErrorHandlers(
          transport: transport,
          options: const UyavaGlobalErrorOptions(propagateToZone: false),
        );

    expect(handle.isDisposed, isFalse);
    expect(handle.transport, same(transport));

    final FlutterExceptionHandler? wrappedFlutterHandler = FlutterError.onError;
    expect(wrappedFlutterHandler, isNotNull);
    expect(wrappedFlutterHandler, isNot(same(originalFlutterHandler)));

    wrappedFlutterHandler!(FlutterErrorDetails(exception: Exception('boom')));
    await _expectEventuallyTrue(
      () => delegatedFlutter,
      reason: 'FlutterError.onError delegate was not invoked',
    );

    final bool handled = ui.PlatformDispatcher.instance.onError!.call(
      Exception('platform'),
      StackTrace.current,
    );
    expect(delegatedPlatform, isTrue);
    expect(handled, isTrue);

    handle.dispose();
    expect(handle.isDisposed, isTrue);
    expect(FlutterError.onError, same(customFlutterHandler));
    expect(ui.PlatformDispatcher.instance.onError, same(customPlatformHandler));
  });

  test(
    'reinstall reuses existing handlers and reference counting works',
    () async {
      final UyavaGlobalErrorHandle first =
          UyavaBootstrap.installGlobalErrorHandlers(
            transport: transport,
            options: const UyavaGlobalErrorOptions(propagateToZone: false),
          );
      final FlutterExceptionHandler? capturedHandler = FlutterError.onError;

      final UyavaGlobalErrorHandle second =
          UyavaBootstrap.installGlobalErrorHandlers(
            transport: transport,
            options: const UyavaGlobalErrorOptions(propagateToZone: false),
          );

      expect(second.isDisposed, isFalse);
      expect(FlutterError.onError, same(capturedHandler));

      first.dispose();
      expect(FlutterError.onError, same(capturedHandler));
      expect(second.isDisposed, isFalse);

      await pumpEventQueue(times: 5);
      second.dispose();
      expect(FlutterError.onError, same(originalFlutterHandler));
      expect(
        ui.PlatformDispatcher.instance.onError,
        same(originalPlatformHandler),
      );
    },
  );

  test(
    'flutter errors produce runtimeError records and flush before delegate',
    () async {
      bool delegated = false;
      FlutterError.onError = (FlutterErrorDetails details) {
        delegated = true;
      };

      final UyavaGlobalErrorHandle handle =
          UyavaBootstrap.installGlobalErrorHandlers(
            transport: transport,
            options: const UyavaGlobalErrorOptions(propagateToZone: false),
          );

      final FlutterExceptionHandler? handler = FlutterError.onError;
      expect(handler, isNotNull);

      handler!(
        FlutterErrorDetails(
          exception: Exception('panic'),
          stack: StackTrace.fromString('test-stack'),
          library: 'testLibrary',
        ),
      );

      await _expectEventuallyTrue(
        () => delegated,
        reason: 'FlutterError.onError delegate was not invoked',
      );

      await transport.flush();
      await transport.dispose();

      final List<Map<String, dynamic>> records = await _readLogRecords(
        tempDir: tempDir,
      );
      final Map<String, dynamic> runtimeRecord = records.firstWhere(
        (Map<String, dynamic> record) => record['type'] == 'runtimeError',
      );

      expect(
        runtimeRecord['scope'],
        equals(UyavaTransportScope.diagnostic.name),
      );
      expect(runtimeRecord['hostMetadata'], isNotNull);

      final Map<String, dynamic> payload = Map<String, dynamic>.from(
        runtimeRecord['payload'],
      );
      expect(payload['source'], equals('flutter'));
      expect(payload['isFatal'], isFalse);
      expect(payload['message'], equals('Exception: panic'));
      expect(payload['stackTrace'], contains('test-stack'));
      expect(payload['platform'], isNotEmpty);

      handle.dispose();
    },
  );

  test('publishes panic diagnostics to transports', () async {
    final List<Map<String, Object?>> observed = <Map<String, Object?>>[];
    Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
      observed.add(<String, Object?>{
        'type': type,
        'payload': Map<String, dynamic>.from(payload),
      });
    };
    expect(Uyava.transports, isNotEmpty);

    final UyavaGlobalErrorHandle handle =
        UyavaBootstrap.installGlobalErrorHandlers(
          transport: transport,
          options: const UyavaGlobalErrorOptions(propagateToZone: false),
        );

    final FlutterExceptionHandler? handler = FlutterError.onError;
    expect(handler, isNotNull);

    handler!(
      FlutterErrorDetails(
        exception: Exception('panic diagnostics'),
        stack: StackTrace.fromString('diagnostic-stack'),
      ),
    );

    await _expectEventuallyTrue(
      () => observed.any(
        (entry) => entry['type'] == UyavaEventTypes.graphDiagnostics,
      ),
      reason: 'panic diagnostic was not published',
    );

    final Map<String, dynamic> diagnosticPayload = Map<String, dynamic>.from(
      observed.firstWhere(
            (entry) => entry['type'] == UyavaEventTypes.graphDiagnostics,
          )['payload']!
          as Map,
    );

    expect(diagnosticPayload['code'], 'logging.panic_tail_captured');
    expect(diagnosticPayload['level'], 'warning');

    final Map<String, dynamic> context = Map<String, dynamic>.from(
      diagnosticPayload['context'] as Map,
    );
    expect(context['fatal'], isFalse);
    expect(context['message'], contains('panic diagnostics'));
    expect(
      (context['stackTrace'] as String?)?.contains('diagnostic-stack'),
      isTrue,
    );

    final Map<String, dynamic> panicTail = Map<String, dynamic>.from(
      context['panicTail'] as Map,
    );
    expect(panicTail['available'], isTrue);
    expect(panicTail['payloadBytes'], isNotNull);

    final Map<String, dynamic>? archive = (context['archive'] as Map?)
        ?.cast<String, dynamic>();
    if (archive != null) {
      expect(archive['sizeBytes'], greaterThan(0));
      expect((archive['path'] as String?)?.isNotEmpty, isTrue);
    }

    handle.dispose();
  });

  test('captures errors forwarded from spawned isolate', () async {
    final UyavaGlobalErrorHandle handle =
        UyavaBootstrap.installGlobalErrorHandlers(
          transport: transport,
          options: const UyavaGlobalErrorOptions(
            propagateToZone: false,
            delegateOriginalHandlers: false,
            enableIsolateErrors: true,
            captureCurrentIsolateErrors: false,
          ),
        );

    final SendPort? port = UyavaBootstrap.isolateErrorPort;
    expect(port, isNotNull);

    final ReceivePort exitPort = ReceivePort();
    await Isolate.spawn<void>(
      _crashingIsolate,
      null,
      onError: port,
      onExit: exitPort.sendPort,
      errorsAreFatal: true,
    );
    await exitPort.first;
    exitPort.close();

    await pumpEventQueue(times: 10);
    await transport.flush();
    await transport.dispose();

    final List<Map<String, dynamic>> records = await _readLogRecords(
      tempDir: tempDir,
    );
    expect(records, isNotEmpty, reason: 'Isolate errors should be logged.');
    final Map<String, dynamic> runtimeRecord = records.firstWhere(
      (Map<String, dynamic> record) => record['type'] == 'runtimeError',
    );

    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      runtimeRecord['payload'],
    );
    expect(payload['source'], equals('isolate'));
    expect(payload['isFatal'], isFalse);
    expect(payload['message'], contains('isolate panic'));
    expect(payload['stackTrace'], contains('_crashingIsolate'));

    handle.dispose();
  });

  test(
    'autoGuardZone attaches isolate listener when runZoned is not used',
    () async {
      final UyavaGlobalErrorHandle handle =
          UyavaBootstrap.installGlobalErrorHandlers(
            transport: transport,
            options: const UyavaGlobalErrorOptions(
              propagateToZone: false,
              delegateOriginalHandlers: false,
              enableIsolateErrors: false,
              autoGuardZone: true,
            ),
          );

      final SendPort? port = UyavaBootstrap.isolateErrorPort;
      expect(port, isNotNull);

      port!.send(<Object?>['auto-guard failure', 'auto-guard stack']);
      await pumpEventQueue(times: 10);

      await transport.flush();
      await transport.dispose();

      final List<Map<String, dynamic>> records = await _readLogRecords(
        tempDir: tempDir,
      );
      final Map<String, dynamic> runtimeRecord = records.firstWhere(
        (Map<String, dynamic> record) => record['type'] == 'runtimeError',
      );
      final Map<String, dynamic> payload = Map<String, dynamic>.from(
        runtimeRecord['payload'],
      );

      expect(payload['source'], equals('isolate'));
      expect(payload['message'], contains('auto-guard failure'));

      handle.dispose();
    },
  );

  test(
    'autoGuardZone off does not install isolate listener when isolate errors disabled',
    () async {
      final UyavaGlobalErrorHandle handle =
          UyavaBootstrap.installGlobalErrorHandlers(
            transport: transport,
            options: const UyavaGlobalErrorOptions(
              propagateToZone: false,
              delegateOriginalHandlers: false,
              enableIsolateErrors: false,
              autoGuardZone: false,
            ),
          );

      expect(UyavaBootstrap.isolateErrorPort, isNull);

      handle.dispose();
    },
  );

  test('presentError guard logs when onError is replaced', () async {
    final UyavaGlobalErrorHandle handle =
        UyavaBootstrap.installGlobalErrorHandlers(
          transport: transport,
          options: const UyavaGlobalErrorOptions(
            propagateToZone: false,
            delegateOriginalHandlers: false,
          ),
        );

    FlutterError.onError = (FlutterErrorDetails _) {};

    FlutterError.presentError(
      FlutterErrorDetails(
        exception: StateError('present-only failure'),
        stack: StackTrace.fromString('present-stack'),
      ),
    );

    await pumpEventQueue(times: 10);
    await transport.flush();
    await transport.dispose();

    final List<Map<String, dynamic>> records = await _readLogRecords(
      tempDir: tempDir,
    );
    final Map<String, dynamic> runtimeRecord = records.firstWhere(
      (Map<String, dynamic> record) => record['type'] == 'runtimeError',
    );
    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      runtimeRecord['payload'],
    );

    expect(payload['source'], equals('flutter'));
    expect(payload['message'], contains('present-only'));
    expect(payload['stackTrace'], contains('present-stack'));

    handle.dispose();
  });

  test(
    'presentError guard emits diagnostics when onError is hijacked',
    () async {
      final List<Map<String, Object?>> observed = <Map<String, Object?>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        observed.add(<String, Object?>{
          'type': type,
          'payload': Map<String, dynamic>.from(payload),
        });
      };

      final UyavaGlobalErrorHandle handle =
          UyavaBootstrap.installGlobalErrorHandlers(
            transport: transport,
            options: const UyavaGlobalErrorOptions(
              propagateToZone: false,
              delegateOriginalHandlers: false,
            ),
          );

      // Simulate hosts that overwrite presentError after installation.
      FlutterError.presentError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };
      UyavaBootstrap.ensurePresentErrorHook();

      FlutterError.onError = (FlutterErrorDetails _) {};

      FlutterError.presentError(
        FlutterErrorDetails(
          exception: StateError('present-only failure'),
          stack: StackTrace.fromString('present-stack'),
        ),
      );

      Iterable<Map<String, Object?>> getDiagnostics() => observed.where(
        (entry) =>
            entry['type'] == UyavaEventTypes.graphDiagnostics &&
            (entry['payload'] as Map<String, Object?>)['code'] ==
                'logging.panic_tail_captured',
      );

      await _expectEventuallyTrue(
        () => getDiagnostics().isNotEmpty,
        reason: 'Expected panic-tail diagnostic to be emitted',
      );

      final Map<String, Object?> context =
          (getDiagnostics().first['payload']
                  as Map<String, Object?>)['context']!
              as Map<String, Object?>;
      final Map<String, Object?> runtimeContext =
          context['runtimeContext']! as Map<String, Object?>;
      expect(runtimeContext['presentErrorGuard'], isTrue);

      handle.dispose();
      Uyava.postEventObserver = null;
    },
  );

  test('non-fatal diagnostics can be disabled', () async {
    final List<Map<String, Object?>> observed = <Map<String, Object?>>[];
    Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
      observed.add(<String, Object?>{
        'type': type,
        'payload': Map<String, dynamic>.from(payload),
      });
    };

    final UyavaGlobalErrorHandle handle =
        UyavaBootstrap.installGlobalErrorHandlers(
          transport: transport,
          options: const UyavaGlobalErrorOptions(
            propagateToZone: false,
            delegateOriginalHandlers: false,
            emitNonFatalDiagnostics: false,
          ),
        );

    final FlutterExceptionHandler? handler = FlutterError.onError;
    expect(handler, isNotNull);

    handler!(
      FlutterErrorDetails(
        exception: Exception('non-fatal'),
        stack: StackTrace.fromString('non-fatal-stack'),
      ),
    );

    await pumpEventQueue(times: 10);

    expect(
      observed.any(
        (entry) => entry['type'] == UyavaEventTypes.graphDiagnostics,
      ),
      isFalse,
    );

    handle.dispose();
  });

  test('runZoned awaits panic-tail flush before rethrowing', () async {
    final UyavaGlobalErrorHandle handle =
        UyavaBootstrap.installGlobalErrorHandlers(
          transport: transport,
          options: const UyavaGlobalErrorOptions(
            propagateToZone: false,
            delegateOriginalHandlers: false,
          ),
        );

    final Future<void> future = UyavaBootstrap.runZoned<void>(
      () async {
        Future<void>.microtask(() {
          throw StateError('zone panic');
        });
        await pumpEventQueue(times: 5);
      },
      transport: transport,
      options: const UyavaGlobalErrorOptions(
        propagateToZone: false,
        delegateOriginalHandlers: false,
      ),
    );

    await expectLater(future, throwsA(isA<StateError>()));

    await transport.flush();
    await transport.dispose();

    final List<Map<String, dynamic>> records = await _readLogRecords(
      tempDir: tempDir,
    );
    final Map<String, dynamic> runtimeRecord = records.firstWhere(
      (Map<String, dynamic> record) => record['type'] == 'runtimeError',
    );

    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      runtimeRecord['payload'],
    );
    expect(payload['source'], equals('zone'));
    expect(payload['message'], contains('zone panic'));

    handle.dispose();
  });

  test('platform dispatcher errors record runtimeError entries', () async {
    final UyavaGlobalErrorHandle handle =
        UyavaBootstrap.installGlobalErrorHandlers(
          transport: transport,
          options: const UyavaGlobalErrorOptions(
            propagateToZone: false,
            delegateOriginalHandlers: false,
          ),
        );

    final bool handled = ui.PlatformDispatcher.instance.onError!(
      StateError('platform panic'),
      StackTrace.fromString('platform-stack'),
    );
    expect(handled, isFalse);

    await transport.flush();
    await transport.dispose();

    final List<Map<String, dynamic>> records = await _readLogRecords(
      tempDir: tempDir,
    );
    final Map<String, dynamic> runtimeRecord = records.firstWhere(
      (Map<String, dynamic> record) => record['type'] == 'runtimeError',
    );
    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      runtimeRecord['payload'],
    );
    expect(payload['source'], equals('platformDispatcher'));
    expect(payload['message'], contains('platform panic'));

    handle.dispose();
  });

  test(
    'propagateToZone forwards fatal errors without recursive logging',
    () async {
      final UyavaGlobalErrorHandle handle =
          UyavaBootstrap.installGlobalErrorHandlers(
            transport: transport,
            options: const UyavaGlobalErrorOptions(
              propagateToZone: true,
              delegateOriginalHandlers: false,
            ),
          );

      final FlutterExceptionHandler? handler = FlutterError.onError;
      expect(handler, isNotNull);

      runZonedGuarded<void>(
        () {
          handler!(
            FlutterErrorDetails(
              exception: StateError('crash once'),
              stack: StackTrace.fromString('propagate-stack'),
              library: 'testLibrary',
              context: ErrorDescription('recursive propagation test'),
            ),
          );
        },
        (Object error, StackTrace stackTrace) {
          // Swallow the propagated error so the test can continue assertions.
        },
        zoneValues: <Object?, Object?>{
          UyavaBootstrap.debugSkipFatalPropagationZoneKey: true,
        },
      );

      await pumpEventQueue(times: 10);

      await transport.flush();
      await transport.dispose();

      final List<Map<String, dynamic>> records = await _readLogRecords(
        tempDir: tempDir,
      );
      final List<Map<String, dynamic>> runtimeRecords = records
          .where(
            (Map<String, dynamic> record) => record['type'] == 'runtimeError',
          )
          .toList();

      expect(runtimeRecords.length, equals(1));
      final Map<String, dynamic> payload = Map<String, dynamic>.from(
        runtimeRecords.single['payload'],
      );
      expect(payload['source'], equals('flutter'));
      expect(payload['message'], contains('crash once'));

      handle.dispose();
    },
  );

  test(
    'propagateToZone dispatches fatal errors via overrideable dispatcher',
    () async {
      Object? dispatchedError;
      StackTrace? dispatchedStack;
      int dispatchCount = 0;
      UyavaBootstrap.debugOverrideFatalDispatcher((
        Object error,
        StackTrace stack,
      ) {
        dispatchCount += 1;
        dispatchedError = error;
        dispatchedStack = stack;
      });

      final UyavaGlobalErrorHandle handle =
          UyavaBootstrap.installGlobalErrorHandlers(
            transport: transport,
            options: const UyavaGlobalErrorOptions(
              propagateToZone: true,
              delegateOriginalHandlers: false,
            ),
          );

      final FlutterExceptionHandler? handler = FlutterError.onError;
      expect(handler, isNotNull);

      final Object boom = StateError('dispatcher boom');
      final StackTrace stack = StackTrace.fromString('dispatcher-stack');

      handler!(
        FlutterErrorDetails(
          exception: boom,
          stack: stack,
          library: 'testLibrary',
          context: ErrorDescription('fatal dispatcher test'),
        ),
      );

      await _expectEventuallyTrue(
        () => dispatchCount == 1,
        reason: 'Fatal dispatcher did not receive the error',
      );

      expect(dispatchCount, equals(1));
      expect(dispatchedError, same(boom));
      expect(dispatchedStack, same(stack));

      handle.dispose();
    },
  );
}

Future<void> _expectEventuallyTrue(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
  String? reason,
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (predicate()) {
      return;
    }
    await pumpEventQueue();
  }
  expect(
    predicate(),
    isTrue,
    reason:
        reason ?? 'Condition not satisfied within ${timeout.inMilliseconds} ms',
  );
}

Future<List<Map<String, dynamic>>> _readLogRecords({
  required Directory tempDir,
}) async {
  final List<File> files =
      tempDir
          .listSync()
          .whereType<File>()
          .where((File file) => file.path.endsWith('.uyava'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  final File file = files.last;
  final List<int> bytes = await file.readAsBytes();
  final List<int> decompressed = GZipCodec().decoder.convert(bytes);
  final String content = utf8.decode(decompressed);
  final Iterable<String> lines = content
      .split('\n')
      .where((String line) => line.isNotEmpty);
  return lines
      .map((String line) => jsonDecode(line) as Map<String, dynamic>)
      .toList(growable: false);
}

void _crashingIsolate(Object? _) {
  Future<void>.microtask(() {
    throw StateError('isolate panic');
  });
}
