part of 'package:uyava_example/main.dart';

mixin _FeaturesTabMixin
    on _ExampleAppStateBase, _FeaturesGraphMixin, _MetricsLogicMixin {
  void _toggleAllFeatures(bool? isEnabled) {
    final bool newAllState = !(_features.values.every((v) => v));
    setState(() {
      _features.updateAll((key, value) => newAllState);
    });
    _updateGraph();
  }

  Widget _buildFeaturesTab(bool isAnimating, bool allFeaturesEnabled) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'All Features',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: allFeaturesEnabled,
                      onChanged: _toggleAllFeatures,
                    ),
                    const Divider(),
                    ..._features.keys.map((featureName) {
                      return ListTile(
                        title: Text(featureName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Lifecycle:'),
                                const SizedBox(width: 8),
                                DropdownButton<_Lifecycle>(
                                  value: _featureLifecycle[featureName]!,
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() {
                                      _featureLifecycle[featureName] = val;
                                    });
                                    _applyLifecycleForFeature(featureName, val);
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                      value: _Lifecycle.unknown,
                                      child: Text('Unknown'),
                                    ),
                                    DropdownMenuItem(
                                      value: _Lifecycle.initialized,
                                      child: Text('Initialized'),
                                    ),
                                    DropdownMenuItem(
                                      value: _Lifecycle.disposed,
                                      child: Text('Disposed'),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Switch(
                                  value: _features[featureName]!,
                                  onChanged: (bool value) {
                                    setState(() {
                                      _features[featureName] = value;
                                    });
                                    _updateGraph();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                icon: const Icon(
                                  Icons.subdirectory_arrow_right,
                                ),
                                onPressed: () => _applyLifecycleForFeature(
                                  featureName,
                                  _featureLifecycle[featureName]!,
                                  includeRoot: false,
                                ),
                                label: const Text('Apply to children only'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        'Events per second: ${_eventsPerSecond.toStringAsFixed(1)}',
                      ),
                      Slider(
                        value: _eventsPerSecond,
                        min: 0.2,
                        max: 20,
                        onChanged: (val) =>
                            setState(() => _eventsPerSecond = val),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            key: const ValueKey<String>(
                              'start-simulation-button',
                            ),
                            onPressed: isAnimating ? null : _startAnimations,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            key: const ValueKey<String>(
                              'stop-simulation-button',
                            ),
                            onPressed: isAnimating ? _stopAnimations : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addTestNodeA,
                            icon: const Icon(Icons.add_box_outlined),
                            label: const Text('Add Test Node A'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _addTestNodeB,
                            icon: const Icon(Icons.add_box),
                            label: const Text('Add Test Node B'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Incremental graph mutations',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _connectLatestTestNodes,
                            icon: const Icon(Icons.link),
                            label: const Text('Link last test nodes'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _removeLastTestEdge,
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Remove last test edge'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _removeLastTestNode,
                            icon: const Icon(Icons.backspace),
                            label: const Text('Remove last test node'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _toggleAuthServiceHighlight,
                            icon: const Icon(Icons.color_lens_outlined),
                            label: Text(
                              _authServiceHighlighted
                                  ? 'Restore Auth Service'
                                  : 'Patch Auth Service',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _toggleRepoAuthEdgeAnnotation,
                            icon: const Icon(Icons.brush),
                            label: Text(
                              _authEdgeAnnotated
                                  ? 'Restore Auth edge'
                                  : 'Patch Auth edge',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Subtree lifecycle presets',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _applyLifecyclePreset(
                              featureName: 'Authentication',
                              state: UyavaLifecycleState.initialized,
                            ),
                            icon: const Icon(Icons.account_tree_outlined),
                            label: const Text('Init Auth subtree'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _applyLifecyclePreset(
                              featureName: 'Authentication',
                              state: UyavaLifecycleState.disposed,
                              includeRoot: false,
                              updateUiState: false,
                            ),
                            icon: const Icon(Icons.subdirectory_arrow_right),
                            label: const Text('Dispose Auth children'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _applyLifecyclePreset(
                              featureName: 'Restaurant Feed',
                              state: UyavaLifecycleState.unknown,
                            ),
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Reset Feed subtree'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _applyLifecyclePreset(
                              featureName: 'Real-time Tracking',
                              state: UyavaLifecycleState.disposed,
                            ),
                            icon: const Icon(Icons.satellite_alt),
                            label: const Text('Dispose Tracking subtree'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startAnimations() {
    if (_simulationController.isRunning) return;
    final int interval = (1000 / _eventsPerSecond).clamp(50, 5000).toInt();
    _simulationController.start(Duration(milliseconds: interval));
    setState(() {});
  }

  void _handleSimulationTick() {
    if (_animatableEdgeIds.isEmpty) return;
    final String edgeId =
        _animatableEdgeIds[_animationIndex % _animatableEdgeIds.length];
    _animationIndex++;
    final String edgeLabel = _edgeLabels[edgeId] ?? edgeId;
    Uyava.emitEdgeEvent(
      edge: edgeId,
      message: 'Auto animation on $edgeLabel (#$_animationIndex)',
    );

    if (_eventableNodeIds.isNotEmpty) {
      final String nodeId =
          _eventableNodeIds[_animationIndex % _eventableNodeIds.length];
      final String nodeLabel = _nodeLabels[nodeId] ?? nodeId;
      Uyava.emitNodeEvent(nodeId: nodeId, message: 'Auto pulse on $nodeLabel');
    }
    _emitAutomaticMetricSample();
  }

  void _stopAnimations() {
    if (!_simulationController.isRunning) return;
    _simulationController.stop();
    setState(() {});
  }

  void _addTestNodeA() {
    final id = 'test_node_a_${_testNodeCounterA++}';
    Uyava.addNode(
      UyavaNode.standard(
        id: id,
        standardType: UyavaStandardType.widget,
        label: 'Test A #$_testNodeCounterA',
      ),
    );
    _recentTestNodeIds.add(id);
  }

  void _addTestNodeB() {
    final id = 'test_node_b_${_testNodeCounterB++}';
    _graphPort.addNode(
      UyavaNode(
        id: id,
        type: 'service',
        label: 'Test B #$_testNodeCounterB',
        description: 'Added from call-site B',
      ),
    );
    _recentTestNodeIds.add(id);
  }

  void _connectLatestTestNodes() {
    if (_recentTestNodeIds.length < 2) {
      debugPrint('Need at least two test nodes to connect.');
      return;
    }
    final String from = _recentTestNodeIds[_recentTestNodeIds.length - 2];
    final String to = _recentTestNodeIds.last;
    final String edgeId = 'test_edge_${_recentAdhocEdges.length}';
    Uyava.addEdge(
      UyavaEdge(
        id: edgeId,
        from: from,
        to: to,
        label: 'Adhoc link ${_recentAdhocEdges.length + 1}',
      ),
    );
    _recentAdhocEdges.add(_AdhocEdge(id: edgeId, from: from, to: to));
  }

  void _removeLastTestEdge() {
    if (_recentAdhocEdges.isEmpty) {
      debugPrint('No adhoc edges to remove.');
      return;
    }
    final _AdhocEdge edge = _recentAdhocEdges.removeLast();
    Uyava.removeEdge(edge.id);
  }

  void _removeLastTestNode() {
    if (_recentTestNodeIds.isEmpty) {
      debugPrint('No test nodes to remove.');
      return;
    }
    final String nodeId = _recentTestNodeIds.removeLast();
    _recentAdhocEdges.removeWhere(
      (edge) => edge.from == nodeId || edge.to == nodeId,
    );
    Uyava.removeNode(nodeId);
  }

  void _toggleAuthServiceHighlight() {
    final bool next = !_authServiceHighlighted;
    setState(() => _authServiceHighlighted = next);
    if (next) {
      Uyava.patchNode('service_auth', {
        'label': 'Auth Service (patched)',
        'color': '#FF7043',
        'tags': <String>['critical', 'auth'],
      });
    } else {
      Uyava.patchNode('service_auth', {
        'label': 'Auth Service',
        'color': null,
        'tags': null,
      });
    }
  }

  void _toggleRepoAuthEdgeAnnotation() {
    final bool next = !_authEdgeAnnotated;
    setState(() => _authEdgeAnnotated = next);
    if (next) {
      Uyava.patchEdge('e3', {
        'label': 'Repo → Service (patched)',
        'description': 'Example app annotation applied at runtime.',
      });
    } else {
      Uyava.patchEdge('e3', {'label': null, 'description': null});
    }
  }
}
