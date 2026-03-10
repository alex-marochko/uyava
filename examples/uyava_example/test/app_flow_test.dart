import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava/uyava.dart';

import 'package:uyava_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Uyava.initialize();
  });

  setUp(() {
    Uyava.resetStateForTesting();
    Uyava.postEventObserver = null;
  });

  tearDown(() async {
    Uyava.postEventObserver = null;
    await Uyava.shutdownTransports();
  });

  testWidgets(
    'registers a metric and emits a typed sample with payload metadata',
    (WidgetTester tester) async {
      _configureTestViewport(tester);
      await tester.pumpWidget(
        const ExampleApp(
          overrides: ExampleAppOverrides(chainStepDelay: Duration.zero),
        ),
      );
      await tester.pumpAndSettle();

      await _openTab(tester, 'Metrics');

      final List<Map<String, dynamic>> metricDefinitions =
          <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> metricSamples = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(payload);
        if (type == UyavaEventTypes.defineMetric) {
          metricDefinitions.add(copy);
        } else if (type == UyavaEventTypes.nodeEvent) {
          metricSamples.add(copy);
        }
      };

      await tester.enterText(
        find.bySemanticsLabel('Metric id').at(0),
        'latency_demo',
      );
      await tester.enterText(
        find.bySemanticsLabel('Label (optional)'),
        'Latency Demo',
      );
      await tester.enterText(
        find.bySemanticsLabel('Description (optional)'),
        'Round-trip latency',
      );
      await tester.enterText(find.bySemanticsLabel('Unit (optional)'), 'ms');
      await tester.enterText(
        find.bySemanticsLabel('Tags (comma separated)'),
        'demo, perf',
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Sum'));
      await tester.pumpAndSettle();

      final Finder metricsScrollCandidates = find.descendant(
        of: find.byKey(const ValueKey('metrics-list')),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down &&
              widget.restorationId == null,
        ),
      );
      expect(metricsScrollCandidates, findsWidgets);
      final Finder metricsScroll = metricsScrollCandidates.first;
      final Finder registerButton = find.byKey(
        const ValueKey('register-metric-button'),
      );
      expect(registerButton, findsOneWidget);
      await tester.dragUntilVisible(
        registerButton,
        metricsScroll,
        const Offset(0, -300),
      );
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(metricDefinitions, hasLength(1));
      final Map<String, dynamic> definition = metricDefinitions.single;
      expect(definition['id'], 'latency_demo');
      expect(definition['label'], 'Latency Demo');
      expect(definition['unit'], 'ms');
      expect(
        definition['tagsNormalized'],
        containsAll(<String>['demo', 'perf']),
      );
      expect(
        definition['aggregators'],
        containsAll(<String>['last', 'min', 'max', 'sum']),
      );
      expect(find.textContaining('Registered metrics'), findsOneWidget);
      expect(find.textContaining('Latency Demo'), findsWidgets);

      await tester.enterText(
        find.bySemanticsLabel('Metric id').at(1),
        'latency_demo',
      );
      await tester.enterText(find.bySemanticsLabel('Metric value'), '42.5');

      final Finder sendButton = find.byKey(
        const ValueKey('send-metric-sample-button'),
      );
      expect(sendButton, findsOneWidget);
      await tester.dragUntilVisible(
        sendButton,
        metricsScroll,
        const Offset(0, -300),
      );
      await tester.tap(sendButton);
      await tester.pump();

      expect(metricSamples, hasLength(1));
      final Map<String, dynamic> sample = metricSamples.single;
      expect(sample['nodeId'], isNotEmpty);
      expect(sample['severity'], anyOf('info', isNull));
      expect(sample['message'], contains('latency_demo'));
      final Map<String, dynamic> payload =
          sample['payload'] as Map<String, dynamic>;
      final Map<String, dynamic> metric =
          payload['metric'] as Map<String, dynamic>;
      expect(metric['id'], 'latency_demo');
      expect(metric['value'], 42.5);
      expect(metric['severity'], anyOf('info', isNull));
    },
  );

  testWidgets('simulates the login event chain and records ordered steps', (
    WidgetTester tester,
  ) async {
    _configureTestViewport(tester);
    await tester.pumpWidget(
      const ExampleApp(
        overrides: ExampleAppOverrides(chainStepDelay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    await _openTab(tester, 'Event Chains');

    final List<Map<String, dynamic>> chainEvents = <Map<String, dynamic>>[];
    Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
      if (type == UyavaEventTypes.nodeEvent) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(payload);
        final Map<String, dynamic>? payloadMap =
            copy['payload'] as Map<String, dynamic>?;
        if (payloadMap?['chain'] != null) {
          chainEvents.add(copy);
        }
      }
    };

    final Finder simulateSuccess = find.byKey(
      const ValueKey('simulate-login-success-button'),
    );
    expect(simulateSuccess, findsOneWidget);
    expect(tester.widget<OutlinedButton>(simulateSuccess).onPressed, isNotNull);
    await tester.ensureVisible(simulateSuccess);
    await tester.tap(simulateSuccess);
    await tester.pump();

    for (int i = 0; i < 10 && chainEvents.length < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(chainEvents.length, greaterThanOrEqualTo(5));
    final List<String> steps = chainEvents
        .map((Map<String, dynamic> event) {
          final Map<String, dynamic> payload =
              event['payload'] as Map<String, dynamic>;
          final Map<String, dynamic> chain =
              payload['chain'] as Map<String, dynamic>;
          return chain['step'] as String;
        })
        .toList(growable: false);
    expect(steps.take(5).toList(), <String>[
      'tap_button',
      'validate_form',
      'dispatch_auth',
      'persist_session',
      'complete',
    ]);
    final Set<String> attempts = chainEvents.map((Map<String, dynamic> event) {
      final Map<String, dynamic> payload =
          event['payload'] as Map<String, dynamic>;
      final Map<String, dynamic> chain =
          payload['chain'] as Map<String, dynamic>;
      return chain['attempt'] as String;
    }).toSet();
    expect(attempts, hasLength(1));
    expect(attempts.single, startsWith('loginAttempt_'));
    expect(find.textContaining(attempts.single), findsOneWidget);
  });

  testWidgets(
    'emits targeted edge/node events and disables actions when features are off',
    (WidgetTester tester) async {
      _configureTestViewport(tester);
      await tester.pumpWidget(
        const ExampleApp(
          overrides: ExampleAppOverrides(chainStepDelay: Duration.zero),
        ),
      );
      await tester.pumpAndSettle();

      await _openTab(tester, 'Targeted Events');

      final List<Map<String, dynamic>> edgeEvents = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> nodeEvents = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(payload);
        if (type == UyavaEventTypes.edgeEvent) {
          edgeEvents.add(copy);
        } else if (type == UyavaEventTypes.nodeEvent) {
          nodeEvents.add(copy);
        }
      };

      final Finder emitEdgeButton = find.byKey(
        const ValueKey('emit-edge-event-button'),
      );
      expect(emitEdgeButton, findsOneWidget);
      await tester.ensureVisible(emitEdgeButton);
      await tester.tap(emitEdgeButton);
      await tester.pump();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Node'));
      await tester.pumpAndSettle();

      final Finder emitNodeButton = find.byKey(
        const ValueKey('emit-node-event-button'),
      );
      expect(emitNodeButton, findsOneWidget);
      await tester.ensureVisible(emitNodeButton);
      await tester.tap(emitNodeButton);
      await tester.pump();

      expect(edgeEvents, isNotEmpty);
      expect(nodeEvents, isNotEmpty);

      await _openTab(tester, 'Features');
      await tester.tap(find.widgetWithText(SwitchListTile, 'All Features'));
      await tester.pumpAndSettle();

      await _openTab(tester, 'Targeted Events');

      final Finder disabledNodeButton = find.byKey(
        const ValueKey('emit-node-event-button'),
      );
      expect(
        tester.widget<ElevatedButton>(disabledNodeButton).onPressed,
        isNull,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Edge'));
      await tester.pumpAndSettle();

      final Finder disabledEdgeButton = find.byKey(
        const ValueKey('emit-edge-event-button'),
      );
      expect(
        tester.widget<ElevatedButton>(disabledEdgeButton).onPressed,
        isNull,
      );
    },
  );

  testWidgets('courier burst tab emits tracking events and can be stopped', (
    WidgetTester tester,
  ) async {
    _configureTestViewport(tester);
    await tester.pumpWidget(
      const ExampleApp(
        overrides: ExampleAppOverrides(chainStepDelay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();

    await _openTab(tester, 'Courier Burst');

    final List<Map<String, dynamic>> edgeEvents = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> nodeEvents = <Map<String, dynamic>>[];
    Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
      final Map<String, dynamic> copy = Map<String, dynamic>.from(payload);
      if (type == UyavaEventTypes.edgeEvent &&
          (copy['message'] as String?)?.contains('[Courier Burst]') == true) {
        edgeEvents.add(copy);
      }
      if (type == UyavaEventTypes.nodeEvent &&
          (copy['message'] as String?)?.contains('[Courier Burst]') == true) {
        nodeEvents.add(copy);
      }
    };

    final Finder startButton = find.byKey(
      const ValueKey('courier-burst-start-button'),
    );
    final Finder stopButton = find.byKey(
      const ValueKey('courier-burst-stop-button'),
    );
    expect(startButton, findsOneWidget);
    expect(stopButton, findsOneWidget);

    await tester.tap(startButton);
    await tester.pump(const Duration(milliseconds: 650));
    await tester.tap(stopButton);
    await tester.pumpAndSettle();

    expect(edgeEvents, isNotEmpty);
    expect(nodeEvents, isNotEmpty);
    expect(
      nodeEvents.any((Map<String, dynamic> event) {
        final Map<String, dynamic>? payload =
            event['payload'] as Map<String, dynamic>?;
        final Map<String, dynamic>? metric =
            payload?['metric'] as Map<String, dynamic>?;
        final String? id = metric?['id'] as String?;
        return id == 'tracking_gap_seconds' || id == 'eta_drift_seconds';
      }),
      isTrue,
    );
  });

  testWidgets('reset diagnostics publishes replaceGraph and clearDiagnostics', (
    WidgetTester tester,
  ) async {
    _configureTestViewport(tester);
    await tester.pumpWidget(
      const ExampleApp(
        overrides: ExampleAppOverrides(chainStepDelay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();

    await _openTab(tester, 'Wrong data');

    final List<String> diagnosticsEvents = <String>[];
    Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
      if (type == UyavaEventTypes.replaceGraph ||
          type == UyavaEventTypes.clearDiagnostics) {
        diagnosticsEvents.add(type);
      }
    };

    await tester.tap(find.byKey(const ValueKey('reset-diagnostics-button')));
    await tester.pump();

    expect(
      diagnosticsEvents,
      containsAll(<String>[
        UyavaEventTypes.replaceGraph,
        UyavaEventTypes.clearDiagnostics,
      ]),
    );
    expect(
      find.text('File logging is not available on this platform.'),
      findsOneWidget,
    );
  });
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final BuildContext context = tester.element(find.byType(TabBar));
  final TabController controller = DefaultTabController.of(context);
  const List<String> labels = <String>[
    'Features',
    'Metrics',
    'Event Chains',
    'Courier Burst',
    'Targeted Events',
    'Wrong data',
  ];
  final int targetIndex = labels.indexOf(label);
  expect(targetIndex, isNot(-1));
  controller.animateTo(targetIndex);
  await tester.pumpAndSettle();
}

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
