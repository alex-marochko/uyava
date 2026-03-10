part of 'package:uyava_example/main.dart';

mixin _FeaturesGraphMixin on _ExampleAppStateBase {
  void _updateGraph() {
    final featureNodes = generateFeatureNodes();
    final allEdges = generateAllEdges();

    final enabledNodes = <UyavaNode>[];
    final enabledEdges = <UyavaEdge>[];
    final enabledNodeIds = <String>{};

    _features.forEach((featureName, isEnabled) {
      if (isEnabled) {
        final nodesForFeature = featureNodes[featureName] ?? [];
        enabledNodes.addAll(nodesForFeature);
        for (final node in nodesForFeature) {
          enabledNodeIds.add(node.id);
        }
      }
    });

    for (final edge in allEdges) {
      if (enabledNodeIds.contains(edge.from) &&
          enabledNodeIds.contains(edge.to)) {
        enabledEdges.add(edge);
      }
    }

    Uyava.replaceGraph(nodes: enabledNodes, edges: enabledEdges);
    for (final entry in _featureLifecycle.entries) {
      final feature = entry.key;
      final state = entry.value;
      if (_features[feature] != true) continue;
      final nodesForFeature = featureNodes[feature] ?? const <UyavaNode>[];
      _applyLifecycleToNodes(nodesForFeature, state);
    }

    if (mounted) {
      setState(() {
        _nodeLabels = {for (final n in enabledNodes) n.id: (n.label ?? n.id)};
        final byNodeId = {
          for (final n in enabledNodes) n.id: (n.label ?? n.id),
        };
        _edgeLabels = {
          for (final e in enabledEdges)
            e.id:
                (e.label ??
                '${byNodeId[e.from] ?? e.from} → ${byNodeId[e.to] ?? e.to}'),
        };
        _animatableEdgeIds = enabledEdges.map((e) => e.id).toList();
        _eventableNodeIds = enabledNodes
            .where((n) => n.parentId != null)
            .map((n) => n.id)
            .toList();
        _animationIndex = 0;

        if (_selectedNodeIdTarget == null ||
            !_eventableNodeIds.contains(_selectedNodeIdTarget)) {
          _selectedNodeIdTarget = _eventableNodeIds.isNotEmpty
              ? _eventableNodeIds.first
              : null;
        }
        if (_selectedEdgeIdTarget == null ||
            !_animatableEdgeIds.contains(_selectedEdgeIdTarget)) {
          _selectedEdgeIdTarget = _animatableEdgeIds.isNotEmpty
              ? _animatableEdgeIds.first
              : null;
        }
        if (_selectedMetricNodeId == null ||
            !_eventableNodeIds.contains(_selectedMetricNodeId)) {
          _selectedMetricNodeId = _eventableNodeIds.isNotEmpty
              ? _eventableNodeIds.first
              : null;
        }
      });
    }
  }

  UyavaLifecycleState _protocolLifecycleFor(_Lifecycle state) {
    switch (state) {
      case _Lifecycle.initialized:
        return UyavaLifecycleState.initialized;
      case _Lifecycle.disposed:
        return UyavaLifecycleState.disposed;
      case _Lifecycle.unknown:
        return UyavaLifecycleState.unknown;
    }
  }

  _Lifecycle _uiLifecycleFor(UyavaLifecycleState state) {
    switch (state) {
      case UyavaLifecycleState.initialized:
        return _Lifecycle.initialized;
      case UyavaLifecycleState.disposed:
        return _Lifecycle.disposed;
      case UyavaLifecycleState.unknown:
        return _Lifecycle.unknown;
    }
  }

  void _applyLifecyclePreset({
    required String featureName,
    required UyavaLifecycleState state,
    bool includeRoot = true,
    bool updateUiState = true,
  }) {
    final String? rootId = _featureRootIds[featureName];
    if (rootId != null) {
      Uyava.updateSubtreeLifecycle(
        rootNodeId: rootId,
        state: state,
        includeRoot: includeRoot,
      );
    } else {
      final nodesForFeature =
          generateFeatureNodes()[featureName] ?? const <UyavaNode>[];
      _applyLifecycleToNodes(nodesForFeature, _uiLifecycleFor(state));
    }
    if (updateUiState) {
      setState(() {
        _featureLifecycle[featureName] = _uiLifecycleFor(state);
      });
    }
  }

  void _applyLifecycleForFeature(
    String featureName,
    _Lifecycle state, {
    bool includeRoot = true,
  }) {
    final nodesForFeature =
        generateFeatureNodes()[featureName] ?? const <UyavaNode>[];
    _applyLifecycleToNodes(nodesForFeature, state, includeRoot: includeRoot);
  }

  void _applyLifecycleToNodes(
    Iterable<UyavaNode> nodes,
    _Lifecycle state, {
    bool includeRoot = true,
  }) {
    final mapped = _protocolLifecycleFor(state);
    final List<UyavaNode> nodeList = nodes.toList();
    if (nodeList.isEmpty) return;

    final Set<String> nodeIds = {for (final node in nodeList) node.id};
    UyavaNode? rootCandidate;
    for (final node in nodeList) {
      final String? parentId = node.parentId;
      if (parentId == null || !nodeIds.contains(parentId)) {
        rootCandidate = node;
        break;
      }
    }

    if (rootCandidate != null) {
      Uyava.updateSubtreeLifecycle(
        rootNodeId: rootCandidate.id,
        state: mapped,
        includeRoot: includeRoot,
      );
      return;
    }

    final List<String> ids = nodeList.map((n) => n.id).toList();
    Uyava.updateNodesListLifecycle(nodeIds: ids, state: mapped);
  }
}
