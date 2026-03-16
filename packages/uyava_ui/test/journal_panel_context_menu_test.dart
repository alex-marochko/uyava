import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UyavaGraphJournalPanel context menu', () {
    late GraphController controller;
    late GraphJournalController journal;

    setUp(() {
      controller = GraphController(engine: GridLayout());
      journal = GraphJournalController(graphController: controller);
      controller.replaceGraph({
        'nodes': [
          {'id': 'nodeA', 'label': 'Node A'},
        ],
        'edges': const <Map<String, Object?>>[],
      }, const Size2D(400, 240));
    });

    tearDown(() {
      journal.dispose();
      controller.dispose();
    });

    testWidgets('copy entry copies payload to clipboard', (tester) async {
      String? copied;
      final defaultBinaryMessenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        methodCall,
      ) async {
        if (methodCall.method == 'Clipboard.setData') {
          copied = methodCall.arguments['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      journal.addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'nodeA',
          message: 'hello clipboard',
          timestamp: DateTime.utc(2024, 5, 1),
          severity: UyavaSeverity.info,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder eventTile = find.text('nodeA');
      expect(eventTile, findsOneWidget);

      await tester.tap(eventTile, buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy entry'));
      await tester.pumpAndSettle();

      expect(copied, isNotNull);
      expect(copied, contains('hello clipboard'));
    });

    testWidgets('focus action triggers callback', (tester) async {
      GraphJournalLinkTarget? tappedTarget;

      journal.addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'nodeA',
          message: 'focus me',
          timestamp: DateTime.utc(2024, 5, 1),
          severity: UyavaSeverity.info,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              onLinkTap: (target) => tappedTarget = target,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder eventTile = find.text('nodeA');
      await tester.tap(eventTile, buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Focus on graph'));
      await tester.pumpAndSettle();

      expect(tappedTarget, isA<GraphJournalNodeLink>());
      final GraphJournalNodeLink nodeLink =
          tappedTarget! as GraphJournalNodeLink;
      expect(nodeLink.nodeId, equals('nodeA'));
    });

    testWidgets('open in IDE action uses sourceRef', (tester) async {
      String? openedRef;

      journal.addNodeEvent(
        UyavaNodeEvent(
          nodeId: 'nodeA',
          message: 'open source',
          timestamp: DateTime.utc(2024, 5, 1),
          severity: UyavaSeverity.info,
          sourceRef: 'package:app/main.dart:10:5',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UyavaGraphJournalPanel(
              controller: journal,
              graphController: controller,
              focusState: GraphFocusState.empty,
              onOpenInIde: (sourceRef) async {
                openedRef = sourceRef;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder eventTile = find.text('nodeA');
      await tester.tap(eventTile, buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      expect(find.text('Open in IDE…'), findsOneWidget);
      await tester.tap(find.text('Open in IDE…'));
      await tester.pumpAndSettle();

      expect(openedRef, equals('package:app/main.dart:10:5'));
    });
  });
}
