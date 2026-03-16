import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

DisplayNode _buildDisplayNode({
  required String id,
  required Offset position,
  String label = '',
  String type = 'node',
  String? parentId,
}) {
  final UyavaNode node = UyavaNode(
    rawData: <String, dynamic>{
      'id': id,
      'label': label,
      'type': type,
      if (parentId != null) 'parentId': parentId,
    },
  );
  return DisplayNode(node: node, position: position);
}

UyavaEdge _buildEdge(String id, String source, String target) {
  return UyavaEdge(
    data: <String, dynamic>{'id': id, 'source': source, 'target': target},
  );
}

void main() {
  final RenderConfig config = const RenderConfig();

  test('resolveGraphHoverTarget prioritizes nodes when pointer is near', () {
    final DisplayNode node = _buildDisplayNode(
      id: 'a',
      position: const Offset(24, 24),
      label: 'Node A',
    );
    final GraphHoverTarget? result = resolveGraphHoverTarget(
      scenePosition: const Offset(30, 30),
      displayNodes: <DisplayNode>[node],
      childrenByParent: <String, List<UyavaNode>>{},
      edges: const <UyavaEdge>[],
      renderConfig: config,
    );
    expect(result, isNotNull);
    expect(result!.kind, GraphHoverTargetKind.node);
    expect(result.node!.id, 'a');
  });

  test('resolveGraphHoverTarget detects edges when pointer near segment', () {
    final DisplayNode source = _buildDisplayNode(
      id: 'a',
      position: const Offset(0, 0),
    );
    final DisplayNode target = _buildDisplayNode(
      id: 'b',
      position: const Offset(100, 0),
    );
    final UyavaEdge edge = _buildEdge('edge_ab', 'a', 'b');
    final GraphHoverTarget? result = resolveGraphHoverTarget(
      scenePosition: const Offset(50, 6),
      displayNodes: <DisplayNode>[source, target],
      childrenByParent: <String, List<UyavaNode>>{},
      edges: <UyavaEdge>[edge],
      renderConfig: config,
    );
    expect(result, isNotNull);
    expect(result!.kind, GraphHoverTargetKind.edge);
    expect(result.edge!.id, 'edge_ab');
  });

  test('resolveGraphHoverTarget returns null when nothing is hit', () {
    final DisplayNode node = _buildDisplayNode(
      id: 'a',
      position: const Offset(0, 0),
    );
    final GraphHoverTarget? result = resolveGraphHoverTarget(
      scenePosition: const Offset(200, 200),
      displayNodes: <DisplayNode>[node],
      childrenByParent: <String, List<UyavaNode>>{},
      edges: const <UyavaEdge>[],
      renderConfig: config,
    );
    expect(result, isNull);
  });

  testWidgets('GraphHoverOverlay shows node parent id in tooltip', (
    WidgetTester tester,
  ) async {
    final DisplayNode node = _buildDisplayNode(
      id: 'child',
      position: const Offset(50, 50),
      label: 'Child',
      parentId: 'parent.feature',
    );
    final GraphHoverDetails details = GraphHoverDetails(
      target: GraphHoverTarget.node(node),
      viewportPosition: const Offset(50, 50),
      scenePosition: const Offset(50, 50),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: Stack(
            children: <Widget>[
              GraphHoverOverlay(
                details: details,
                viewportSize: const Size(400, 300),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Parent · parent.feature'), findsOneWidget);
  });

  testWidgets('GraphHoverOverlay shows dash when node parent is missing', (
    WidgetTester tester,
  ) async {
    final DisplayNode node = _buildDisplayNode(
      id: 'root',
      position: const Offset(80, 80),
      label: 'Root',
    );
    final GraphHoverDetails details = GraphHoverDetails(
      target: GraphHoverTarget.node(node),
      viewportPosition: const Offset(80, 80),
      scenePosition: const Offset(80, 80),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: Stack(
            children: <Widget>[
              GraphHoverOverlay(
                details: details,
                viewportSize: const Size(400, 300),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Parent · -'), findsOneWidget);
  });
}
