import '../models/uyava_edge.dart';
import '../models/uyava_node.dart';
import '../math/size2d.dart';
import '../math/vector2.dart';

/// Abstraction for pluggable layout engines.
abstract class LayoutEngine {
  /// Initialize the engine with graph data and viewport size.
  void initialize({
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
    required Size2D size,

    /// Optional seed positions for existing nodes to preserve layout
    /// during incremental updates. Engines may ignore entries for
    /// unknown IDs. When provided, engines should prefer these
    /// positions over fresh placement and may choose a milder alpha
    /// reset to avoid jarring motion.
    Map<String, Vector2>? initialPositions,
  });

  /// Advance the simulation one step.
  void step();

  /// Whether the layout has converged and no further steps are needed.
  bool get isConverged;

  /// Current node positions keyed by node id.
  Map<String, Vector2> get positions;
}
