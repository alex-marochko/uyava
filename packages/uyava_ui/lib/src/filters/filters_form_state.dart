import 'package:flutter/foundation.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

/// Immutable snapshot of the filter form values.
@immutable
class FiltersFormState {
  const FiltersFormState({
    this.pattern = '',
    this.searchMode = UyavaFilterSearchMode.substring,
    this.caseSensitive = false,
    this.tagsMode = UyavaFilterTagsMode.include,
    this.tagsLogic = UyavaFilterTagLogic.any,
    this.selectableTagsLogic = UyavaFilterTagLogic.any,
    this.selectedTags = const <String>[],
    this.nodeMode = FiltersNodeMode.include,
    this.selectedNodeIds = const <String>[],
    this.groupingMode = UyavaFilterGroupingMode.none,
    this.groupingDepth,
    this.severityOperator = UyavaFilterSeverityOperator.atLeast,
    this.selectedSeverity,
  });

  /// Default state used when filters are reset.
  static const FiltersFormState defaults = FiltersFormState();

  final String pattern;
  final UyavaFilterSearchMode searchMode;
  final bool caseSensitive;
  final UyavaFilterTagsMode tagsMode;
  final UyavaFilterTagLogic tagsLogic;
  final UyavaFilterTagLogic selectableTagsLogic;
  final List<String> selectedTags;
  final FiltersNodeMode nodeMode;
  final List<String> selectedNodeIds;
  final UyavaFilterGroupingMode groupingMode;
  final int? groupingDepth;
  final UyavaFilterSeverityOperator severityOperator;
  final UyavaSeverity? selectedSeverity;

  bool get hasPattern => pattern.trim().isNotEmpty;
  bool get hasTags => selectedTags.isNotEmpty;
  bool get hasNodes => selectedNodeIds.isNotEmpty;
  bool get hasSeverity => selectedSeverity != null;

  bool get hasActiveFilters => hasPattern || hasTags || hasNodes || hasSeverity;

  FiltersFormState copyWith({
    String? pattern,
    UyavaFilterSearchMode? searchMode,
    bool? caseSensitive,
    UyavaFilterTagsMode? tagsMode,
    UyavaFilterTagLogic? tagsLogic,
    UyavaFilterTagLogic? selectableTagsLogic,
    List<String>? selectedTags,
    FiltersNodeMode? nodeMode,
    List<String>? selectedNodeIds,
    UyavaFilterGroupingMode? groupingMode,
    int? groupingDepth,
    bool clearGroupingDepth = false,
    UyavaFilterSeverityOperator? severityOperator,
    UyavaSeverity? selectedSeverity,
    bool clearSelectedSeverity = false,
  }) {
    return FiltersFormState(
      pattern: pattern ?? this.pattern,
      searchMode: searchMode ?? this.searchMode,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      tagsMode: tagsMode ?? this.tagsMode,
      tagsLogic: tagsLogic ?? this.tagsLogic,
      selectableTagsLogic: selectableTagsLogic ?? this.selectableTagsLogic,
      selectedTags: selectedTags == null
          ? List<String>.from(this.selectedTags)
          : List<String>.from(selectedTags),
      nodeMode: nodeMode ?? this.nodeMode,
      selectedNodeIds: selectedNodeIds == null
          ? List<String>.from(this.selectedNodeIds)
          : List<String>.from(selectedNodeIds),
      groupingMode: groupingMode ?? this.groupingMode,
      groupingDepth: clearGroupingDepth
          ? null
          : (groupingDepth ?? this.groupingDepth),
      severityOperator: severityOperator ?? this.severityOperator,
      selectedSeverity: clearSelectedSeverity
          ? null
          : (selectedSeverity ?? this.selectedSeverity),
    );
  }

  /// Builds a state snapshot from the provided controller state.
  static FiltersFormState fromGraphFilterState(
    GraphFilterState state, {
    FiltersFormState? fallback,
    required bool forceDefaults,
  }) {
    final FiltersFormState base = fallback ?? FiltersFormState.defaults;
    final GraphFilterSearch? search = state.search;
    final GraphFilterTags? tags = state.tags;
    final GraphFilterNodeSet? nodes = state.nodes;
    final GraphFilterGrouping? grouping = state.grouping;
    final GraphFilterSeverity? severity = state.severity;

    final FiltersFormState defaults = FiltersFormState.defaults;

    final String pattern = search?.pattern ?? '';
    final UyavaFilterSearchMode searchMode =
        search?.mode ?? (forceDefaults ? defaults.searchMode : base.searchMode);
    final bool caseSensitive =
        search?.caseSensitive ??
        (forceDefaults ? defaults.caseSensitive : base.caseSensitive);

    final UyavaFilterTagsMode tagsMode =
        tags?.mode ?? (forceDefaults ? defaults.tagsMode : base.tagsMode);
    final List<String> selectedTags =
        tags?.values.toList(growable: false) ?? const <String>[];

    final bool isExactTags = tagsMode == UyavaFilterTagsMode.exact;
    final UyavaFilterTagLogic tagsLogic;
    final UyavaFilterTagLogic selectableTagsLogic;
    if (tags != null && !isExactTags) {
      tagsLogic = tags.logic;
      selectableTagsLogic = tags.logic;
    } else {
      tagsLogic = isExactTags
          ? UyavaFilterTagLogic.all
          : (forceDefaults ? defaults.tagsLogic : base.tagsLogic);
      selectableTagsLogic = forceDefaults
          ? defaults.selectableTagsLogic
          : base.selectableTagsLogic;
    }

    FiltersNodeMode nodeMode = FiltersNodeMode.include;
    List<String> selectedNodeIds = const <String>[];
    if (nodes != null &&
        (nodes.include.isNotEmpty || nodes.exclude.isNotEmpty)) {
      if (nodes.include.isNotEmpty) {
        nodeMode = FiltersNodeMode.include;
        selectedNodeIds = nodes.include.toList(growable: false);
      } else {
        nodeMode = FiltersNodeMode.exclude;
        selectedNodeIds = nodes.exclude.toList(growable: false);
      }
    } else if (!forceDefaults) {
      nodeMode = base.nodeMode;
    }

    final UyavaFilterGroupingMode groupingMode =
        grouping?.mode ?? UyavaFilterGroupingMode.none;
    final int? groupingDepth = grouping?.levelDepth;

    final UyavaFilterSeverityOperator severityOperator =
        severity?.operator ??
        (forceDefaults ? defaults.severityOperator : base.severityOperator);
    final UyavaSeverity? selectedSeverity = severity?.level;

    return FiltersFormState(
      pattern: pattern,
      searchMode: searchMode,
      caseSensitive: caseSensitive,
      tagsMode: tagsMode,
      tagsLogic: tagsLogic,
      selectableTagsLogic: selectableTagsLogic,
      selectedTags: selectedTags,
      nodeMode: nodeMode,
      selectedNodeIds: selectedNodeIds,
      groupingMode: groupingMode,
      groupingDepth: groupingDepth,
      severityOperator: severityOperator,
      selectedSeverity: selectedSeverity,
    );
  }

  FiltersFormState cycleSearchMode() {
    final List<UyavaFilterSearchMode> values = UyavaFilterSearchMode.values;
    final int index = values.indexOf(searchMode);
    final UyavaFilterSearchMode next = values[(index + 1) % values.length];
    return copyWith(searchMode: next);
  }

  FiltersFormState toggleCaseSensitive() {
    return copyWith(caseSensitive: !caseSensitive);
  }

  FiltersFormState cycleTagsMode() {
    switch (tagsMode) {
      case UyavaFilterTagsMode.include:
        return copyWith(
          tagsMode: UyavaFilterTagsMode.exclude,
          tagsLogic: selectableTagsLogic,
        );
      case UyavaFilterTagsMode.exclude:
        return copyWith(
          tagsMode: UyavaFilterTagsMode.exact,
          tagsLogic: UyavaFilterTagLogic.all,
        );
      case UyavaFilterTagsMode.exact:
        return copyWith(
          tagsMode: UyavaFilterTagsMode.include,
          tagsLogic: selectableTagsLogic,
        );
    }
  }

  FiltersFormState cycleTagsLogic() {
    if (tagsMode == UyavaFilterTagsMode.exact) return this;
    final UyavaFilterTagLogic next = tagsLogic == UyavaFilterTagLogic.any
        ? UyavaFilterTagLogic.all
        : UyavaFilterTagLogic.any;
    return copyWith(tagsLogic: next, selectableTagsLogic: next);
  }

  FiltersFormState toggleNodeMode() {
    return copyWith(
      nodeMode: nodeMode == FiltersNodeMode.include
          ? FiltersNodeMode.exclude
          : FiltersNodeMode.include,
    );
  }

  FiltersFormState withPattern(String value) {
    return copyWith(pattern: value);
  }

  FiltersFormState withSelectedTags(List<String> tags) {
    return copyWith(selectedTags: List<String>.from(tags));
  }

  FiltersFormState withSelectedNodeIds(List<String> ids) {
    return copyWith(selectedNodeIds: List<String>.from(ids));
  }

  FiltersFormState clearTags() => copyWith(selectedTags: <String>[]);

  FiltersFormState clearNodes() => copyWith(selectedNodeIds: <String>[]);

  FiltersFormState clearSeverity() => copyWith(clearSelectedSeverity: true);

  FiltersFormState withSeverity(UyavaSeverity? severity) {
    return copyWith(selectedSeverity: severity);
  }

  FiltersFormState withSeverityOperator(UyavaFilterSeverityOperator operator) {
    return copyWith(severityOperator: operator);
  }

  FiltersFormState pruneSelections({
    Set<String>? validNodeIds,
    Set<String>? validTags,
    Set<int>? validGroupingDepths,
  }) {
    FiltersFormState next = this;

    if (validNodeIds != null && validNodeIds.isNotEmpty) {
      final List<String> retained = selectedNodeIds
          .where((id) => validNodeIds.contains(id))
          .toList(growable: false);
      if (!listEquals(retained, selectedNodeIds)) {
        next = next.copyWith(selectedNodeIds: retained);
      }
    }

    if (validTags != null && validTags.isNotEmpty) {
      final List<String> retained = selectedTags
          .where((tag) => validTags.contains(tag))
          .toList(growable: false);
      if (!listEquals(retained, selectedTags)) {
        next = next.copyWith(selectedTags: retained);
      }
    }

    if (groupingMode == UyavaFilterGroupingMode.level &&
        groupingDepth != null &&
        validGroupingDepths != null &&
        !validGroupingDepths.contains(groupingDepth)) {
      next = next.copyWith(
        groupingMode: UyavaFilterGroupingMode.none,
        clearGroupingDepth: true,
      );
    }

    return next;
  }

  GraphFilterState toGraphFilterState() {
    GraphFilterSearch? search;
    final String trimmedPattern = pattern.trim();
    if (trimmedPattern.isNotEmpty) {
      search = GraphFilterSearch(
        mode: searchMode,
        pattern: trimmedPattern,
        caseSensitive: caseSensitive,
      );
    }

    GraphFilterNodeSet? nodes;
    if (selectedNodeIds.isNotEmpty) {
      if (nodeMode == FiltersNodeMode.include) {
        nodes = GraphFilterNodeSet(
          include: List<String>.from(selectedNodeIds),
          exclude: const <String>[],
        );
      } else {
        nodes = GraphFilterNodeSet(
          include: const <String>[],
          exclude: List<String>.from(selectedNodeIds),
        );
      }
    }

    GraphFilterTags? tags;
    if (selectedTags.isNotEmpty) {
      final normalization = normalizeTags(selectedTags);
      if (normalization.hasValues) {
        final UyavaFilterTagLogic logic = tagsMode == UyavaFilterTagsMode.exact
            ? UyavaFilterTagLogic.all
            : tagsLogic;
        tags = GraphFilterTags(
          mode: tagsMode,
          values: normalization.values,
          valuesNormalized: normalization.normalized,
          logic: logic,
        );
      }
    }

    GraphFilterGrouping? grouping;
    if (groupingMode == UyavaFilterGroupingMode.level &&
        groupingDepth != null) {
      grouping = GraphFilterGrouping(
        mode: groupingMode,
        levelDepth: groupingDepth,
      );
    }

    GraphFilterSeverity? severity;
    if (selectedSeverity != null) {
      severity = GraphFilterSeverity(
        operator: severityOperator,
        level: selectedSeverity!,
      );
    }

    return GraphFilterState(
      search: search,
      tags: tags,
      nodes: nodes,
      grouping: grouping,
      severity: severity,
    );
  }
}

enum FiltersNodeMode { include, exclude }
