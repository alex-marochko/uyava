import 'dart:async';
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

  testWidgets(
    'cloning the active log surfaces discard stats and archive events',
    (WidgetTester tester) async {
      final FlutterExceptionHandler? originalFlutterError =
          FlutterError.onError;
      final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
      final bool Function(Object, StackTrace)? originalPlatformOnError =
          dispatcher.onError;

      setUyavaFileLoggerTestOverrides(
        const UyavaFileLoggerTestOverrides(useSynchronousWorker: true),
      );
      await app.main();
      setUyavaFileLoggerTestOverrides(null);

      dispatcher.onError = originalPlatformOnError;
      FlutterError.onError = originalFlutterError;

      addTearDown(() {
        UyavaBootstrap.removeGlobalErrorHandlers();
        dispatcher.onError = originalPlatformOnError;
        FlutterError.onError = originalFlutterError;
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

      await tester.runAsync(() async {
        await _waitForRootArchive(
          delegate,
          timeout: const Duration(seconds: 10),
        );
      });

      await _openTab(tester, 'Wrong data');
      await _ensureVisible(
        tester,
        find.text('Dropped events (discard stats stream)'),
      );
      await _setMinLogLevel(tester, UyavaSeverity.error);
      _restoreErrorHandlers(
        dispatcher: dispatcher,
        originalFlutterError: originalFlutterError,
        originalPlatformOnError: originalPlatformOnError,
      );

      await tester.runAsync(() async {
        expect(currentMinLogLevel(), UyavaSeverity.error);
      });

      await _openTab(tester, 'Targeted Events');
      await _setTargetedSeverity(tester, 'info');
      await _emitEdgePulses(tester, count: 6);

      await _openTab(tester, 'Wrong data');
      await _ensureVisible(
        tester,
        find.text('Dropped events (discard stats stream)'),
      );

      await _pumpUntil(
        tester,
        () => _hasNonZeroDropCount(),
        timeout: const Duration(seconds: 10),
      );

      expect(
        find.textContaining('Last reason: severity_min_level'),
        findsOneWidget,
      );
      expect(find.textContaining('- severity_min_level:'), findsOneWidget);

      final int exportsBefore = delegate.exportedArchives().length;

      await _ensureVisible(
        tester,
        find.text('Panic-tail archives and live log'),
      );
      final Finder cloneButton = find.widgetWithText(
        ElevatedButton,
        'Clone active log',
      );
      expect(cloneButton, findsOneWidget);
      await tester.tap(cloneButton);
      await tester.pump();

      await _pumpUntil(
        tester,
        () => find.text('Cloning...').evaluate().isEmpty,
        timeout: const Duration(seconds: 10),
      );

      File clonedArchive = File('');
      await tester.runAsync(() async {
        clonedArchive = await _waitForExportedArchive(
          delegate,
          exportsBefore,
          timeout: const Duration(seconds: 10),
        );
      });
      expect(clonedArchive.existsSync(), isTrue);
      final String cloneName = clonedArchive.uri.pathSegments.last;

      await _pumpUntil(
        tester,
        () => find.textContaining('Active archive clone').evaluate().isNotEmpty,
      );
      await _pumpUntil(
        tester,
        () => find.textContaining(cloneName).evaluate().isNotEmpty,
      );
    },
  );
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final Finder tab = find.widgetWithText(Tab, label);
  expect(tab, findsOneWidget);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void _restoreErrorHandlers({
  required ui.PlatformDispatcher dispatcher,
  FlutterExceptionHandler? originalFlutterError,
  bool Function(Object, StackTrace)? originalPlatformOnError,
}) {
  UyavaBootstrap.removeGlobalErrorHandlers();
  dispatcher.onError = originalPlatformOnError;
  FlutterError.onError = originalFlutterError;
}

Future<void> _ensureVisible(WidgetTester tester, Finder finder) async {
  final Finder scrollable = find.descendant(
    of: find.byKey(const ValueKey('wrong-data-list')),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
  await tester.pumpAndSettle();
}

Future<void> _setMinLogLevel(WidgetTester tester, UyavaSeverity target) async {
  final Finder dropdown = find.byWidgetPredicate(
    (Widget widget) => widget is DropdownButton<UyavaSeverity>,
  );
  expect(dropdown, findsOneWidget);

  await tester.ensureVisible(dropdown);
  final DropdownButton<UyavaSeverity> button = tester
      .widget<DropdownButton<UyavaSeverity>>(dropdown);
  if (button.value == target) {
    return;
  }

  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  final Finder option = find.text(_severityLabel(target)).last;
  await tester.tap(option);
  await tester.pump();

  await _pumpUntil(
    tester,
    () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
    timeout: const Duration(seconds: 5),
  );
}

Future<void> _setTargetedSeverity(WidgetTester tester, String target) async {
  final Finder dropdown = find.byWidgetPredicate((Widget widget) {
    if (widget is! DropdownButton<String>) {
      return false;
    }
    final List<DropdownMenuItem<String>>? items = widget.items;
    if (items == null || items.length != 6) {
      return false;
    }
    final List<String> labels = items
        .map((DropdownMenuItem<String> item) {
          final Widget child = item.child;
          return child is Text ? child.data : null;
        })
        .whereType<String>()
        .toList();
    return const [
      'trace',
      'debug',
      'info',
      'warn',
      'error',
      'fatal',
    ].every(labels.contains);
  });

  expect(dropdown, findsOneWidget);
  await tester.ensureVisible(dropdown);
  final DropdownButton<String> button = tester.widget<DropdownButton<String>>(
    dropdown,
  );
  if (button.value == target) {
    return;
  }

  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(target).last);
  await tester.pump();
}

Future<void> _emitEdgePulses(WidgetTester tester, {required int count}) async {
  final Finder button = find.byKey(const ValueKey('emit-edge-event-button'));
  expect(button, findsOneWidget);
  await tester.ensureVisible(button);
  expect(
    tester.widget<ElevatedButton>(button).onPressed,
    isNotNull,
    reason: 'Emit Edge Event button must stay enabled.',
  );

  for (int i = 0; i < count; i++) {
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration interval = const Duration(milliseconds: 100),
  Duration timeout = const Duration(seconds: 5),
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (condition()) {
      return;
    }
    await tester.pump(interval);
  }
  fail('Condition was not met within ${timeout.inSeconds}s.');
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
    'No cloned archive detected within ${timeout.inSeconds}s.',
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
    'Active archive was not created within ${timeout.inSeconds}s.',
    timeout,
  );
}

bool _hasNonZeroDropCount() {
  final Iterable<Element> matches = find
      .textContaining('Total drops:')
      .evaluate();
  for (final Element element in matches) {
    final Widget widget = element.widget;
    if (widget is! Text) {
      continue;
    }
    final String? data = widget.data;
    if (data == null) {
      continue;
    }
    final RegExpMatch? match = RegExp(r'Total drops:\s*(\d+)').firstMatch(data);
    if (match == null) {
      continue;
    }
    final int value = int.tryParse(match.group(1) ?? '') ?? 0;
    if (value > 0) {
      return true;
    }
  }
  return false;
}

String _severityLabel(UyavaSeverity severity) {
  switch (severity) {
    case UyavaSeverity.trace:
      return 'trace — tracing';
    case UyavaSeverity.debug:
      return 'debug — debugging';
    case UyavaSeverity.info:
      return 'info — informational';
    case UyavaSeverity.warn:
      return 'warn — warning';
    case UyavaSeverity.error:
      return 'error — error state';
    case UyavaSeverity.fatal:
      return 'fatal — critical';
  }
}
