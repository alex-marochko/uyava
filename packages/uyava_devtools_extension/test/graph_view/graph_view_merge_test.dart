import 'package:flutter_test/flutter_test.dart';

import 'graph_view_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerGraphViewTestHarness();

  testWidgets('incremental node removals cascade edges via merge', (
    tester,
  ) async {
    final dynamic graphState = await pumpGraphViewPage(
      tester,
      graphPayload: basicGraphPayload(),
    );

    expect(
      (graphState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceA', 'serviceB'}),
    );
    expect(
      (graphState.visibleEdgeIds as List<String>).toSet(),
      equals({'serviceA-serviceB'}),
    );

    graphState.removeNodeForTesting(
      'serviceA',
      cascadeEdgeIds: const ['serviceA-serviceB'],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      (graphState.visibleNodeIds as List<String>).toSet(),
      equals({'serviceB'}),
    );
    expect(graphState.visibleEdgeIds, isEmpty);
  });

  testWidgets('patch events replace existing node data via merge', (
    tester,
  ) async {
    final dynamic graphState = await pumpGraphViewPage(
      tester,
      graphPayload: basicGraphPayload(),
    );

    final List<Map<String, dynamic>> nodes =
        (basicGraphPayload()['nodes'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final Map<String, dynamic> patchedNode = Map<String, dynamic>.from(
      nodes.firstWhere((node) => node['id'] == 'serviceB'),
    )..['label'] = 'Service B · patched';

    graphState.patchNodeForTesting(patchedNode);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final graphController = graphState.graphController;
    final updatedNode = graphController.nodes.singleWhere(
      (node) => node.id == 'serviceB',
    );
    expect(updatedNode.label, 'Service B · patched');

    graphState.removeEdgeForTesting('serviceB-serviceC');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      (graphState.visibleEdgeIds as List<String>).toSet(),
      equals({'serviceA-serviceB'}),
    );
  });
}
