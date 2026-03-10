import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'filters_multi_select_field.dart';

class NodeFilterOptionsController {
  List<NodeFilterOption> _options = const <NodeFilterOption>[];
  Map<String, NodeFilterOption> _lookup = const <String, NodeFilterOption>{};
  Map<String, List<String>> _descendants = const <String, List<String>>{};
  List<int> _depthLevels = const <int>[0];

  List<NodeFilterOption> get options => _options;
  Map<String, NodeFilterOption> get lookup => _lookup;
  Map<String, List<String>> get descendants => _descendants;
  List<int> get depthLevels => _depthLevels;

  void update(List<UyavaNode> nodes) {
    final _NodeData data = _deriveNodeData(nodes);
    _options = data.options;
    _lookup = data.lookup;
    _descendants = data.descendants;
    _depthLevels = data.depthLevels;
  }
}

class TagFilterOptionsController {
  List<TagFilterOption> _options = const <TagFilterOption>[];
  Map<String, TagFilterOption> _lookup = const <String, TagFilterOption>{};
  Set<String> _normalizations = const <String>{};

  List<TagFilterOption> get options => _options;
  Map<String, TagFilterOption> get lookup => _lookup;

  /// Returns true if the derived tag list changed.
  bool update({
    required List<UyavaNode> nodes,
    required List<GraphMetricSnapshot> metrics,
    required List<GraphEventChainSnapshot> eventChains,
  }) {
    final _TagData data = _deriveTagData(nodes, metrics, eventChains);
    final Set<String> nextNormalizations = <String>{
      for (final TagFilterOption option in data.options) option.normalized,
    };
    final bool changed = !setEquals(_normalizations, nextNormalizations);
    _normalizations = nextNormalizations;
    _options = data.options;
    _lookup = data.lookup;
    return changed;
  }
}

class NodeFilterOption extends FiltersMultiSelectOption<String> {
  NodeFilterOption({
    required super.value,
    required super.label,
    super.subtitle,
    super.searchText,
    super.depth,
  });

  @override
  String get chipLabel => '$label ($value)';
}

class TagFilterOption extends FiltersMultiSelectOption<String> {
  TagFilterOption({
    required super.value,
    required super.label,
    required this.normalized,
    super.searchText,
  });

  final String normalized;
}

class _NodeData {
  const _NodeData({
    required this.options,
    required this.lookup,
    required this.depthLevels,
    required this.descendants,
  });

  final List<NodeFilterOption> options;
  final Map<String, NodeFilterOption> lookup;
  final List<int> depthLevels;
  final Map<String, List<String>> descendants;
}

class _TagData {
  const _TagData({required this.options, required this.lookup});

  final List<TagFilterOption> options;
  final Map<String, TagFilterOption> lookup;
}

_NodeData _deriveNodeData(List<UyavaNode> nodes) {
  if (nodes.isEmpty) {
    return const _NodeData(
      options: <NodeFilterOption>[],
      lookup: <String, NodeFilterOption>{},
      depthLevels: <int>[0],
      descendants: <String, List<String>>{},
    );
  }

  final Map<String, UyavaNode> byId = {
    for (final UyavaNode node in nodes) node.id: node,
  };
  final Map<String, List<UyavaNode>> childrenByParent =
      <String, List<UyavaNode>>{};
  final List<UyavaNode> roots = <UyavaNode>[];

  for (final UyavaNode node in nodes) {
    final String? parentId = node.parentId;
    if (parentId == null || !byId.containsKey(parentId)) {
      roots.add(node);
    } else {
      (childrenByParent[parentId] ??= <UyavaNode>[]).add(node);
    }
  }

  int compareNodes(UyavaNode a, UyavaNode b) {
    final String aLabel = a.label.toLowerCase();
    final String bLabel = b.label.toLowerCase();
    final int labelCompare = aLabel.compareTo(bLabel);
    if (labelCompare != 0) return labelCompare;
    return a.id.compareTo(b.id);
  }

  void sortChildren(List<UyavaNode>? children) {
    children?.sort(compareNodes);
  }

  sortChildren(roots);
  childrenByParent.values.forEach(sortChildren);

  final List<NodeFilterOption> options = <NodeFilterOption>[];
  final Map<String, NodeFilterOption> lookup = <String, NodeFilterOption>{};
  final Map<String, List<String>> descendants = <String, List<String>>{};
  int maxDepth = 0;

  void visit(UyavaNode node, int depth) {
    maxDepth = math.max(maxDepth, depth);
    final String label = node.label.isEmpty ? node.id : node.label;
    final String subtitle = node.id;
    final NodeFilterOption option = NodeFilterOption(
      value: node.id,
      label: label,
      subtitle: subtitle,
      depth: depth,
      searchText:
          '${label.toLowerCase()} ${subtitle.toLowerCase()} ${node.type.toLowerCase()}',
    );
    options.add(option);
    lookup[node.id] = option;
    final List<UyavaNode>? children = childrenByParent[node.id];
    if (children != null) {
      for (final UyavaNode child in children) {
        visit(child, depth + 1);
      }
    }
    final List<String> descendantIds = <String>[];
    if (children != null) {
      for (final UyavaNode child in children) {
        descendantIds.add(child.id);
        final List<String>? childDescendants = descendants[child.id];
        if (childDescendants != null && childDescendants.isNotEmpty) {
          descendantIds.addAll(childDescendants);
        }
      }
    }
    descendants[node.id] = List<String>.unmodifiable(descendantIds);
  }

  for (final UyavaNode root in roots) {
    visit(root, 0);
  }

  final List<int> depthLevels = [
    for (int level = 0; level <= maxDepth; level++) level,
  ];

  return _NodeData(
    options: options,
    lookup: lookup,
    depthLevels: depthLevels,
    descendants: descendants,
  );
}

_TagData _deriveTagData(
  List<UyavaNode> nodes,
  List<GraphMetricSnapshot> metrics,
  List<GraphEventChainSnapshot> eventChains,
) {
  if (nodes.isEmpty && metrics.isEmpty && eventChains.isEmpty) {
    return const _TagData(
      options: <TagFilterOption>[],
      lookup: <String, TagFilterOption>{},
    );
  }

  final Map<String, TagFilterOption> byNormalized = <String, TagFilterOption>{};
  void addTag(String? value) {
    if (value == null || value.isEmpty) return;
    final String normalized = value.toLowerCase();
    if (byNormalized.containsKey(normalized)) return;
    byNormalized[normalized] = TagFilterOption(
      value: value,
      label: value,
      normalized: normalized,
      searchText: normalized,
    );
  }

  for (final UyavaNode node in nodes) {
    final Object? rawTags = node.data['tags'];
    if (rawTags is! Iterable) continue;
    for (final Object? entry in rawTags) {
      if (entry is! String) continue;
      addTag(entry);
    }
  }

  for (final GraphMetricSnapshot snapshot in metrics) {
    final definition = snapshot.definition;
    final Iterable<String> metricTags = definition.tags.isNotEmpty
        ? definition.tags
        : definition.tagsNormalized;
    for (final String tag in metricTags) {
      addTag(tag);
    }
  }

  for (final GraphEventChainSnapshot chain in eventChains) {
    final UyavaEventChainDefinitionPayload definition = chain.definition;
    final Iterable<String> chainTags = definition.tags.isNotEmpty
        ? definition.tags
        : definition.tagsNormalized;
    for (final String tag in chainTags) {
      addTag(tag);
    }
  }

  final List<TagFilterOption> options = byNormalized.values.toList(
    growable: false,
  )..sort((a, b) => a.normalized.compareTo(b.normalized));
  final Map<String, TagFilterOption> byValue = {
    for (final TagFilterOption option in options) option.value: option,
  };

  return _TagData(options: options, lookup: byValue);
}
