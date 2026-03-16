import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava/uyava.dart';
import 'package:uyava_example/main.dart';

import 'support/fake_simulation_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Uyava.initialize();
  });

  setUp(() {
    Uyava.resetStateForTesting();
  });

  tearDown(() async {
    Uyava.postEventObserver = null;
    await Uyava.shutdownTransports();
  });

  testWidgets('Start button drives simulation and Stop halts it', (
    WidgetTester tester,
  ) async {
    final FakeSimulationController simulationController =
        FakeSimulationController();
    final List<String> eventTypes = <String>[];
    Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
      if (type == UyavaEventTypes.edgeEvent ||
          type == UyavaEventTypes.nodeEvent) {
        eventTypes.add(type);
      }
    };

    await tester.pumpWidget(
      ExampleApp(
        overrides: ExampleAppOverrides(
          simulationController: simulationController,
          random: math.Random(1),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openTab(tester, 'Features');

    final Finder startButton = find.byKey(
      const ValueKey<String>('start-simulation-button'),
    );
    final Finder stopButton = find.byKey(
      const ValueKey<String>('stop-simulation-button'),
    );
    expect(startButton, findsOneWidget);
    expect(stopButton, findsOneWidget);
    await tester.ensureVisible(startButton);
    await tester.pump();

    expect(tester.widget<ElevatedButton>(startButton).onPressed, isNotNull);
    expect(tester.widget<ElevatedButton>(stopButton).onPressed, isNull);

    await tester.tap(startButton);
    await tester.pump();

    expect(simulationController.startCount, 1);
    expect(
      simulationController.lastInterval,
      const Duration(milliseconds: 500),
    );
    expect(tester.widget<ElevatedButton>(startButton).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(stopButton).onPressed, isNotNull);

    simulationController.tick();
    simulationController.tick();

    expect(
      eventTypes.where((type) => type == UyavaEventTypes.edgeEvent).length,
      greaterThan(0),
    );
    expect(
      eventTypes.where((type) => type == UyavaEventTypes.nodeEvent).length,
      greaterThan(0),
    );

    await tester.ensureVisible(stopButton);
    await tester.pump();

    await tester.tap(stopButton);
    await tester.pump();

    expect(simulationController.stopCount, 1);
    final int recordedEvents = eventTypes.length;

    simulationController.tick();
    expect(eventTypes.length, recordedEvents);
    expect(tester.widget<ElevatedButton>(startButton).onPressed, isNotNull);
    expect(tester.widget<ElevatedButton>(stopButton).onPressed, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final Finder tab = find.widgetWithText(Tab, label);
  expect(tab, findsOneWidget);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}
