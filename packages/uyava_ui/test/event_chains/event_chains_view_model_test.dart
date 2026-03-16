import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

Future<GraphController> _controllerWithChains() async {
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

  controller.recordEventChainProgress(
    nodeId: 'nodeA',
    chain: <String, Object?>{'id': 'login_flow', 'step': 'start'},
  );

  return controller;
}

Future<GraphController> _controllerWithMultipleChains() async {
  final GraphController controller = await _controllerWithChains();
  controller.registerEventChainDefinition(<String, Object?>{
    'id': 'checkout_flow',
    'label': 'Checkout Flow',
    'description': 'Checkout sequence',
    'tags': const <String>['Chain', 'Checkout'],
    'steps': const <Map<String, Object?>>[
      {'stepId': 'cart', 'nodeId': 'nodeA'},
      {'stepId': 'pay', 'nodeId': 'nodeB'},
    ],
  });
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'EventChainsViewModel reorders pinned chains and toggles selection',
    () async {
      final GraphController controller = await _controllerWithMultipleChains();
      addTearDown(controller.dispose);

      final EventChainsViewModel viewModel = EventChainsViewModel(
        controller: controller,
        pinnedChains: const <String>{'checkout_flow'},
      );
      addTearDown(viewModel.dispose);

      await pumpEventQueue();

      expect(viewModel.chainViews.first.snapshot.id, equals('checkout_flow'));

      viewModel.toggleChainSelection('login_flow');
      expect(viewModel.selectedChainId, equals('login_flow'));
      final String? attemptKey = viewModel.selectedAttemptKey;
      expect(attemptKey, isNotNull);

      viewModel.toggleChainSelection('login_flow');
      expect(viewModel.selectedChainId, isNull);
      expect(viewModel.selectedAttemptKey, isNull);
    },
  );

  test('resetChain clears attempt selection state', () async {
    final GraphController controller = await _controllerWithChains();
    addTearDown(controller.dispose);

    final EventChainsViewModel viewModel = EventChainsViewModel(
      controller: controller,
    );
    addTearDown(viewModel.dispose);

    await pumpEventQueue();
    viewModel.toggleChainSelection('login_flow');
    expect(viewModel.selectedAttemptKey, isNotNull);

    controller.recordEventChainProgress(
      nodeId: 'nodeB',
      chain: <String, Object?>{'id': 'login_flow', 'step': 'finish'},
    );
    await pumpEventQueue();

    viewModel.resetChain('login_flow');
    expect(viewModel.selectedAttemptKey, isNull);
  });
}
