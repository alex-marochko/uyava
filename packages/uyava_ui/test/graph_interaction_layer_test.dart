import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

DisplayNode _node({
  required String id,
  required Offset position,
  String type = 'service',
  String? parentId,
}) {
  return DisplayNode(
    node: UyavaNode(
      rawData: <String, Object?>{
        'id': id,
        'type': type,
        'label': id,
        if (parentId != null) 'parentId': parentId,
      },
    ),
    position: position,
  );
}

void main() {
  const RenderConfig config = RenderConfig();

  test('hitTestParentIdAt returns parent when tapped within radius', () {
    final DisplayNode parent = _node(
      id: 'parent',
      position: const Offset(40, 40),
    );
    final DisplayNode child = _node(
      id: 'child',
      position: const Offset(90, 40),
      parentId: 'parent',
    );
    final String? result = hitTestParentIdAt(
      const Offset(44, 42),
      <DisplayNode>[parent, child],
      <String, List<UyavaNode>>{
        'parent': <UyavaNode>[parent.node],
      },
      config,
    );

    expect(result, 'parent');
  });

  test('GraphInteractionLayer resolves nearest node hit', () {
    final DisplayNode left = _node(id: 'left', position: const Offset(0, 0));
    final DisplayNode right = _node(id: 'right', position: const Offset(60, 0));
    final GraphInteractionLayer layer = GraphInteractionLayer(
      displayNodes: <DisplayNode>[left, right],
      childrenByParent: const <String, List<UyavaNode>>{},
      renderConfig: config,
    );

    expect(layer.hitTestNodeId(const Offset(2, 2)), 'left');
    expect(layer.hitTestNodeId(const Offset(52, 2)), 'right');
  });
}
