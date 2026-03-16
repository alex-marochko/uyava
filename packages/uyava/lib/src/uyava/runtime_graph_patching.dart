part of 'package:uyava/uyava.dart';

extension _UyavaGraphPatching on _UyavaRuntime {
  /// Applies a selective update to an existing node.
  ///
  /// [changes] accepts a partial set of node fields (type, label, description,
  /// parentId, tags, color, shape). Tags should be provided as a list of
  /// strings. Passing `null` clears the value for nullable fields.
  void patchNode(String nodeId, Map<String, Object?> changes) {
    final UyavaNode? current = graph.nodes[nodeId];
    if (current == null) {
      developer.log(
        'Uyava patchNode ignored: unknown id $nodeId',
        name: 'Uyava',
      );
      return;
    }
    if (changes.isEmpty) return;

    String? nextType;
    bool typeProvided = false;
    String? nextLabel;
    bool labelProvided = false;
    String? nextDescription;
    bool descriptionProvided = false;
    String? nextParentId;
    bool parentProvided = false;
    List<String>? nextTags;
    bool tagsProvided = false;
    String? nextColor;
    bool colorProvided = false;
    String? nextShape;
    bool shapeProvided = false;

    for (final entry in changes.entries) {
      switch (entry.key) {
        case 'type':
          typeProvided = true;
          final Object? value = entry.value;
          if (value is String && value.trim().isNotEmpty) {
            nextType = value;
          } else {
            nextType = 'unknown';
          }
          break;
        case 'label':
          labelProvided = true;
          final Object? value = entry.value;
          nextLabel = value is String ? value : null;
          break;
        case 'description':
          descriptionProvided = true;
          final Object? value = entry.value;
          nextDescription = value is String ? value : null;
          break;
        case 'parentId':
          parentProvided = true;
          final Object? value = entry.value;
          nextParentId = value is String && value.isNotEmpty ? value : null;
          break;
        case 'tags':
          tagsProvided = true;
          final Object? value = entry.value;
          if (value == null) {
            nextTags = null;
          } else if (value is Iterable) {
            nextTags = value.whereType<String>().toList();
          } else {
            developer.log(
              'Uyava patchNode ignored tags payload (expected Iterable): $value',
              name: 'Uyava',
            );
            tagsProvided = false;
          }
          break;
        case 'color':
          colorProvided = true;
          final Object? value = entry.value;
          nextColor = value is String ? value : null;
          break;
        case 'shape':
          shapeProvided = true;
          final Object? value = entry.value;
          nextShape = value is String ? value : null;
          break;
        default:
          developer.log(
            'Uyava patchNode ignored unsupported key ${entry.key}',
            name: 'Uyava',
          );
      }
    }

    if (!(typeProvided ||
        labelProvided ||
        descriptionProvided ||
        parentProvided ||
        tagsProvided ||
        colorProvided ||
        shapeProvided)) {
      return;
    }

    final UyavaNode updated = UyavaNode(
      id: current.id,
      type: typeProvided ? nextType ?? 'unknown' : current.type,
      label: labelProvided ? nextLabel : current.label,
      description: descriptionProvided ? nextDescription : current.description,
      parentId: parentProvided ? nextParentId : current.parentId,
      tags: tagsProvided ? nextTags : current.tags,
      color: colorProvided ? nextColor : current.color,
      shape: shapeProvided ? nextShape : current.shape,
    );

    final Map<String, dynamic> previousSnapshot = nodeSnapshot(current);
    final Map<String, dynamic> nextSnapshot = nodeSnapshot(updated);
    if (_mapsEffectivelyEqual(previousSnapshot, nextSnapshot)) {
      return;
    }

    graph.nodes[nodeId] = updated;
    nodeLifecycleStates.putIfAbsent(nodeId, () => defaultLifecycleState);

    final Set<String> changedKeys = <String>{};
    final Set<String> allKeys = <String>{
      ...previousSnapshot.keys,
      ...nextSnapshot.keys,
    };
    for (final key in allKeys) {
      final Object? before = previousSnapshot[key];
      final Object? after = nextSnapshot[key];
      if (!_valuesEqual(before, after)) {
        changedKeys.add(key);
      }
    }

    developer.log(
      'Uyava patchNode: $nodeId changed ${changedKeys.join(', ')}',
      name: 'Uyava',
    );

    postEvent(UyavaEventTypes.patchNode, <String, dynamic>{
      'id': nodeId,
      'node': nextSnapshot,
      if (changedKeys.isNotEmpty) 'changedKeys': changedKeys.toList(),
    });
  }

  /// Applies a selective update to an existing edge.
  ///
  /// [changes] accepts a partial set of edge fields (from, to, label,
  /// description). Passing `null` clears the value for nullable fields.
  void patchEdge(String edgeId, Map<String, Object?> changes) {
    final UyavaEdge? current = graph.edges[edgeId];
    if (current == null) {
      developer.log(
        'Uyava patchEdge ignored: unknown id $edgeId',
        name: 'Uyava',
      );
      return;
    }
    if (changes.isEmpty) return;

    String? nextSource;
    bool sourceProvided = false;
    String? nextTarget;
    bool targetProvided = false;
    String? nextLabel;
    bool labelProvided = false;
    String? nextDescription;
    bool descriptionProvided = false;

    for (final entry in changes.entries) {
      switch (entry.key) {
        case 'from':
        case 'source':
          sourceProvided = true;
          final Object? value = entry.value;
          nextSource = value is String && value.isNotEmpty
              ? value.trim()
              : null;
          break;
        case 'to':
        case 'target':
          targetProvided = true;
          final Object? value = entry.value;
          nextTarget = value is String && value.isNotEmpty
              ? value.trim()
              : null;
          break;
        case 'label':
          labelProvided = true;
          final Object? value = entry.value;
          nextLabel = value is String ? value : null;
          break;
        case 'description':
          descriptionProvided = true;
          final Object? value = entry.value;
          nextDescription = value is String ? value : null;
          break;
        default:
          developer.log(
            'Uyava patchEdge ignored unsupported key ${entry.key}',
            name: 'Uyava',
          );
      }
    }

    if (!(sourceProvided ||
        targetProvided ||
        labelProvided ||
        descriptionProvided)) {
      return;
    }

    String resolvedSource = current.from;
    if (sourceProvided) {
      if (nextSource == null) {
        developer.log(
          'Uyava patchEdge ignored null from for $edgeId',
          name: 'Uyava',
        );
        return;
      }
      if (!graph.nodes.containsKey(nextSource)) {
        postDiagnostic(
          code: UyavaGraphIntegrityCode.edgesDanglingSource,
          level: UyavaDiagnosticLevel.error,
          edgeId: edgeId,
          context: {'source': nextSource, 'origin': 'patchEdge'},
        );
        return;
      }
      resolvedSource = nextSource;
    }

    String resolvedTarget = current.to;
    if (targetProvided) {
      if (nextTarget == null) {
        developer.log(
          'Uyava patchEdge ignored null target for $edgeId',
          name: 'Uyava',
        );
        return;
      }
      if (!graph.nodes.containsKey(nextTarget)) {
        postDiagnostic(
          code: UyavaGraphIntegrityCode.edgesDanglingTarget,
          level: UyavaDiagnosticLevel.error,
          edgeId: edgeId,
          context: {'target': nextTarget, 'origin': 'patchEdge'},
        );
        return;
      }
      resolvedTarget = nextTarget;
    }

    if (resolvedSource == resolvedTarget) {
      postDiagnostic(
        code: UyavaGraphIntegrityCode.edgesSelfLoop,
        level: UyavaDiagnosticLevel.error,
        edgeId: edgeId,
        context: {'nodeId': resolvedSource, 'origin': 'patchEdge'},
      );
      return;
    }

    final UyavaEdge updated = UyavaEdge(
      id: current.id,
      from: resolvedSource,
      to: resolvedTarget,
      label: labelProvided ? nextLabel : current.label,
      description: descriptionProvided ? nextDescription : current.description,
    );

    final Map<String, dynamic> previousSnapshot = current.toJson();
    final Map<String, dynamic> nextSnapshot = updated.toJson();
    if (_mapsEffectivelyEqual(previousSnapshot, nextSnapshot)) {
      return;
    }

    graph.edges[edgeId] = updated;

    final Set<String> changedKeys = <String>{};
    final Set<String> allKeys = <String>{
      ...previousSnapshot.keys,
      ...nextSnapshot.keys,
    };
    for (final key in allKeys) {
      final Object? before = previousSnapshot[key];
      final Object? after = nextSnapshot[key];
      if (!_valuesEqual(before, after)) {
        changedKeys.add(key);
      }
    }

    developer.log(
      'Uyava patchEdge: $edgeId changed ${changedKeys.join(', ')}',
      name: 'Uyava',
    );

    postEvent(UyavaEventTypes.patchEdge, <String, dynamic>{
      'id': edgeId,
      'edge': nextSnapshot,
      if (changedKeys.isNotEmpty) 'changedKeys': changedKeys.toList(),
    });
  }

  bool _mapsEffectivelyEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    final Set<String> keys = <String>{...a.keys, ...b.keys};
    for (final key in keys) {
      if (!_valuesEqual(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }

  bool _valuesEqual(Object? a, Object? b) {
    if (a is List && b is List) {
      return listEquals(a, b);
    }
    return a == b;
  }
}
