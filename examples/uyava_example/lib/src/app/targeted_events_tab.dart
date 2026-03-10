part of 'package:uyava_example/main.dart';

mixin _TargetedEventsTabMixin on _ExampleAppStateBase {
  Widget _buildTargetedEventsTab() {
    final isNode = _targetType == _TargetType.node;
    final isEdge = _targetType == _TargetType.edge;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fire a targeted event on a specific node or edge',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Target type:'),
              ChoiceChip(
                label: const Text('Edge'),
                selected: isEdge,
                onSelected: (_) =>
                    setState(() => _targetType = _TargetType.edge),
              ),
              ChoiceChip(
                label: const Text('Node'),
                selected: isNode,
                onSelected: (_) =>
                    setState(() => _targetType = _TargetType.node),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Severity:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedSeverity,
                items: const [
                  DropdownMenuItem(value: 'trace', child: Text('trace')),
                  DropdownMenuItem(value: 'debug', child: Text('debug')),
                  DropdownMenuItem(value: 'info', child: Text('info')),
                  DropdownMenuItem(value: 'warn', child: Text('warn')),
                  DropdownMenuItem(value: 'error', child: Text('error')),
                  DropdownMenuItem(value: 'fatal', child: Text('fatal')),
                ],
                onChanged: (v) => setState(
                  () => _selectedSeverity = v ?? UyavaSeverity.info.name,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEdge) ...[
            const Text('Select edge'),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedEdgeIdTarget,
              items: _animatableEdgeIds
                  .map(
                    (id) => DropdownMenuItem(
                      value: id,
                      child: Text(_edgeLabels[id] ?? id),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedEdgeIdTarget = val),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              key: const ValueKey('emit-edge-event-button'),
              onPressed: (_selectedEdgeIdTarget != null)
                  ? () {
                      final String edgeId = _selectedEdgeIdTarget!;
                      final UyavaSeverity? severity = _severityFromName(
                        _selectedSeverity,
                      );
                      final String label = _edgeLabels[edgeId] ?? edgeId;
                      Uyava.emitEdgeEvent(
                        edge: edgeId,
                        message: 'Manual burst on $label',
                        severity: severity,
                      );
                    }
                  : null,
              icon: const Icon(Icons.bolt),
              label: const Text('Emit Edge Event'),
            ),
          ],
          if (isNode) ...[
            const Text('Select node'),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedNodeIdTarget,
              items: _eventableNodeIds
                  .map(
                    (id) => DropdownMenuItem(
                      value: id,
                      child: Text(_nodeLabels[id] ?? id),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedNodeIdTarget = val),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              key: const ValueKey('emit-node-event-button'),
              onPressed: (_selectedNodeIdTarget != null)
                  ? () {
                      final String nodeId = _selectedNodeIdTarget!;
                      final UyavaSeverity? severity = _severityFromName(
                        _selectedSeverity,
                      );
                      final String label = _nodeLabels[nodeId] ?? nodeId;
                      Uyava.emitNodeEvent(
                        nodeId: nodeId,
                        message: 'Manual pulse on $label',
                        severity: severity,
                      );
                    }
                  : null,
              icon: const Icon(Icons.circle),
              label: const Text('Emit Node Pulse'),
            ),
          ],
          const Spacer(),
          const Text(
            'Tip: lists reflect currently enabled features only.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
