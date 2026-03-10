import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:uyava/uyava.dart';
import 'package:uyava_example/main.dart' as app;
import 'package:uyava_example/src/file_logging.dart';

import 'support/temp_logging_workspace.dart';
import 'support/test_file_system_delegate.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final _FakeSharePlatform fakeSharePlatform = _FakeSharePlatform();
  late SharePlatform previousSharePlatform;

  setUp(() {
    previousSharePlatform = SharePlatform.instance;
    fakeSharePlatform.reset();
    SharePlatform.instance = fakeSharePlatform;
  });

  tearDown(() {
    SharePlatform.instance = previousSharePlatform;
  });

  testWidgets(
    'exporting a panic-tail archive updates live stream and filesystem',
    (WidgetTester tester) async {
      final FlutterExceptionHandler? originalFlutterError =
          FlutterError.onError;
      final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
      final originalPlatformOnError = dispatcher.onError;

      setUyavaFileLoggerTestOverrides(
        const UyavaFileLoggerTestOverrides(useSynchronousWorker: true),
      );
      await app.main();
      setUyavaFileLoggerTestOverrides(null);

      dispatcher.onError = originalPlatformOnError;
      FlutterError.onError = originalFlutterError;

      addTearDown(() {
        FlutterError.onError = originalFlutterError;
        dispatcher.onError = originalPlatformOnError;
      });

      await tester.pump();
      await _pumpUntil(
        tester,
        () => find.text('Wrong data').evaluate().isNotEmpty,
      );

      final UyavaFileTransport? transport = currentFileTransport();
      expect(transport, isNotNull, reason: 'File transport is not available.');

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
      await tester.pump();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      await logSyntheticRuntimeError(
        source: 'integration_test',
        error: StateError('Integration test panic-tail sample'),
        stackTrace: StackTrace.current,
        context: const {'scenario': 'ui-export-flow'},
      );
      await tester.pump(const Duration(milliseconds: 250));

      await tester.runAsync(() async {
        await _waitForRootArchive(
          delegate,
          timeout: const Duration(seconds: 10),
        );
      });

      final Finder exportButton = find.text('Send log via email');
      await _ensureVisible(tester, exportButton);
      expect(exportButton, findsWidgets);
      await tester.tap(exportButton.first);
      await tester.pump();

      final int initialExportCount = delegate.exportedArchives().length;
      File? exportedViaPolling;
      const Duration waitTimeout = Duration(seconds: 20);

      await tester.runAsync(() async {
        await Future.any(<Future<void>>[
          fakeSharePlatform.waitForShareXFiles(timeout: waitTimeout),
          _waitForExportedArchive(
            delegate,
            initialExportCount,
            timeout: waitTimeout,
          ).then((File file) {
            exportedViaPolling = file;
          }),
        ]);
      });
      await tester.pump();

      File sharedFile;
      if (fakeSharePlatform.shareXFilesCalls.isNotEmpty) {
        final _ShareXFilesCall shareCall =
            fakeSharePlatform.shareXFilesCalls.last;
        final XFile sharedXFile = shareCall.files.single;
        sharedFile = File(sharedXFile.path);
      } else {
        expect(
          exportedViaPolling,
          isNotNull,
          reason:
              'Archive did not appear in exports/, and shareXFiles was not called.',
        );
        sharedFile = exportedViaPolling!;
      }
      expect(sharedFile.existsSync(), isTrue);

      await _pumpUntil(
        tester,
        () => delegate.exportedArchives().any(
          (File file) => file.path == sharedFile.path,
        ),
      );

      final List<File> exportedArchives = delegate.exportedArchives();
      expect(exportedArchives, isNotEmpty);
      expect(
        exportedArchives.any((File file) => file.path == sharedFile.path),
        isTrue,
      );

      final List<File> rootArchives = delegate.rootArchives();
      expect(rootArchives, isNotEmpty);

      final String fileName = sharedFile.uri.pathSegments.last;
      await _pumpUntil(
        tester,
        () => find.textContaining(fileName).evaluate().isNotEmpty,
      );

      expect(find.textContaining('Exported archive'), findsWidgets);
    },
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxTicks = 120,
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

Future<void> _ensureVisible(WidgetTester tester, Finder finder) async {
  final Finder scrollable = find.descendant(
    of: find.byKey(const ValueKey('wrong-data-list')),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
  await tester.pumpAndSettle();
}

Future<File> _waitForExportedArchive(
  TestFileSystemDelegate delegate,
  int existingCount, {
  required Duration timeout,
  Duration pollInterval = const Duration(milliseconds: 150),
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    final List<File> exports = delegate.exportedArchives();
    if (exports.length > existingCount) {
      return exports.last;
    }
    await Future<void>.delayed(pollInterval);
  }
  throw TimeoutException(
    'No exported archive detected within ${timeout.inSeconds}s.',
    timeout,
  );
}

Future<void> _waitForRootArchive(
  TestFileSystemDelegate delegate, {
  required Duration timeout,
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (delegate.rootArchives().isNotEmpty) {
      return;
    }
    await Future<void>.delayed(pollInterval);
  }
  throw TimeoutException(
    'No root archive created within ${timeout.inSeconds}s.',
    timeout,
  );
}

class _ShareXFilesCall {
  _ShareXFilesCall({required this.files, this.text, this.subject, this.origin});

  final List<XFile> files;
  final String? text;
  final String? subject;
  final ui.Rect? origin;
}

class _FakeSharePlatform extends SharePlatform {
  _FakeSharePlatform() : _shareXFilesCompleter = Completer<void>();

  final List<_ShareXFilesCall> shareXFilesCalls = <_ShareXFilesCall>[];
  Completer<void> _shareXFilesCompleter;

  void reset() {
    shareXFilesCalls.clear();
    _shareXFilesCompleter = Completer<void>();
  }

  Future<void> waitForShareXFiles({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return _shareXFilesCompleter.future.timeout(timeout);
  }

  @override
  Future<void> share(
    String text, {
    String? subject,
    ui.Rect? sharePositionOrigin,
  }) async {}

  @override
  Future<void> shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    ui.Rect? sharePositionOrigin,
  }) async {}

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
    ui.Rect? sharePositionOrigin,
  }) async {
    shareXFilesCalls.add(
      _ShareXFilesCall(
        files: List<XFile>.from(files),
        text: text,
        subject: subject,
        origin: sharePositionOrigin,
      ),
    );
    if (!_shareXFilesCompleter.isCompleted) {
      _shareXFilesCompleter.complete();
    }
    return const ShareResult('fake-share-xfiles', ShareResultStatus.success);
  }

  @override
  Future<void> shareUri(Uri uri, {ui.Rect? sharePositionOrigin}) async {}
}
