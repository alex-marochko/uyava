import 'package:uyava_protocol/uyava_protocol.dart';

import 'graph_filter_state.dart';

/// Codec for persisting filter state snapshots in host storage.
class GraphFilterStateCodec {
  static const String schemaId = 'uyava.graph_filters.v1';

  const GraphFilterStateCodec();

  /// Serializes [state] into a simple JSON-friendly map.
  ///
  /// Returns `null` when the state is effectively empty.
  Map<String, Object?>? encode(GraphFilterState state) {
    if (state.isEmpty) return null;
    final Map<String, Object?> data = <String, Object?>{};

    final GraphFilterSearch? search = state.search;
    if (search != null) {
      data['search'] = <String, Object?>{
        'mode': search.mode.name,
        'pattern': search.pattern,
        'caseSensitive': search.caseSensitive,
        if (search.flags != null && search.flags!.isNotEmpty)
          'flags': search.flags,
      };
    }

    final GraphFilterTags? tags = state.tags;
    if (tags != null && tags.valuesNormalized.isNotEmpty) {
      data['tags'] = <String, Object?>{
        'mode': tags.mode.name,
        'logic': tags.logic.name,
        'values': List<String>.of(tags.values),
        'valuesNormalized': List<String>.of(tags.valuesNormalized),
      };
    }

    final GraphFilterNodeSet? nodes = state.nodes;
    if (nodes != null && (nodes.hasInclude || nodes.hasExclude)) {
      data['nodes'] = <String, Object?>{
        if (nodes.hasInclude) 'include': List<String>.of(nodes.include),
        if (nodes.hasExclude) 'exclude': List<String>.of(nodes.exclude),
      };
    }

    final GraphFilterParent? parent = state.parent;
    if (parent != null &&
        (parent.rootId != null && parent.rootId!.isNotEmpty ||
            parent.depth != null)) {
      data['parent'] = <String, Object?>{
        if (parent.rootId != null && parent.rootId!.isNotEmpty)
          'rootId': parent.rootId,
        if (parent.depth != null) 'depth': parent.depth,
      };
    }

    final GraphFilterGrouping? grouping = state.grouping;
    if (grouping != null &&
        (grouping.mode != UyavaFilterGroupingMode.none ||
            grouping.levelDepth != null)) {
      data['grouping'] = <String, Object?>{
        'mode': grouping.mode.name,
        if (grouping.levelDepth != null) 'levelDepth': grouping.levelDepth,
      };
    }

    final GraphFilterSeverity? severity = state.severity;
    if (severity != null) {
      data['severity'] = <String, Object?>{
        'operator': severity.operator.name,
        'level': severity.level.name,
      };
    }

    if (data.isEmpty) {
      return null;
    }
    return data;
  }

  /// Restores a [GraphFilterState] from serialized [raw] data.
  GraphFilterState? decode(Object? raw) {
    if (raw is! Map) return null;

    final GraphFilterSearch? search = _decodeSearch(raw['search']);
    final GraphFilterTags? tags = _decodeTags(raw['tags']);
    final GraphFilterNodeSet? nodes = _decodeNodeSet(raw['nodes']);
    final GraphFilterParent? parent = _decodeParent(raw['parent']);
    final GraphFilterGrouping? grouping = _decodeGrouping(raw['grouping']);
    final GraphFilterSeverity? severity = _decodeSeverity(raw['severity']);

    if (search == null &&
        tags == null &&
        nodes == null &&
        parent == null &&
        grouping == null &&
        severity == null) {
      return GraphFilterState.empty;
    }
    return GraphFilterState(
      search: search,
      tags: tags,
      nodes: nodes,
      parent: parent,
      grouping: grouping,
      severity: severity,
    );
  }

  static GraphFilterSearch? _decodeSearch(Object? raw) {
    if (raw is! Map) return null;
    final String? patternRaw = raw['pattern'] is String
        ? (raw['pattern'] as String).trim()
        : null;
    if (patternRaw == null || patternRaw.isEmpty) {
      return null;
    }

    final UyavaFilterSearchMode mode =
        _parseSearchMode(raw['mode']) ?? UyavaFilterSearchMode.substring;
    final bool caseSensitive = raw['caseSensitive'] is bool
        ? raw['caseSensitive'] as bool
        : false;
    final String? flags =
        raw['flags'] is String && (raw['flags'] as String).isNotEmpty
        ? raw['flags'] as String
        : null;
    return GraphFilterSearch(
      mode: mode,
      pattern: patternRaw,
      caseSensitive: caseSensitive,
      flags: flags,
    );
  }

  static GraphFilterTags? _decodeTags(Object? raw) {
    if (raw is! Map) return null;
    final UyavaFilterTagsMode mode =
        _parseTagsMode(raw['mode']) ?? UyavaFilterTagsMode.include;
    final UyavaFilterTagLogic logic =
        _parseTagLogic(raw['logic']) ?? UyavaFilterTagLogic.any;

    final Iterable<Object?>? valuesRaw = raw['values'] is Iterable
        ? raw['values'] as Iterable<Object?>
        : null;
    if (valuesRaw == null) {
      return null;
    }
    final List<String> values = <String>[];
    for (final Object? entry in valuesRaw) {
      if (entry is String && entry.trim().isNotEmpty) {
        values.add(entry);
      }
    }
    if (values.isEmpty) {
      return null;
    }
    final UyavaTagNormalizationResult normalized = normalizeTags(values);
    if (!normalized.hasValues) {
      return null;
    }
    final UyavaFilterTagLogic effectiveLogic = mode == UyavaFilterTagsMode.exact
        ? UyavaFilterTagLogic.all
        : logic;

    return GraphFilterTags(
      mode: mode,
      values: normalized.values,
      valuesNormalized: normalized.normalized,
      logic: effectiveLogic,
    );
  }

  static GraphFilterNodeSet? _decodeNodeSet(Object? raw) {
    if (raw is! Map) return null;
    final Iterable<Object?>? includeRaw = raw['include'] is Iterable
        ? raw['include'] as Iterable<Object?>
        : null;
    final Iterable<Object?>? excludeRaw = raw['exclude'] is Iterable
        ? raw['exclude'] as Iterable<Object?>
        : null;

    final List<String> include = <String>[];
    if (includeRaw != null) {
      for (final Object? entry in includeRaw) {
        if (entry is String && entry.trim().isNotEmpty) {
          include.add(entry.trim());
        }
      }
    }

    final List<String> exclude = <String>[];
    if (excludeRaw != null) {
      for (final Object? entry in excludeRaw) {
        if (entry is String && entry.trim().isNotEmpty) {
          exclude.add(entry.trim());
        }
      }
    }

    if (include.isEmpty && exclude.isEmpty) {
      return null;
    }
    return GraphFilterNodeSet(include: include, exclude: exclude);
  }

  static GraphFilterParent? _decodeParent(Object? raw) {
    if (raw is! Map) return null;
    final String? rootId = raw['rootId'] is String
        ? (raw['rootId'] as String).trim()
        : null;
    final Object? depthRaw = raw['depth'];
    int? depth;
    if (depthRaw is num) {
      depth = depthRaw.toInt();
    } else if (depthRaw is String && depthRaw.isNotEmpty) {
      depth = int.tryParse(depthRaw);
    }
    final bool hasRoot = rootId != null && rootId.isNotEmpty;
    if (!hasRoot && depth == null) {
      return null;
    }
    return GraphFilterParent(rootId: hasRoot ? rootId : null, depth: depth);
  }

  static GraphFilterGrouping? _decodeGrouping(Object? raw) {
    if (raw is! Map) return null;
    final UyavaFilterGroupingMode mode =
        _parseGroupingMode(raw['mode']) ?? UyavaFilterGroupingMode.none;
    int? levelDepth;
    final Object? depthRaw = raw['levelDepth'];
    if (depthRaw is num) {
      levelDepth = depthRaw.toInt();
    } else if (depthRaw is String && depthRaw.isNotEmpty) {
      levelDepth = int.tryParse(depthRaw);
    }
    if (mode == UyavaFilterGroupingMode.none && levelDepth == null) {
      return null;
    }
    return GraphFilterGrouping(
      mode: mode,
      levelDepth: mode == UyavaFilterGroupingMode.level ? levelDepth : null,
    );
  }

  static GraphFilterSeverity? _decodeSeverity(Object? raw) {
    if (raw is! Map) return null;
    final UyavaFilterSeverityOperator? operator = _parseSeverityOperator(
      raw['operator'],
    );
    if (operator == null) {
      return null;
    }
    final UyavaSeverity? level = _parseSeverityLevel(raw['level']);
    if (level == null) {
      return null;
    }
    return GraphFilterSeverity(operator: operator, level: level);
  }

  static UyavaFilterSearchMode? _parseSearchMode(Object? raw) {
    if (raw is! String) return null;
    for (final UyavaFilterSearchMode mode in UyavaFilterSearchMode.values) {
      if (mode.name == raw) return mode;
    }
    return null;
  }

  static UyavaFilterTagsMode? _parseTagsMode(Object? raw) {
    if (raw is! String) return null;
    for (final UyavaFilterTagsMode mode in UyavaFilterTagsMode.values) {
      if (mode.name == raw) return mode;
    }
    return null;
  }

  static UyavaFilterTagLogic? _parseTagLogic(Object? raw) {
    if (raw is! String) return null;
    for (final UyavaFilterTagLogic logic in UyavaFilterTagLogic.values) {
      if (logic.name == raw) return logic;
    }
    return null;
  }

  static UyavaFilterGroupingMode? _parseGroupingMode(Object? raw) {
    if (raw is! String) return null;
    for (final UyavaFilterGroupingMode mode in UyavaFilterGroupingMode.values) {
      if (mode.name == raw) return mode;
    }
    return null;
  }

  static UyavaFilterSeverityOperator? _parseSeverityOperator(Object? raw) {
    if (raw is! String) return null;
    for (final UyavaFilterSeverityOperator op
        in UyavaFilterSeverityOperator.values) {
      if (op.name == raw) return op;
    }
    return null;
  }

  static UyavaSeverity? _parseSeverityLevel(Object? raw) {
    if (raw is! String) return null;
    for (final UyavaSeverity sev in UyavaSeverity.values) {
      if (sev.name == raw) return sev;
    }
    return null;
  }
}
