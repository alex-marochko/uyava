import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import 'config.dart';
import 'display_node.dart';
import 'graph_interaction_layer.dart';

export 'graph_interaction_layer.dart'
    show GraphInteractionLayer, hitTestNodeIdAt, hitTestParentIdAt;

@Deprecated('Use hitTestParentIdAt instead')
String? hitTestParentId(
  Offset scenePos,
  List<DisplayNode> displayNodes,
  Map<String, List<UyavaNode>> childrenByParent,
  RenderConfig renderConfig,
) => hitTestParentIdAt(scenePos, displayNodes, childrenByParent, renderConfig);

@Deprecated('Use hitTestNodeIdAt instead')
String? hitTestNodeId(
  Offset scenePos,
  List<DisplayNode> displayNodes,
  Map<String, List<UyavaNode>> childrenByParent,
  RenderConfig renderConfig,
) => hitTestNodeIdAt(scenePos, displayNodes, childrenByParent, renderConfig);
