import 'package:collection/collection.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'graph_event_chains.dart';
import 'graph_metrics.dart';
import 'uyava_edge.dart';
import 'uyava_node.dart';

/// Immutable snapshot of active graph filters.
class GraphFilterState {
  const GraphFilterState({
    this.search,
    this.tags,
    this.nodes,
    this.parent,
    this.grouping,
    this.severity,
  });

  /// Empty filter set (no restrictions).
  static const GraphFilterState empty = GraphFilterState();

  final GraphFilterSearch? search;
  final GraphFilterTags? tags;
  final GraphFilterNodeSet? nodes;
  final GraphFilterParent? parent;
  final GraphFilterGrouping? grouping;
  final GraphFilterSeverity? severity;

  bool get isEmpty =>
      search == null &&
      tags == null &&
      nodes == null &&
      parent == null &&
      grouping == null &&
      severity == null;

  factory GraphFilterState.fromPayload(UyavaGraphFilterCommandPayload payload) {
    GraphFilterSearch? search;
    if (payload.search != null) {
      final UyavaGraphFilterSearchPayload raw = payload.search!;
      if (raw.pattern.isNotEmpty) {
        search = GraphFilterSearch(
          mode: raw.mode,
          pattern: raw.pattern,
          caseSensitive: raw.caseSensitive,
          flags: raw.flags,
        );
      }
    }

    GraphFilterTags? tags;
    if (payload.tags != null) {
      final UyavaGraphFilterTagsPayload raw = payload.tags!;
      if (raw.valuesNormalized.isNotEmpty) {
        tags = GraphFilterTags(
          mode: raw.mode,
          values: raw.values,
          valuesNormalized: raw.valuesNormalized,
          logic: raw.logic,
        );
      }
    }

    GraphFilterNodeSet? nodes;
    if (payload.nodes != null) {
      final UyavaGraphFilterIdSetPayload raw = payload.nodes!;
      if (raw.include.isNotEmpty || raw.exclude.isNotEmpty) {
        nodes = GraphFilterNodeSet(include: raw.include, exclude: raw.exclude);
      }
    }

    GraphFilterParent? parent;
    if (payload.parent != null) {
      final UyavaGraphFilterParentPayload raw = payload.parent!;
      if (raw.rootId != null || raw.depth != null) {
        parent = GraphFilterParent(rootId: raw.rootId, depth: raw.depth);
      }
    }

    GraphFilterGrouping? grouping;
    if (payload.grouping != null) {
      final UyavaGraphFilterGroupingPayload raw = payload.grouping!;
      if (raw.mode != UyavaFilterGroupingMode.none || raw.levelDepth != null) {
        grouping = GraphFilterGrouping(
          mode: raw.mode,
          levelDepth: raw.levelDepth,
        );
      }
    }

    GraphFilterSeverity? severity;
    if (payload.severity != null) {
      final UyavaGraphFilterSeverityPayload raw = payload.severity!;
      severity = GraphFilterSeverity(operator: raw.operator, level: raw.level);
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

  GraphFilterState copyWith({
    GraphFilterSearch? search,
    GraphFilterTags? tags,
    GraphFilterNodeSet? nodes,
    GraphFilterParent? parent,
    GraphFilterGrouping? grouping,
    GraphFilterSeverity? severity,
  }) {
    return GraphFilterState(
      search: search ?? this.search,
      tags: tags ?? this.tags,
      nodes: nodes ?? this.nodes,
      parent: parent ?? this.parent,
      grouping: grouping ?? this.grouping,
      severity: severity ?? this.severity,
    );
  }

  @override
  int get hashCode =>
      Object.hash(search, tags, nodes, parent, grouping, severity);

  @override
  bool operator ==(Object other) {
    return other is GraphFilterState &&
        other.search == search &&
        other.tags == tags &&
        other.nodes == nodes &&
        other.parent == parent &&
        other.grouping == grouping &&
        other.severity == severity;
  }
}

/// Search filter configuration.
class GraphFilterSearch {
  GraphFilterSearch({
    required this.mode,
    required this.pattern,
    required this.caseSensitive,
    this.flags,
  }) : _matcher = _GraphSearchMatcher.build(
         mode: mode,
         pattern: pattern,
         caseSensitive: caseSensitive,
         flags: flags,
       );

  final UyavaFilterSearchMode mode;
  final String pattern;
  final bool caseSensitive;
  final String? flags;

  final _GraphSearchMatcher _matcher;

  bool matchesNode(UyavaNode node) {
    return _matcher.matches(node.id) || _matcher.matches(node.label);
  }

  bool matchesEdge(UyavaEdge edge) {
    return _matcher.matches(edge.id) ||
        _matcher.matches(edge.payload.label ?? '');
  }

  bool matchesMetric(GraphMetricSnapshot metric) {
    return _matcher.matches(metric.id) ||
        _matcher.matches(metric.definition.label ?? '');
  }

  bool matchesChain(GraphEventChainSnapshot chain) {
    final definition = chain.definition;
    return _matcher.matches(definition.id) ||
        _matcher.matches(definition.label ?? '');
  }

  @override
  int get hashCode => Object.hash(mode, pattern, caseSensitive, flags ?? '');

  @override
  bool operator ==(Object other) {
    return other is GraphFilterSearch &&
        other.mode == mode &&
        other.pattern == pattern &&
        other.caseSensitive == caseSensitive &&
        other.flags == flags;
  }
}

abstract class _GraphSearchMatcher {
  factory _GraphSearchMatcher.build({
    required UyavaFilterSearchMode mode,
    required String pattern,
    required bool caseSensitive,
    String? flags,
  }) {
    switch (mode) {
      case UyavaFilterSearchMode.substring:
        return _SubstringMatcher(pattern, caseSensitive);
      case UyavaFilterSearchMode.mask:
        return _MaskMatcher(pattern, caseSensitive);
      case UyavaFilterSearchMode.regex:
        return _RegexMatcher(pattern, caseSensitive, flags);
    }
  }

  bool matches(String? value);
}

class _SubstringMatcher implements _GraphSearchMatcher {
  _SubstringMatcher(String pattern, bool caseSensitive)
    : _pattern = caseSensitive ? pattern : pattern.toLowerCase(),
      _caseSensitive = caseSensitive;

  final String _pattern;
  final bool _caseSensitive;

  @override
  bool matches(String? value) {
    if (value == null) return false;
    final candidate = _caseSensitive ? value : value.toLowerCase();
    return candidate.contains(_pattern);
  }
}

class _MaskMatcher implements _GraphSearchMatcher {
  _MaskMatcher(String mask, bool caseSensitive)
    : _regex = _maskToRegex(mask, caseSensitive);

  final RegExp _regex;

  static RegExp _maskToRegex(String mask, bool caseSensitive) {
    final buffer = StringBuffer();
    for (final rune in mask.runes) {
      final char = String.fromCharCode(rune);
      switch (char) {
        case '*':
          buffer.write('.*');
          break;
        case '?':
          buffer.write('.');
          break;
        default:
          buffer.write(RegExp.escape(char));
      }
    }
    return RegExp(buffer.toString(), caseSensitive: caseSensitive);
  }

  @override
  bool matches(String? value) {
    if (value == null) return false;
    return _regex.hasMatch(value);
  }
}

class _RegexMatcher implements _GraphSearchMatcher {
  _RegexMatcher(String pattern, bool caseSensitive, String? flags)
    : _regex = RegExp(
        pattern,
        caseSensitive: caseSensitive,
        multiLine: flags?.contains('m') ?? false,
        unicode: flags?.contains('u') ?? false,
        dotAll: flags?.contains('s') ?? false,
      );

  final RegExp _regex;

  @override
  bool matches(String? value) {
    if (value == null) return false;
    return _regex.hasMatch(value);
  }
}

/// Tag filter configuration.
class GraphFilterTags {
  GraphFilterTags({
    required this.mode,
    required List<String> values,
    required List<String> valuesNormalized,
    required this.logic,
  }) : values = List<String>.unmodifiable(values),
       valuesNormalized = List<String>.unmodifiable(valuesNormalized),
       _normalizedSet = Set<String>.unmodifiable(valuesNormalized),
       _setEquality = const SetEquality<String>();

  final UyavaFilterTagsMode mode;
  final List<String> values;
  final List<String> valuesNormalized;
  final UyavaFilterTagLogic logic;

  final Set<String> _normalizedSet;
  final SetEquality<String> _setEquality;

  bool get isEmpty => _normalizedSet.isEmpty;

  bool matchesNode(UyavaNode node) {
    return _matches(node.payload.tagsNormalized);
  }

  bool matchesMetric(GraphMetricSnapshot metric) {
    final List<String> normalized = metric.definition.tagsNormalized;
    if (normalized.isNotEmpty) {
      return _matches(normalized);
    }
    final List<String> fallback = <String>[
      for (final String tag in metric.definition.tags) tag.toLowerCase(),
    ];
    return _matches(fallback);
  }

  bool matchesChain(GraphEventChainSnapshot chain) {
    final List<String> normalized = chain.definition.tagsNormalized;
    if (normalized.isNotEmpty) {
      return _matches(normalized);
    }
    final List<String> fallback = <String>[
      for (final String tag in chain.definition.tags) tag.toLowerCase(),
    ];
    return _matches(fallback);
  }

  bool _matches(List<String> candidateNormalized) {
    if (_normalizedSet.isEmpty) {
      if (mode == UyavaFilterTagsMode.exact) {
        return candidateNormalized.isEmpty;
      }
      // No values to filter by for include/exclude; treat as pass-through.
      return true;
    }
    final Set<String> candidateSet = Set<String>.from(candidateNormalized);
    final bool containsAny = candidateNormalized.any(_normalizedSet.contains);
    final bool containsAll = _normalizedSet.every(
      (value) => candidateSet.contains(value),
    );

    switch (mode) {
      case UyavaFilterTagsMode.include:
        return logic == UyavaFilterTagLogic.any ? containsAny : containsAll;
      case UyavaFilterTagsMode.exclude:
        return logic == UyavaFilterTagLogic.any ? !containsAny : !containsAll;
      case UyavaFilterTagsMode.exact:
        return _setEquality.equals(candidateSet, _normalizedSet);
    }
  }

  @override
  int get hashCode =>
      Object.hash(mode, logic, Object.hashAll(valuesNormalized));

  @override
  bool operator ==(Object other) {
    return other is GraphFilterTags &&
        other.mode == mode &&
        other.logic == logic &&
        const ListEquality<String>().equals(
          other.valuesNormalized,
          valuesNormalized,
        );
  }
}

/// Explicit include/exclude node lists.
class GraphFilterNodeSet {
  GraphFilterNodeSet({
    required List<String> include,
    required List<String> exclude,
  }) : include = Set<String>.unmodifiable(include),
       exclude = Set<String>.unmodifiable(exclude);

  final Set<String> include;
  final Set<String> exclude;

  bool get hasInclude => include.isNotEmpty;
  bool get hasExclude => exclude.isNotEmpty;

  bool allows(String id) {
    if (exclude.contains(id)) return false;
    if (include.isEmpty) return true;
    return include.contains(id);
  }

  Iterable<String> unknownIds(Iterable<String> knownIds) {
    final Set<String> known = Set<String>.from(knownIds);
    final List<String> unknown = <String>[];
    for (final id in include) {
      if (!known.contains(id)) unknown.add(id);
    }
    for (final id in exclude) {
      if (!known.contains(id)) unknown.add(id);
    }
    return unknown;
  }

  @override
  int get hashCode =>
      Object.hashAll([Object.hashAll(include), Object.hashAll(exclude)]);

  @override
  bool operator ==(Object other) {
    return other is GraphFilterNodeSet &&
        const SetEquality<String>().equals(other.include, include) &&
        const SetEquality<String>().equals(other.exclude, exclude);
  }
}

/// Optional parent scoping information.
class GraphFilterParent {
  const GraphFilterParent({this.rootId, this.depth});

  final String? rootId;
  final int? depth;

  @override
  int get hashCode => Object.hash(rootId, depth);

  @override
  bool operator ==(Object other) {
    return other is GraphFilterParent &&
        other.rootId == rootId &&
        other.depth == depth;
  }
}

/// Grouping mode configuration.
class GraphFilterGrouping {
  const GraphFilterGrouping({required this.mode, this.levelDepth});

  final UyavaFilterGroupingMode mode;
  final int? levelDepth;

  @override
  int get hashCode => Object.hash(mode, levelDepth);

  @override
  bool operator ==(Object other) {
    return other is GraphFilterGrouping &&
        other.mode == mode &&
        other.levelDepth == levelDepth;
  }
}

/// Severity filter configuration applied to runtime events.
class GraphFilterSeverity {
  const GraphFilterSeverity({required this.operator, required this.level});

  final UyavaFilterSeverityOperator operator;
  final UyavaSeverity level;

  bool matches(UyavaSeverity? candidate) {
    final int threshold = level.index;
    final int value = candidate?.index ?? UyavaSeverity.info.index;
    switch (operator) {
      case UyavaFilterSeverityOperator.atLeast:
        return value >= threshold;
      case UyavaFilterSeverityOperator.atMost:
        return value <= threshold;
      case UyavaFilterSeverityOperator.exact:
        return value == threshold;
    }
  }

  @override
  int get hashCode => Object.hash(operator, level);

  @override
  bool operator ==(Object other) {
    return other is GraphFilterSeverity &&
        other.operator == operator &&
        other.level == level;
  }
}
