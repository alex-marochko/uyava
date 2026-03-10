import 'dart:math' as math;

import '../models/uyava_edge.dart';
import '../models/uyava_node.dart';
import '../math/size2d.dart';
import '../math/vector2.dart';
import 'layout_engine.dart';

/// A simple deterministic grid layout.
///
/// Useful for demos, screenshots, and as an example of a pluggable
/// LayoutEngine implementation. Nodes are placed in row-major order
/// on a grid sized to the viewport with a small padding.
class GridLayout implements LayoutEngine {
  final double padding;
  final double minCellSize;

  GridLayout({this.padding = 24.0, this.minCellSize = 48.0});

  late Map<String, Vector2> _positions;
  bool _initialized = false;

  @override
  void initialize({
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
    required Size2D size,
    Map<String, Vector2>? initialPositions,
  }) {
    // Compute a roughly square grid.
    final n = nodes.length;
    final cols = n == 0 ? 0 : math.max(1, (math.sqrt(n)).ceil());
    final rows = cols == 0 ? 0 : (n / cols).ceil();

    final usableWidth = math.max(0.0, size.width - 2 * padding);
    final usableHeight = math.max(0.0, size.height - 2 * padding);
    final cellWidth = cols == 0 ? 0.0 : usableWidth / cols;
    final cellHeight = rows == 0 ? 0.0 : usableHeight / rows;
    final cw = math.max(minCellSize, cellWidth);
    final ch = math.max(minCellSize, cellHeight);

    _positions = <String, Vector2>{};
    for (var i = 0; i < nodes.length; i++) {
      final id = nodes[i].id;
      final seed = initialPositions?[id];
      if (seed != null) {
        _positions[id] = seed;
      } else {
        final r = cols == 0 ? 0 : (i / cols).floor();
        final c = cols == 0 ? 0 : (i % cols);
        final x = padding + (c + 0.5) * cw;
        final y = padding + (r + 0.5) * ch;
        _positions[id] = Vector2(x, y);
      }
    }

    _initialized = true;
  }

  @override
  void step() {
    // Grid layout is static; nothing to simulate.
  }

  @override
  bool get isConverged => _initialized;

  @override
  Map<String, Vector2> get positions => _positions;
}
