import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uyava/uyava.dart';
import 'package:uyava_example/main.dart' as app;
import 'package:uyava_example/src/file_logging.dart';

import 'support/temp_logging_workspace.dart';
import 'support/test_file_system_delegate.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crash-safe streaming journal is recovered on restart', (
    WidgetTester tester,
  ) async {
    final List<Object> fatalErrors = <Object>[];
    final List<StackTrace> fatalStacks = <StackTrace>[];
    final Completer<void> fatalDispatched = Completer<void>();
    bool fatalTriggered = false;
    bool fatalTimedOut = false;

    UyavaBootstrap.debugOverrideFatalDispatcher((
      Object error,
      StackTrace stack,
    ) {
      fatalErrors.add(error);
      fatalStacks.add(stack);
      if (!fatalDispatched.isCompleted) {
        fatalDispatched.complete();
      }
      fatalTriggered = true;
    });
    addTearDown(() {
      UyavaBootstrap.debugOverrideFatalDispatcher(null);
    });

    final FlutterExceptionHandler? originalFlutterError = FlutterError.onError;
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final originalPlatformHandler = dispatcher.onError;

    setUyavaFileLoggerTestOverrides(
      const UyavaFileLoggerTestOverrides(useSynchronousWorker: true),
    );
    await app.main();
    setUyavaFileLoggerTestOverrides(null);

    addTearDown(() {
      FlutterError.onError = originalFlutterError;
      dispatcher.onError = originalPlatformHandler;
    });

    await tester.pump();
    await _pumpUntil(
      tester,
      () => find.text('Wrong data').evaluate().isNotEmpty,
    );

    final UyavaFileTransport? transport = currentFileTransport();
    expect(transport, isNotNull, reason: 'Expected an active file transport.');

    addTearDown(() async {
      await shutdownFileLogging();
      await Uyava.shutdownTransports();
    });

    final IntegrationLoggingWorkspace workspace =
        IntegrationLoggingWorkspace.fromConfig(config: transport!.config);
    final TestFileSystemDelegate delegate =
        TestFileSystemDelegate.fromWorkspace(workspace);
    addTearDown(delegate.dispose);

    final Finder wrongDataTab = find.widgetWithText(Tab, 'Wrong data');
    expect(wrongDataTab, findsOneWidget);
    await tester.tap(wrongDataTab);
    await tester.pumpAndSettle();

    final Finder crashButton = find.text(
      'Crash via Flutter error',
      skipOffstage: false,
    );
    final Finder scrollable = find.byType(Scrollable);
    expect(scrollable, findsWidgets);
    int scrollAttempts = 0;
    while (crashButton.evaluate().isEmpty && scrollAttempts < 10) {
      await tester.drag(scrollable.first, const Offset(0, -400));
      await tester.pumpAndSettle();
      scrollAttempts += 1;
    }
    expect(
      crashButton,
      findsWidgets,
      reason:
          'The Crash via Flutter error button should appear after scrolling the Wrong data tab.',
    );
    await tester.ensureVisible(crashButton.first);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(crashButton.first);
    await tester.pump();

    try {
      await fatalDispatched.future.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      fatalTimedOut = true;
    }
    await tester.pump(const Duration(milliseconds: 200));

    final Object? crashException = tester.takeException();
    if (crashException != null) {
      expect(crashException, isA<StateError>());
      expect(
        crashException.toString(),
        contains('Crash Flutter error for Uyava panic-tail demo'),
      );
    }

    if (fatalTriggered) {
      expect(
        fatalErrors.first.toString(),
        contains('Crash Flutter error for Uyava panic-tail demo'),
      );
      expect(fatalStacks, isNotEmpty);
    }
    if (fatalTimedOut) {
      expect(
        fatalTriggered,
        isFalse,
        reason:
            'If the fatal dispatcher did not run in time, the fatalTriggered '
            'flag should remain false.',
      );
    }

    List<String> mirrorLines = <String>[];
    await tester.runAsync(() async {
      mirrorLines = await _waitForMirror(delegate);
    });
    expect(
      mirrorLines,
      isNotEmpty,
      reason: 'Panic mirror must contain a record.',
    );

    final File streamingJournal = File(delegate.streamingJournalPath);
    expect(
      streamingJournal.existsSync(),
      isTrue,
      reason: 'Streaming journal should remain after the fatal crash.',
    );
    final Uint8List streamingSnapshot = Uint8List.fromList(
      await streamingJournal.readAsBytes(),
    );
    expect(streamingSnapshot, isNotEmpty);

    final List<File> archivesBeforeRestart = delegate.rootArchives();
    expect(archivesBeforeRestart, isNotEmpty);

    // Clean up the active transport as if the process exited, but keep the mirror.
    await shutdownFileLogging();
    await Uyava.shutdownTransports();
    await tester.pump();

    final File streamingAfterShutdown = File(delegate.streamingJournalPath);
    if (streamingAfterShutdown.existsSync()) {
      try {
        await streamingAfterShutdown.delete();
      } catch (_) {}
    }
    await streamingAfterShutdown.writeAsBytes(streamingSnapshot, flush: true);

    setUyavaFileLoggerTestOverrides(
      const UyavaFileLoggerTestOverrides(useSynchronousWorker: true),
    );
    final UyavaFileTransport restarted = await UyavaFileTransport.start(
      config: workspace.config,
    );
    setUyavaFileLoggerTestOverrides(null);

    addTearDown(() async {
      await restarted.dispose();
    });

    await restarted.flush();
    await tester.pump(const Duration(milliseconds: 100));

    final File streamingAfterRestart = File(delegate.streamingJournalPath);
    expect(
      streamingAfterRestart.existsSync(),
      isTrue,
      reason: 'Recovery opens a new streaming journal after restore.',
    );

    final int recoveredLength = streamingAfterRestart.lengthSync();
    expect(
      recoveredLength,
      lessThan(streamingSnapshot.length),
      reason:
          'The new streaming journal should be fresh (header only), so it must '
          'be smaller than the archived snapshot.',
    );

    await tester.runAsync(() async {
      final List<String> streamingLines = await delegate
          .readStreamingJournalLines();
      expect(
        streamingLines.length,
        equals(1),
        reason:
            'The new streaming journal should contain only the sessionHeader.',
      );
      expect(streamingLines.first, contains('"type":"sessionHeader"'));
    });

    final List<File> archivesAfterRestart = delegate.rootArchives();
    expect(
      archivesAfterRestart.length,
      greaterThanOrEqualTo(archivesBeforeRestart.length),
    );

    File? recovered;
    for (final File candidate in archivesAfterRestart.reversed) {
      if (candidate.path.contains('recovered')) {
        recovered = candidate;
        break;
      }
    }
    expect(
      recovered,
      isNotNull,
      reason: 'Expected a recovered archive after restart.',
    );

    final List<String> recoveredLines = await _readArchiveLines(recovered!);
    expect(
      recoveredLines.any(
        (String line) =>
            line.contains('Crash Flutter error for Uyava panic-tail demo'),
      ),
      isTrue,
      reason: 'Recovered archive must contain the panic-tail record.',
    );
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxTicks = 80,
  Duration interval = const Duration(milliseconds: 100),
}) async {
  for (int i = 0; i < maxTicks; i++) {
    if (condition()) {
      return;
    }
    await tester.pump(interval);
  }
  fail('Condition was not met within the allotted time.');
}

Future<List<String>> _readArchiveLines(File archive) async {
  final List<int> bytes = await archive.readAsBytes();
  final List<int> decompressed = GZipCodec().decoder.convert(bytes);
  final String content = utf8.decode(decompressed);
  return content
      .split('\n')
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .toList(growable: false);
}

Future<List<String>> _waitForMirror(
  TestFileSystemDelegate delegate, {
  Duration timeout = const Duration(seconds: 3),
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  List<String> lines = <String>[];
  while (stopwatch.elapsed < timeout) {
    lines = await delegate.readPanicMirrorLines();
    if (lines.isNotEmpty) {
      return lines;
    }
    await Future<void>.delayed(pollInterval);
  }
  return lines;
}
