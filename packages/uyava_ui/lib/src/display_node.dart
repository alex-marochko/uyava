import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

/// Lightweight view model that pairs a node with its computed position.
class DisplayNode {
  const DisplayNode({required this.node, required this.position});

  final UyavaNode node;
  final Offset position;

  String get id => node.id;
  String get label => node.label;
  String get type => node.type;
  String? get parentId => node.parentId;
  NodeLifecycle get lifecycle => node.lifecycle;
}
