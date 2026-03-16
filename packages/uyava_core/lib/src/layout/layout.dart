import 'dart:math';

import 'package:collection/collection.dart';

import '../models/uyava_edge.dart';
import '../models/uyava_node.dart';
import '../math/size2d.dart';
import '../math/vector2.dart';
import 'layout_engine.dart';
import 'layout_config.dart';

// A simple class to hold node data for the layout algorithm.
class LayoutNode {
  final String id;
  final String? parentId;
  Vector2 position;
  Vector2 velocity = Vector2.zero;

  LayoutNode(this.id, this.position, {this.parentId});
}

/// Implements a force-directed layout inspired by D3.js principles.
class ForceDirectedLayout implements LayoutEngine {
  static const double _alphaEpsilon = 1e-5;
  late List<LayoutNode> _nodes;
  late List<UyavaEdge> _edges;
  late Size2D _size;
  final LayoutConfig config;
  late Map<String, String?> _parentById;
  late Map<String, String> _rootById; // top-most ancestor id (or self id)
  late Map<String, String>
  _groupById; // immediate group key: parentId ?? self id
  late Map<String, List<int>> _indicesByGroup; // group -> node indices
  late Map<String, int> _indexById;
  late Map<String, List<String>> _childrenById;
  late List<String> _treeRoots;
  late List<String> _idsByDepthDesc;
  Map<String, Vector2> _anchorPos = {};
  late Map<String, int>
  _edgeCountByRootPair; // undirected root pair -> edge count

  // D3-inspired parameters
  double alpha = 1.0; // Simulation "energy"

  ForceDirectedLayout({LayoutConfig? config})
    : config = config ?? const LayoutConfig();

  @override
  void initialize({
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
    required Size2D size,
    Map<String, Vector2>? initialPositions,
  }) {
    _edges = edges;
    _size = size;
    _nodes = nodes
        .map((un) => LayoutNode(un.id, Vector2.zero, parentId: un.parentId))
        .toList();
    // When seeded positions are provided, start with a milder alpha
    // to avoid jarring motion and preserve continuity.
    if (initialPositions != null && initialPositions.isNotEmpty) {
      alpha = 0.2;
    } else {
      // reset alpha when re-initializing without seeds
      alpha = 1.0;
    }
    if (_nodes.isEmpty) return;
    _computeHierarchyKeys(nodes);
    _buildIndicesByGroup(nodes);
    if (config.subtreeSeparationStrength > 0) {
      _buildHierarchyTreeCache(nodes);
    }
    _buildEdgeCountByRootPair();
    _placeWithSeedsOrDeterministic(initialPositions);
  }

  void _computeHierarchyKeys(List<UyavaNode> nodes) {
    // Build parent map for quick traversal
    final Map<String, String?> parentById = {
      for (final n in nodes) n.id: n.parentId,
    };
    final Map<String, String> rootById = {};
    final Map<String, String> groupById = {};

    String findRoot(String id) {
      // If parent is null, root is the node id itself (top-level)
      String? current = id;
      String? parent = parentById[current];
      if (parent == null) return id;
      // Walk up until no parent
      final seen = <String>{};
      while (parent != null && !seen.contains(parent)) {
        seen.add(parent);
        final next = parentById[parent];
        if (next == null) {
          return parent;
        }
        parent = next;
      }
      return parent ?? id;
    }

    for (final n in nodes) {
      rootById[n.id] = findRoot(n.id);
      groupById[n.id] = n.parentId ?? n.id;
    }
    _parentById = parentById;
    _rootById = rootById;
    _groupById = groupById;
  }

  bool _isAncestor(String candidateAncestorId, String nodeId) {
    String? cursor = _parentById[nodeId];
    final seen = <String>{};
    while (cursor != null && seen.add(cursor)) {
      if (cursor == candidateAncestorId) {
        return true;
      }
      cursor = _parentById[cursor];
    }
    return false;
  }

  bool _isAncestorOrDescendant(String a, String b) {
    return _isAncestor(a, b) || _isAncestor(b, a);
  }

  void _buildIndicesByGroup(List<UyavaNode> nodes) {
    final map = <String, List<int>>{};
    for (var i = 0; i < nodes.length; i++) {
      final id = nodes[i].id;
      final group = _groupById[id] ?? id;
      (map[group] ??= <int>[]).add(i);
    }
    _indicesByGroup = map;
    _anchorPos = {};
  }

  void _buildHierarchyTreeCache(List<UyavaNode> nodes) {
    _indexById = <String, int>{
      for (var i = 0; i < nodes.length; i++) nodes[i].id: i,
    };
    final Set<String> idSet = _indexById.keys.toSet();

    final Map<String, List<String>> children = <String, List<String>>{
      for (final id in idSet) id: <String>[],
    };
    for (final node in nodes) {
      final String id = node.id;
      final String? parent = _parentById[id];
      if (parent == null || parent == id || !idSet.contains(parent)) continue;
      children[parent]!.add(id);
    }
    _childrenById = children;

    final Set<String> rootSet = <String>{};
    for (final node in nodes) {
      final String id = node.id;
      final String? parent = _parentById[id];
      if (parent == null || parent == id || !idSet.contains(parent)) {
        rootSet.add(id);
      }
    }

    final Set<String> covered = <String>{};
    void markSubtree(String rootId) {
      final List<String> stack = <String>[rootId];
      while (stack.isNotEmpty) {
        final String current = stack.removeLast();
        if (!covered.add(current)) continue;
        final List<String>? children = _childrenById[current];
        if (children == null || children.isEmpty) continue;
        stack.addAll(children);
      }
    }

    for (final root in rootSet) {
      markSubtree(root);
    }
    if (covered.length < nodes.length) {
      for (final node in nodes) {
        if (covered.contains(node.id)) continue;
        rootSet.add(node.id);
        markSubtree(node.id);
      }
    }
    _treeRoots = rootSet.toList(growable: false);

    final Map<String, int> depthMemo = <String, int>{};
    int depthOf(String id) {
      final int? cached = depthMemo[id];
      if (cached != null) return cached;
      int depth = 0;
      String cursor = id;
      final Set<String> seen = <String>{cursor};
      while (true) {
        final String? parent = _parentById[cursor];
        if (parent == null || parent == cursor || !idSet.contains(parent)) {
          break;
        }
        final int? parentDepth = depthMemo[parent];
        if (parentDepth != null) {
          depth += parentDepth + 1;
          break;
        }
        if (!seen.add(parent)) {
          break;
        }
        depth++;
        cursor = parent;
      }
      depthMemo[id] = depth;
      return depth;
    }

    final List<String> ids = nodes.map((n) => n.id).toList(growable: false);
    for (final id in ids) {
      depthOf(id);
    }
    ids.sort((a, b) {
      final int da = depthMemo[a] ?? 0;
      final int db = depthMemo[b] ?? 0;
      return db.compareTo(da);
    });
    _idsByDepthDesc = ids;
  }

  void _buildEdgeCountByRootPair() {
    final map = <String, int>{};
    String pairKey(String a, String b) {
      return (a.compareTo(b) <= 0) ? '$a|$b' : '$b|$a';
    }

    for (final e in _edges) {
      final rS = _rootById[e.source] ?? e.source;
      final rT = _rootById[e.target] ?? e.target;
      if (rS == rT) continue;
      final key = pairKey(rS, rT);
      map[key] = (map[key] ?? 0) + 1;
    }
    _edgeCountByRootPair = map;
  }

  void _placeWithSeedsOrDeterministic(Map<String, Vector2>? seeds) {
    if (_nodes.isEmpty) return;
    // Build neighbor map for smarter placement of new nodes.
    final Map<String, List<String>> neighbors = <String, List<String>>{};
    for (final e in _edges) {
      (neighbors[e.source] ??= <String>[]).add(e.target);
      (neighbors[e.target] ??= <String>[]).add(e.source);
    }

    final center = Vector2(_size.width / 2, _size.height / 2);
    final radius = min(_size.width, _size.height) / 3;
    final jitter = Random(0xA11CE);

    for (var i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      final seed = seeds?[node.id];
      if (seed != null) {
        node.position = seed;
        continue;
      }
      // Try neighbors with seeds first
      final neighIds = neighbors[node.id] ?? const <String>[];
      final seededNeighbors = neighIds
          .map((id) => seeds?[id])
          .whereType<Vector2>()
          .toList(growable: false);
      if (seededNeighbors.isNotEmpty) {
        var sx = 0.0, sy = 0.0;
        for (final p in seededNeighbors) {
          sx += p.dx;
          sy += p.dy;
        }
        final avg = Vector2(
          sx / seededNeighbors.length,
          sy / seededNeighbors.length,
        );
        // Place near neighbors with a small jitter
        node.position =
            avg +
            Vector2(
              (jitter.nextDouble() - 0.5) * 10.0,
              (jitter.nextDouble() - 0.5) * 10.0,
            );
        continue;
      }
      // If has parent with seed, place near parent
      final parentId = node.parentId;
      if (parentId != null) {
        final parentSeed = seeds?[parentId];
        if (parentSeed != null) {
          node.position =
              parentSeed +
              Vector2(
                (jitter.nextDouble() - 0.5) * 20.0,
                (jitter.nextDouble() - 0.5) * 20.0,
              );
          continue;
        }
      }
      // Fallback: deterministic ring placement for remaining nodes.
      final angle = (2 * pi * i) / _nodes.length;
      node.position =
          center + Vector2(cos(angle) * radius, sin(angle) * radius);
    }
  }

  @override
  void step() {
    if (alpha <= config.alphaMin + _alphaEpsilon) {
      alpha = config.alphaMin;
      return;
    }

    // 1. Apply forces to update velocities
    _applyManyBodyForce();
    _applyLinkForce();
    _applyHierarchicalGravity();
    _applyGroupAnchors();
    if (config.subtreeSeparationStrength > 0) {
      _applySubtreeSeparationForce();
    }

    // 2. Update positions based on velocity
    for (var node in _nodes) {
      // Apply friction
      node.velocity *= config.velocityDecay;
      // Update position
      node.position += node.velocity;
    }

    // 3. Handle collisions
    _applyCollisionForce();

    // 4. Center the graph (D3-style)
    _applyCentering();

    // 5. Clamp positions to bounds
    final double minX = config.padding;
    final double minY = config.padding;
    final double maxX = max(minX, _size.width - config.padding);
    final double maxY = max(minY, _size.height - config.padding);
    for (var node in _nodes) {
      node.position = Vector2(
        node.position.dx.clamp(minX, maxX),
        node.position.dy.clamp(minY, maxY),
      );
    }

    // 6. Decay alpha (cool down)
    alpha += (config.alphaMin - alpha) * config.alphaDecay;
    if ((alpha - config.alphaMin).abs() <= _alphaEpsilon) {
      alpha = config.alphaMin;
    }
  }

  void _applyGroupAnchors() {
    if (!config.enableGroupAnchors) return;
    if (_nodes.isEmpty) return;

    // 1) Compute centroid per immediate group (only groups with >1 node)
    final centroids = <String, Vector2>{};
    final counts = <String, int>{};
    for (final entry in _indicesByGroup.entries) {
      final idxs = entry.value;
      if (idxs.length <= 1) continue;
      var sx = 0.0, sy = 0.0;
      for (final i in idxs) {
        final p = _nodes[i].position;
        sx += p.dx;
        sy += p.dy;
      }
      centroids[entry.key] = Vector2(sx / idxs.length, sy / idxs.length);
      counts[entry.key] = idxs.length;
    }

    // 2) Smooth anchor positions
    final s = config.anchorSmoothing.clamp(0.0, 1.0);
    for (final e in centroids.entries) {
      final prev = _anchorPos[e.key];
      _anchorPos[e.key] = prev == null
          ? e.value
          : Vector2(
              prev.dx * s + e.value.dx * (1 - s),
              prev.dy * s + e.value.dy * (1 - s),
            );
    }

    // 3) Link nodes to their group anchor (radial spring)
    for (final entry in _indicesByGroup.entries) {
      final group = entry.key;
      final idxs = entry.value;
      if (idxs.length <= 1) continue;
      final anchor = _anchorPos[group];
      if (anchor == null) continue;
      for (final i in idxs) {
        final node = _nodes[i];
        final delta = anchor - node.position;
        final dist = delta.distance;
        if (dist == 0) continue;
        final diff = dist - config.anchorLinkDistance;
        final force = diff * config.anchorLinkStrength * alpha;
        final change = (delta / dist) * force;
        node.velocity += change;
      }
    }

    // 4a) Repel anchors from each other and distribute to member nodes
    final groups = _anchorPos.keys.toList(growable: false);
    for (var a = 0; a < groups.length; a++) {
      for (var b = a + 1; b < groups.length; b++) {
        final g1 = groups[a];
        final g2 = groups[b];
        if (_isAncestorOrDescendant(g1, g2)) {
          continue;
        }
        final p1 = _anchorPos[g1]!;
        final p2 = _anchorPos[g2]!;
        var d = (p1 - p2).distance;
        if (d < 1.0) d = 1.0;
        final base =
            (config.manyBodyStrength.abs() * config.anchorRepulsionFactor) /
            (d * d);
        final dir = (p1 - p2) / d;
        final change = dir * base * alpha;
        final c1 = (counts[g1] ?? _indicesByGroup[g1]?.length ?? 1).toDouble();
        final c2 = (counts[g2] ?? _indicesByGroup[g2]?.length ?? 1).toDouble();
        for (final i in _indicesByGroup[g1] ?? const <int>[]) {
          _nodes[i].velocity += change / c1;
        }
        for (final i in _indicesByGroup[g2] ?? const <int>[]) {
          _nodes[i].velocity -= change / c2;
        }
      }
    }

    // 4b) Soft collision between anchors based on approximate group radii
    if (config.anchorCollisionStrength > 0) {
      for (var a = 0; a < groups.length; a++) {
        for (var b = a + 1; b < groups.length; b++) {
          final g1 = groups[a];
          final g2 = groups[b];
          if (_isAncestorOrDescendant(g1, g2)) {
            continue;
          }
          final p1 = _anchorPos[g1]!;
          final p2 = _anchorPos[g2]!;
          var d = (p1 - p2).distance;
          if (d < 1.0) d = 1.0;
          final n1 = (counts[g1] ?? _indicesByGroup[g1]?.length ?? 1)
              .toDouble();
          final n2 = (counts[g2] ?? _indicesByGroup[g2]?.length ?? 1)
              .toDouble();
          final rEst1 =
              config.collisionRadius * config.anchorCollisionScale * sqrt(n1);
          final rEst2 =
              config.collisionRadius * config.anchorCollisionScale * sqrt(n2);
          final target = rEst1 + rEst2;
          final overlap = target - d;
          if (overlap > 0) {
            final dir = (p1 - p2) / d;
            final push = overlap * config.anchorCollisionStrength * alpha;
            for (final i in _indicesByGroup[g1] ?? const <int>[]) {
              _nodes[i].velocity += dir * (push / n1);
            }
            for (final i in _indicesByGroup[g2] ?? const <int>[]) {
              _nodes[i].velocity -= dir * (push / n2);
            }
          }
        }
      }
    }
  }

  Vector2 _fallbackSiblingDirection(String a, String b) {
    final String key = (a.compareTo(b) <= 0) ? '$a|$b' : '$b|$a';
    final int hash = key.hashCode & 0x7fffffff;
    final double angle = (hash % 3600) / 3600 * 2 * pi;
    final Vector2 direction = Vector2(cos(angle), sin(angle));
    return direction == Vector2.zero ? const Vector2(1, 0) : direction;
  }

  void _applySubtreeSeparationForce() {
    if (config.subtreeSeparationStrength <= 0) return;
    if (_nodes.isEmpty) return;
    if (_childrenById.isEmpty) return;

    final Map<String, Vector2> subtreeSum = <String, Vector2>{
      for (final node in _nodes) node.id: node.position,
    };
    final Map<String, int> subtreeCount = <String, int>{
      for (final node in _nodes) node.id: 1,
    };

    for (final id in _idsByDepthDesc) {
      final List<String>? children = _childrenById[id];
      if (children == null || children.isEmpty) continue;
      Vector2 sum = subtreeSum[id] ?? Vector2.zero;
      int count = subtreeCount[id] ?? 1;
      for (final child in children) {
        sum += subtreeSum[child] ?? Vector2.zero;
        count += subtreeCount[child] ?? 0;
      }
      subtreeSum[id] = sum;
      subtreeCount[id] = count;
    }

    final Map<String, Vector2> pending = <String, Vector2>{};
    for (final entry in _childrenById.entries) {
      final List<String> siblings = entry.value;
      if (siblings.length < 2) continue;
      for (var a = 0; a < siblings.length; a++) {
        for (var b = a + 1; b < siblings.length; b++) {
          final String sA = siblings[a];
          final String sB = siblings[b];
          final double nA = (subtreeCount[sA] ?? 1).toDouble();
          final double nB = (subtreeCount[sB] ?? 1).toDouble();
          final Vector2 cA = (subtreeSum[sA] ?? Vector2.zero) / nA;
          final Vector2 cB = (subtreeSum[sB] ?? Vector2.zero) / nB;
          final Vector2 delta = cA - cB;
          double distance = delta.distance;
          if (distance < 1.0) distance = 1.0;

          final double rA =
              config.collisionRadius * config.subtreeSeparationScale * sqrt(nA);
          final double rB =
              config.collisionRadius * config.subtreeSeparationScale * sqrt(nB);
          final double target = rA + rB + config.subtreeSeparationGap;
          final double overlap = target - distance;
          if (overlap <= 0) continue;

          final Vector2 direction = delta.distance < 1e-3
              ? _fallbackSiblingDirection(sA, sB)
              : (delta / distance);
          final double push =
              overlap * config.subtreeSeparationStrength * alpha;
          final Vector2 separation = direction * push;
          pending[sA] = (pending[sA] ?? Vector2.zero) + separation;
          pending[sB] = (pending[sB] ?? Vector2.zero) - separation;
        }
      }
    }

    if (pending.isEmpty) return;

    final Set<String> visited = <String>{};
    final List<MapEntry<String, Vector2>> stack = <MapEntry<String, Vector2>>[
      for (final root in _treeRoots)
        MapEntry<String, Vector2>(root, Vector2.zero),
    ];
    while (stack.isNotEmpty) {
      final MapEntry<String, Vector2> frame = stack.removeLast();
      final String id = frame.key;
      if (!visited.add(id)) continue;
      final Vector2 accumulated = frame.value + (pending[id] ?? Vector2.zero);
      final int? index = _indexById[id];
      if (index != null) {
        _nodes[index].velocity += accumulated;
      }
      final List<String>? children = _childrenById[id];
      if (children == null || children.isEmpty) continue;
      for (final child in children) {
        stack.add(MapEntry<String, Vector2>(child, accumulated));
      }
    }

    for (final node in _nodes) {
      if (visited.contains(node.id)) continue;
      final Vector2 pendingSelf = pending[node.id] ?? Vector2.zero;
      if (pendingSelf == Vector2.zero) continue;
      node.velocity += pendingSelf;
    }
  }

  void _applyManyBodyForce() {
    for (var i = 0; i < _nodes.length; i++) {
      final v = _nodes[i];
      for (var j = i + 1; j < _nodes.length; j++) {
        final u = _nodes[j];
        final delta = v.position - u.position;
        var distance = delta.distance;
        if (distance < 1.0) distance = 1.0; // Avoid division by zero
        // Increase repulsion between different immediate groups to help
        // clusters separate. Same-group stays at baseline strength.
        final differentGroup = _groupById[v.id] != _groupById[u.id];
        final hierarchicalPair = _isAncestorOrDescendant(v.id, u.id);
        final repulsion = differentGroup && !hierarchicalPair
            ? (config.manyBodyStrength * config.interGroupRepulsionFactor)
            : config.manyBodyStrength;
        final force = repulsion / (distance * distance);
        final velocityChange = delta * force * alpha;

        v.velocity -= velocityChange;
        u.velocity += velocityChange;
      }
    }
  }

  void _applyLinkForce() {
    for (var edge in _edges) {
      final source = _nodes.firstWhereOrNull((n) => n.id == edge.source);
      final target = _nodes.firstWhereOrNull((n) => n.id == edge.target);
      if (source == null || target == null) continue;

      final delta = source.position - target.position;
      final distance = delta.distance;
      final sameGroup = _groupById[source.id] == _groupById[target.id];
      final hierarchicalPair = _isAncestorOrDescendant(source.id, target.id);
      double linkDist = config.linkDistance;
      double linkStr = config.linkStrength;
      if (sameGroup || hierarchicalPair) {
        linkDist *= config.sameGroupLinkDistanceFactor;
        linkStr *= config.sameGroupLinkStrengthFactor;
      } else {
        linkDist *= config.interGroupLinkDistanceFactor;
        linkStr *= config.interGroupLinkStrengthFactor;
        final p = config.interRootLinkNormalizationPower;
        if (p > 0) {
          final rS = _rootById[source.id] ?? source.id;
          final rT = _rootById[target.id] ?? target.id;
          final key = (rS.compareTo(rT) <= 0) ? '$rS|$rT' : '$rT|$rS';
          final c = (_edgeCountByRootPair[key] ?? 1).toDouble();
          if (c > 1) {
            final factor = pow(c, p).toDouble();
            linkStr /= factor;
          }
        }
      }
      final difference = distance - linkDist;

      if (distance > 0) {
        final force = difference * linkStr * alpha;
        final velocityChange = (delta / distance) * force;

        source.velocity -= velocityChange;
        target.velocity += velocityChange;
      }
    }
  }

  void _applyHierarchicalGravity() {
    for (var v in _nodes) {
      if (v.parentId != null) {
        final parentNode = _nodes.firstWhereOrNull((n) => n.id == v.parentId);
        if (parentNode != null) {
          final delta = parentNode.position - v.position;
          final distance = delta.distance;
          final difference = distance - config.gravityLinkDistance;

          if (distance > 0) {
            final force = difference * config.gravityLinkStrength * alpha;
            final velocityChange = (delta / distance) * force;

            v.velocity += velocityChange;
            parentNode.velocity -= velocityChange;
          }
        }
      }
    }
  }

  void _applyCollisionForce() {
    for (var i = 0; i < _nodes.length; i++) {
      final v = _nodes[i];
      for (var j = i + 1; j < _nodes.length; j++) {
        final u = _nodes[j];
        final delta = v.position - u.position;
        final distance = delta.distance;
        final minDistance = config.collisionRadius * 2;

        if (distance < minDistance) {
          final overlap = minDistance - distance;
          final separation = (delta / distance) * (overlap / 2);
          v.position += separation;
          u.position -= separation;
        }
      }
    }
  }

  void _applyCentering() {
    if (_nodes.isEmpty) return;

    var cx = 0.0;
    var cy = 0.0;
    for (var node in _nodes) {
      cx += node.position.dx;
      cy += node.position.dy;
    }
    final centerOfMass = Vector2(cx / _nodes.length, cy / _nodes.length);

    final targetCenter = Vector2(_size.width / 2, _size.height / 2);
    final translation = targetCenter - centerOfMass;

    for (var node in _nodes) {
      node.position += translation;
    }
  }

  @override
  bool get isConverged => alpha <= config.alphaMin + _alphaEpsilon;

  @override
  Map<String, Vector2> get positions => {
    for (final n in _nodes) n.id: n.position,
  };
}
