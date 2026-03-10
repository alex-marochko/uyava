import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

Future<GraphController> _createControllerWithChain() async {
  final GraphController controller = GraphController(engine: GridLayout());
  controller.replaceGraph(<String, dynamic>{
    'nodes': <Map<String, Object?>>[
      {'id': 'nodeA', 'label': 'Node A'},
      {'id': 'nodeB', 'label': 'Node B'},
    ],
    'edges': const <Map<String, Object?>>[],
  }, const Size2D(800, 600));

  controller.registerEventChainDefinition(<String, Object?>{
    'id': 'login_flow',
    'label': 'Login Flow',
    'description': 'Happy path for login',
    'tags': <String>['Chain', 'Auth'],
    'steps': const <Map<String, Object?>>[
      {'stepId': 'start', 'nodeId': 'nodeA'},
      {'stepId': 'finish', 'nodeId': 'nodeB'},
    ],
  });

  controller.recordEventChainProgress(
    nodeId: 'nodeA',
    chain: <String, Object?>{'id': 'login_flow', 'step': 'start'},
  );

  return controller;
}

Future<GraphController> _createControllerWithoutAttempts() async {
  final GraphController controller = GraphController(engine: GridLayout());
  controller.replaceGraph(<String, dynamic>{
    'nodes': <Map<String, Object?>>[
      {'id': 'nodeA', 'label': 'Node A'},
      {'id': 'nodeB', 'label': 'Node B'},
    ],
    'edges': const <Map<String, Object?>>[],
  }, const Size2D(800, 600));

  controller.registerEventChainDefinition(<String, Object?>{
    'id': 'login_flow',
    'label': 'Login Flow',
    'description': 'Happy path for login',
    'tags': const <String>['Chain', 'Auth'],
    'steps': const <Map<String, Object?>>[
      {'stepId': 'start', 'nodeId': 'nodeA'},
      {'stepId': 'finish', 'nodeId': 'nodeB'},
    ],
  });

  return controller;
}

Future<GraphController> _createControllerWithMultipleChains() async {
  final GraphController controller = GraphController(engine: GridLayout());
  controller.replaceGraph(<String, dynamic>{
    'nodes': <Map<String, Object?>>[
      {'id': 'nodeA', 'label': 'Node A'},
      {'id': 'nodeB', 'label': 'Node B'},
      {'id': 'nodeC', 'label': 'Node C'},
    ],
    'edges': const <Map<String, Object?>>[],
  }, const Size2D(800, 600));

  controller.registerEventChainDefinition(<String, Object?>{
    'id': 'login_flow',
    'label': 'Login Flow',
    'description': 'Happy path for login',
    'tags': const <String>['Chain', 'Auth'],
    'steps': const <Map<String, Object?>>[
      {'stepId': 'start', 'nodeId': 'nodeA'},
      {'stepId': 'finish', 'nodeId': 'nodeB'},
    ],
  });

  controller.registerEventChainDefinition(<String, Object?>{
    'id': 'checkout_flow',
    'label': 'Checkout Flow',
    'description': 'Checkout sequence',
    'tags': const <String>['Chain', 'Checkout'],
    'steps': const <Map<String, Object?>>[
      {'stepId': 'cart', 'nodeId': 'nodeB'},
      {'stepId': 'pay', 'nodeId': 'nodeC'},
    ],
  });

  return controller;
}

TextSpan _chainSummarySpan(WidgetTester tester, String chainId) {
  final ValueKey<String> key = ValueKey<String>('chain-summary-$chainId');
  final Iterable<RichText> summaries = tester
      .widgetList<RichText>(find.byType(RichText))
      .where((RichText text) => text.key == key);
  final RichText summary = summaries.single;
  return summary.text as TextSpan;
}

String _chainSummaryText(WidgetTester tester, String chainId) {
  return _chainSummarySpan(tester, chainId).toPlainText();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UyavaEventChainsPanel renders chain summary and details', (
    WidgetTester tester,
  ) async {
    final GraphController controller = await _createControllerWithChain();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UyavaEventChainsPanel(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login Flow'), findsWidgets);
    expect(find.text('login_flow'), findsWidgets);
    expect(find.text('Chain'), findsNothing);
    expect(find.text('Auth'), findsNothing);
    expect(
      _chainSummaryText(tester, 'login_flow'),
      'Success 0 · Fail 0 · Active 1',
    );
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('1. start'), findsNothing);
    expect(find.text('2. finish'), findsNothing);

    await tester.tap(find.text('Login Flow').first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, '1'), findsOneWidget);

    expect(find.text('1. start'), findsOneWidget);
    expect(find.text('2. finish'), findsOneWidget);
    expect(find.text('Chain'), findsWidgets);
    expect(find.text('Auth'), findsWidgets);
  });

  testWidgets('Chain summary highlights non-zero counts with colors', (
    WidgetTester tester,
  ) async {
    final GraphController controller = await _createControllerWithoutAttempts();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UyavaEventChainsPanel(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    TextSpan zeroRoot = _chainSummarySpan(tester, 'login_flow');
    List<InlineSpan> zeroSpans = zeroRoot.children!;
    expect((zeroSpans[0] as TextSpan).style, isNull);
    expect((zeroSpans[2] as TextSpan).style, isNull);
    expect((zeroSpans[4] as TextSpan).style, isNull);

    controller.recordEventChainProgress(
      nodeId: 'nodeA',
      chain: <String, Object?>{'id': 'login_flow', 'step': 'start'},
    );
    await tester.pumpAndSettle();

    controller.recordEventChainProgress(
      nodeId: 'nodeB',
      chain: <String, Object?>{'id': 'login_flow', 'step': 'finish'},
    );
    await tester.pumpAndSettle();

    controller.recordEventChainProgress(
      nodeId: 'nodeB',
      chain: <String, Object?>{'id': 'login_flow', 'step': 'finish'},
    );
    await tester.pumpAndSettle();

    controller.recordEventChainProgress(
      nodeId: 'nodeA',
      chain: <String, Object?>{'id': 'login_flow', 'step': 'start'},
    );
    await tester.pumpAndSettle();

    final TextSpan highlightedRoot = _chainSummarySpan(tester, 'login_flow');
    final List<InlineSpan> highlightedSpans = highlightedRoot.children!;
    expect(
      (highlightedSpans[0] as TextSpan).style?.color,
      const Color(0xFF2E7D32),
    );
    expect(
      (highlightedSpans[2] as TextSpan).style?.color,
      const Color(0xFFC62828),
    );
    expect(
      (highlightedSpans[4] as TextSpan).style?.color,
      const Color(0xFFF9A825),
    );

    controller.resetEventChain('login_flow');
    await tester.pumpAndSettle();

    final TextSpan resetRoot = _chainSummarySpan(tester, 'login_flow');
    zeroSpans = resetRoot.children!;
    expect((zeroSpans[0] as TextSpan).style, isNull);
    expect((zeroSpans[2] as TextSpan).style, isNull);
    expect((zeroSpans[4] as TextSpan).style, isNull);
  });

  testWidgets('Pinned chains render first and persist pin state', (
    WidgetTester tester,
  ) async {
    final GraphController controller =
        await _createControllerWithMultipleChains();
    addTearDown(controller.dispose);

    Set<String> latestPins = const <String>{};

    await tester.pumpWidget(
      MaterialApp(
        home: UyavaEventChainsPanel(
          controller: controller,
          pinnedChains: const <String>{'checkout_flow'},
          onPinnedChainsChanged: (Set<String> pins) {
            latestPins = pins;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Offset checkoutOffset = tester.getTopLeft(
      find.byKey(const ValueKey('chain-tile-checkout_flow')),
    );
    final Offset loginOffset = tester.getTopLeft(
      find.byKey(const ValueKey('chain-tile-login_flow')),
    );
    expect(checkoutOffset.dy, lessThan(loginOffset.dy));

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('chain-tile-checkout_flow')),
        matching: find.byTooltip('Unpin chain'),
      ),
    );
    await tester.pumpAndSettle();

    expect(latestPins.contains('checkout_flow'), isFalse);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('chain-tile-login_flow')),
        matching: find.byTooltip('Pin chain'),
      ),
    );
    await tester.pumpAndSettle();

    expect(latestPins.contains('login_flow'), isTrue);
  });

  testWidgets('Chains stay collapsed/expanded based on user interaction only', (
    WidgetTester tester,
  ) async {
    final GraphController controller = await _createControllerWithChain();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UyavaEventChainsPanel(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. start'), findsNothing);

    controller.recordEventChainProgress(
      nodeId: 'nodeB',
      chain: <String, Object?>{'id': 'login_flow', 'step': 'finish'},
    );
    await tester.pumpAndSettle();

    expect(find.text('1. start'), findsNothing);

    await tester.tap(find.text('Login Flow').first);
    await tester.pumpAndSettle();

    expect(find.text('1. start'), findsOneWidget);

    controller.recordEventChainProgress(
      nodeId: 'nodeA',
      chain: <String, Object?>{'id': 'login_flow', 'step': 'start'},
    );
    await tester.pumpAndSettle();

    expect(find.text('1. start'), findsOneWidget);
  });

  testWidgets('UyavaEventChainsPanel shows placeholder when empty', (
    WidgetTester tester,
  ) async {
    final GraphController controller = GraphController(engine: GridLayout());
    addTearDown(controller.dispose);

    controller.replaceGraph(<String, dynamic>{
      'nodes': const <Map<String, Object?>>[],
      'edges': const <Map<String, Object?>>[],
    }, const Size2D(800, 600));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UyavaEventChainsPanel(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No event chains'), findsOneWidget);
  });

  testWidgets('Active attempts render as chips with placeholder card', (
    WidgetTester tester,
  ) async {
    final GraphController controller = await _createControllerWithoutAttempts();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UyavaEventChainsPanel(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login Flow').first);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((Widget widget) => widget is Wrap),
      findsWidgets,
    );
    expect(find.byType(ChoiceChip), findsNothing);

    expect(find.text('No active attempts'), findsOneWidget);

    expect(find.byType(Chip), findsOneWidget);
  });

  testWidgets('Reset button clears chain statistics', (
    WidgetTester tester,
  ) async {
    final GraphController controller = await _createControllerWithChain();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UyavaEventChainsPanel(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Reset chain statistics'), findsOneWidget);
    expect(
      _chainSummaryText(tester, 'login_flow'),
      'Success 0 · Fail 0 · Active 1',
    );

    await tester.tap(find.byTooltip('Reset chain statistics'));
    await tester.pumpAndSettle();

    expect(
      _chainSummaryText(tester, 'login_flow'),
      'Success 0 · Fail 0 · Active 0',
    );
  });

  testWidgets('Reset all clears chain statistics', (WidgetTester tester) async {
    final GraphController controller = await _createControllerWithChain();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UyavaEventChainsPanel(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reset all'), findsOneWidget);
    expect(
      _chainSummaryText(tester, 'login_flow'),
      'Success 0 · Fail 0 · Active 1',
    );

    await tester.tap(find.text('Reset all'));
    await tester.pumpAndSettle();

    expect(
      _chainSummaryText(tester, 'login_flow'),
      'Success 0 · Fail 0 · Active 0',
    );
  });
}
