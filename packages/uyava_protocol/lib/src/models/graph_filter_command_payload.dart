// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../graph_integrity_codes.dart';
import '../../graph_diagnostic_level.dart';
import '../../normalization.dart';
import '../base_types.dart';

import 'graph_diagnostic_payload.dart';

part 'graph_filter_command_payload.freezed.dart';
part 'graph_filter_command_payload.g.dart';

/// Composite payload describing graph filter updates.
@Freezed(toJson: true)
class UyavaGraphFilterCommandPayload with _$UyavaGraphFilterCommandPayload {
  const UyavaGraphFilterCommandPayload._();

  @JsonSerializable(explicitToJson: true)
  const factory UyavaGraphFilterCommandPayload({
    UyavaGraphFilterSearchPayload? search,
    UyavaGraphFilterTagsPayload? tags,
    UyavaGraphFilterIdSetPayload? nodes,
    UyavaGraphFilterIdSetPayload? edges,
    UyavaGraphFilterParentPayload? parent,
    UyavaGraphFilterGroupingPayload? grouping,
    UyavaGraphFilterSeverityPayload? severity,
  }) = _UyavaGraphFilterCommandPayload;

  factory UyavaGraphFilterCommandPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphFilterCommandPayloadFromJson(json);

  /// Normalizes raw command payloads and surfaces diagnostics.
  static UyavaGraphFilterSanitizationResult sanitize(Map<String, dynamic> raw) {
    final Map<String, dynamic> working = Map<String, dynamic>.from(raw);
    final List<UyavaGraphDiagnosticPayload> diagnostics =
        <UyavaGraphDiagnosticPayload>[];

    final _Section<UyavaGraphFilterSearchPayload> search = _parseSearch(
      working['search'],
    );
    final _Section<UyavaGraphFilterTagsPayload> tags = _parseTags(
      working['tags'],
    );
    final _Section<UyavaGraphFilterIdSetPayload> nodes = _parseIdSet(
      working['nodes'],
    );
    final _Section<UyavaGraphFilterIdSetPayload> edges = _parseIdSet(
      working['edges'],
    );
    final _Section<UyavaGraphFilterParentPayload> parent = _parseParent(
      working['parent'],
    );
    final _Section<UyavaGraphFilterGroupingPayload> grouping = _parseGrouping(
      working['grouping'],
    );
    final _Section<UyavaGraphFilterSeverityPayload> severity = _parseSeverity(
      working['severity'],
    );

    diagnostics
      ..addAll(search.diagnostics)
      ..addAll(tags.diagnostics)
      ..addAll(nodes.diagnostics)
      ..addAll(edges.diagnostics)
      ..addAll(parent.diagnostics)
      ..addAll(grouping.diagnostics)
      ..addAll(severity.diagnostics);

    final Map<String, dynamic> sanitized = <String, dynamic>{};
    if (search.payload != null) {
      sanitized['search'] = search.payload!.toJson();
    }
    if (tags.payload != null) {
      sanitized['tags'] = tags.payload!.toJson();
    }
    if (nodes.payload != null) {
      sanitized['nodes'] = nodes.payload!.toJson();
    }
    if (edges.payload != null) {
      sanitized['edges'] = edges.payload!.toJson();
    }
    if (parent.payload != null) {
      sanitized['parent'] = parent.payload!.toJson();
    }
    if (grouping.payload != null) {
      sanitized['grouping'] = grouping.payload!.toJson();
    }
    if (severity.payload != null) {
      sanitized['severity'] = severity.payload!.toJson();
    }

    final UyavaGraphFilterCommandPayload payload =
        UyavaGraphFilterCommandPayload.fromJson(sanitized);

    final bool isValid = diagnostics
        .where((d) => d.level == UyavaDiagnosticLevel.error)
        .isEmpty;

    return UyavaGraphFilterSanitizationResult(
      payload: payload,
      diagnostics: diagnostics,
      isValid: isValid,
    );
  }
}

@Freezed(toJson: true)
class UyavaGraphFilterSearchPayload with _$UyavaGraphFilterSearchPayload {
  const UyavaGraphFilterSearchPayload._();

  const factory UyavaGraphFilterSearchPayload({
    required UyavaFilterSearchMode mode,
    required String pattern,
    @Default(false) bool caseSensitive,
    String? flags,
  }) = _UyavaGraphFilterSearchPayload;

  factory UyavaGraphFilterSearchPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphFilterSearchPayloadFromJson(json);
}

@Freezed(toJson: true)
class UyavaGraphFilterTagsPayload with _$UyavaGraphFilterTagsPayload {
  const UyavaGraphFilterTagsPayload._();

  const factory UyavaGraphFilterTagsPayload({
    required UyavaFilterTagsMode mode,
    @Default(<String>[]) List<String> values,
    @JsonKey(name: 'valuesNormalized')
    @Default(<String>[])
    List<String> valuesNormalized,
    @JsonKey(name: 'logic')
    @Default(UyavaFilterTagLogic.any)
    UyavaFilterTagLogic logic,
  }) = _UyavaGraphFilterTagsPayload;

  factory UyavaGraphFilterTagsPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphFilterTagsPayloadFromJson(json);
}

@Freezed(toJson: true)
class UyavaGraphFilterIdSetPayload with _$UyavaGraphFilterIdSetPayload {
  const UyavaGraphFilterIdSetPayload._();

  const factory UyavaGraphFilterIdSetPayload({
    @Default(<String>[]) List<String> include,
    @Default(<String>[]) List<String> exclude,
  }) = _UyavaGraphFilterIdSetPayload;

  factory UyavaGraphFilterIdSetPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphFilterIdSetPayloadFromJson(json);
}

@Freezed(toJson: true)
class UyavaGraphFilterParentPayload with _$UyavaGraphFilterParentPayload {
  const UyavaGraphFilterParentPayload._();

  const factory UyavaGraphFilterParentPayload({String? rootId, int? depth}) =
      _UyavaGraphFilterParentPayload;

  factory UyavaGraphFilterParentPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphFilterParentPayloadFromJson(json);
}

@Freezed(toJson: true)
class UyavaGraphFilterGroupingPayload with _$UyavaGraphFilterGroupingPayload {
  const UyavaGraphFilterGroupingPayload._();

  const factory UyavaGraphFilterGroupingPayload({
    required UyavaFilterGroupingMode mode,
    int? levelDepth,
  }) = _UyavaGraphFilterGroupingPayload;

  factory UyavaGraphFilterGroupingPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphFilterGroupingPayloadFromJson(json);
}

@Freezed(toJson: true)
class UyavaGraphFilterSeverityPayload with _$UyavaGraphFilterSeverityPayload {
  const UyavaGraphFilterSeverityPayload._();

  const factory UyavaGraphFilterSeverityPayload({
    required UyavaFilterSeverityOperator operator,
    required UyavaSeverity level,
  }) = _UyavaGraphFilterSeverityPayload;

  factory UyavaGraphFilterSeverityPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphFilterSeverityPayloadFromJson(json);
}

class UyavaGraphFilterSanitizationResult {
  const UyavaGraphFilterSanitizationResult({
    required this.payload,
    required this.diagnostics,
    required this.isValid,
  });

  final UyavaGraphFilterCommandPayload payload;
  final List<UyavaGraphDiagnosticPayload> diagnostics;
  final bool isValid;
}

class _Section<T> {
  const _Section(this.payload, this.diagnostics);

  final T? payload;
  final List<UyavaGraphDiagnosticPayload> diagnostics;
}

_Section<UyavaGraphFilterSearchPayload> _parseSearch(Object? raw) {
  if (raw is! Map) {
    return _Section<UyavaGraphFilterSearchPayload>(null, const []);
  }

  final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  final List<UyavaGraphDiagnosticPayload> diagnostics =
      <UyavaGraphDiagnosticPayload>[];

  final String? rawMode = _trimmedOrNull(map['mode']);
  UyavaFilterSearchMode mode =
      UyavaFilterSearchModeCodec.fromWireString(rawMode) ??
      UyavaFilterSearchMode.substring;
  if (rawMode != null &&
      UyavaFilterSearchModeCodec.fromWireString(rawMode) == null) {
    diagnostics.add(
      UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.filtersInvalidMode.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.filtersInvalidMode,
        level: UyavaGraphIntegrityCode.filtersInvalidMode.defaultLevel,
        context: <String, Object?>{'mode': rawMode},
      ),
    );
    mode = UyavaFilterSearchMode.substring;
  }

  final String pattern = _trimmedOrNull(map['pattern']) ?? '';
  final Object? rawCaseSensitive = map['caseSensitive'];
  final bool caseSensitive = rawCaseSensitive is bool
      ? rawCaseSensitive
      : false;

  final _FlagResult flagResult = _parseFlags(map['flags']);
  diagnostics.addAll(flagResult.diagnostics);
  final bool effectiveCaseSensitive =
      flagResult.caseSensitiveOverride ?? caseSensitive;

  if (mode == UyavaFilterSearchMode.regex && pattern.isNotEmpty) {
    try {
      RegExp(
        pattern,
        caseSensitive: effectiveCaseSensitive,
        multiLine: flagResult.multiLine,
        unicode: flagResult.unicode,
        dotAll: flagResult.dotAll,
      );
    } on FormatException catch (error) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.filtersInvalidPattern.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.filtersInvalidPattern,
          level: UyavaGraphIntegrityCode.filtersInvalidPattern.defaultLevel,
          context: <String, Object?>{
            'pattern': pattern,
            'error': error.message,
          },
        ),
      );
      return _Section<UyavaGraphFilterSearchPayload>(null, diagnostics);
    }
  }

  if (pattern.isEmpty &&
      mode == UyavaFilterSearchMode.substring &&
      !effectiveCaseSensitive &&
      (flagResult.flags == null || flagResult.flags!.isEmpty)) {
    return _Section<UyavaGraphFilterSearchPayload>(null, diagnostics);
  }

  return _Section<UyavaGraphFilterSearchPayload>(
    UyavaGraphFilterSearchPayload(
      mode: mode,
      pattern: pattern,
      caseSensitive: effectiveCaseSensitive,
      flags: flagResult.flags,
    ),
    diagnostics,
  );
}

_Section<UyavaGraphFilterTagsPayload> _parseTags(Object? raw) {
  if (raw is! Map) {
    return _Section<UyavaGraphFilterTagsPayload>(null, const []);
  }

  final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  final List<UyavaGraphDiagnosticPayload> diagnostics =
      <UyavaGraphDiagnosticPayload>[];

  final String? rawMode = _trimmedOrNull(map['mode']);
  UyavaFilterTagsMode mode =
      UyavaFilterTagsModeCodec.fromWireString(rawMode) ??
      UyavaFilterTagsMode.include;
  if (rawMode != null &&
      UyavaFilterTagsModeCodec.fromWireString(rawMode) == null) {
    diagnostics.add(
      UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.filtersInvalidMode.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.filtersInvalidMode,
        level: UyavaGraphIntegrityCode.filtersInvalidMode.defaultLevel,
        context: <String, Object?>{'mode': rawMode},
      ),
    );
    mode = UyavaFilterTagsMode.include;
  }

  final String? rawLogic = _trimmedOrNull(map['logic']);
  UyavaFilterTagLogic logic =
      UyavaFilterTagLogicCodec.fromWireString(rawLogic) ??
      UyavaFilterTagLogic.any;
  if (rawLogic != null &&
      UyavaFilterTagLogicCodec.fromWireString(rawLogic) == null) {
    diagnostics.add(
      UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.filtersInvalidMode.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.filtersInvalidMode,
        level: UyavaGraphIntegrityCode.filtersInvalidMode.defaultLevel,
        context: <String, Object?>{'logic': rawLogic},
      ),
    );
    logic = UyavaFilterTagLogic.any;
  }

  final UyavaTagNormalizationResult tagData = normalizeTags(map['values']);
  if (!tagData.hasValues) {
    if (!tagData.hadInput) {
      return _Section<UyavaGraphFilterTagsPayload>(null, diagnostics);
    }
    return _Section<UyavaGraphFilterTagsPayload>(
      UyavaGraphFilterTagsPayload(
        mode: mode,
        values: const <String>[],
        valuesNormalized: const <String>[],
        logic: logic,
      ),
      diagnostics,
    );
  }

  return _Section<UyavaGraphFilterTagsPayload>(
    UyavaGraphFilterTagsPayload(
      mode: mode,
      values: tagData.values,
      valuesNormalized: tagData.normalized,
      logic: logic,
    ),
    diagnostics,
  );
}

_Section<UyavaGraphFilterIdSetPayload> _parseIdSet(Object? raw) {
  if (raw is! Map) {
    return _Section<UyavaGraphFilterIdSetPayload>(null, const []);
  }

  final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  final List<String> include = _sanitizeIdList(map['include']);
  final List<String> exclude = _sanitizeIdList(map['exclude']);

  if (include.isEmpty && exclude.isEmpty) {
    return _Section<UyavaGraphFilterIdSetPayload>(null, const []);
  }

  return _Section<UyavaGraphFilterIdSetPayload>(
    UyavaGraphFilterIdSetPayload(include: include, exclude: exclude),
    const [],
  );
}

_Section<UyavaGraphFilterParentPayload> _parseParent(Object? raw) {
  if (raw is! Map) {
    return _Section<UyavaGraphFilterParentPayload>(null, const []);
  }

  final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  final String? rootId = _trimmedOrNull(map['rootId']);
  final int? depth = _sanitizeDepth(map['depth']);

  if (rootId == null && depth == null) {
    return _Section<UyavaGraphFilterParentPayload>(null, const []);
  }

  return _Section<UyavaGraphFilterParentPayload>(
    UyavaGraphFilterParentPayload(rootId: rootId, depth: depth),
    const [],
  );
}

_Section<UyavaGraphFilterGroupingPayload> _parseGrouping(Object? raw) {
  if (raw is! Map) {
    return _Section<UyavaGraphFilterGroupingPayload>(null, const []);
  }

  final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  final List<UyavaGraphDiagnosticPayload> diagnostics =
      <UyavaGraphDiagnosticPayload>[];

  final String? rawMode = _trimmedOrNull(map['mode']);
  UyavaFilterGroupingMode mode =
      UyavaFilterGroupingModeCodec.fromWireString(rawMode) ??
      UyavaFilterGroupingMode.none;
  if (rawMode != null &&
      UyavaFilterGroupingModeCodec.fromWireString(rawMode) == null) {
    diagnostics.add(
      UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.filtersInvalidMode.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.filtersInvalidMode,
        level: UyavaGraphIntegrityCode.filtersInvalidMode.defaultLevel,
        context: <String, Object?>{'mode': rawMode},
      ),
    );
    mode = UyavaFilterGroupingMode.none;
  }

  int? levelDepth = _sanitizeDepth(map['levelDepth']);
  if (mode != UyavaFilterGroupingMode.level) {
    levelDepth = null;
  }

  if (mode == UyavaFilterGroupingMode.none && levelDepth == null) {
    return _Section<UyavaGraphFilterGroupingPayload>(null, diagnostics);
  }

  return _Section<UyavaGraphFilterGroupingPayload>(
    UyavaGraphFilterGroupingPayload(mode: mode, levelDepth: levelDepth),
    diagnostics,
  );
}

_Section<UyavaGraphFilterSeverityPayload> _parseSeverity(Object? raw) {
  if (raw is! Map) {
    return _Section<UyavaGraphFilterSeverityPayload>(null, const []);
  }

  final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  final List<UyavaGraphDiagnosticPayload> diagnostics =
      <UyavaGraphDiagnosticPayload>[];

  final String? operatorRaw = _trimmedOrNull(map['operator']);
  final UyavaFilterSeverityOperator? operator =
      UyavaFilterSeverityOperatorCodec.fromWireString(operatorRaw);
  if (operator == null) {
    diagnostics.add(
      UyavaGraphDiagnosticPayload(
        code: UyavaGraphIntegrityCode.filtersInvalidMode.toWireString(),
        codeEnum: UyavaGraphIntegrityCode.filtersInvalidMode,
        level: UyavaGraphIntegrityCode.filtersInvalidMode.defaultLevel,
        context: <String, Object?>{'operator': operatorRaw},
      ),
    );
    return _Section<UyavaGraphFilterSeverityPayload>(null, diagnostics);
  }

  final String? levelRaw = _trimmedOrNull(map['level']);
  UyavaSeverity? level;
  if (levelRaw != null) {
    try {
      level = UyavaSeverity.values.byName(levelRaw);
    } catch (_) {
      diagnostics.add(
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.filtersInvalidMode.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.filtersInvalidMode,
          level: UyavaGraphIntegrityCode.filtersInvalidMode.defaultLevel,
          context: <String, Object?>{'level': levelRaw},
        ),
      );
    }
  }

  if (level == null) {
    return _Section<UyavaGraphFilterSeverityPayload>(null, diagnostics);
  }

  return _Section<UyavaGraphFilterSeverityPayload>(
    UyavaGraphFilterSeverityPayload(operator: operator, level: level),
    diagnostics,
  );
}

class _FlagResult {
  const _FlagResult({
    required this.flags,
    required this.caseSensitiveOverride,
    required this.multiLine,
    required this.unicode,
    required this.dotAll,
    this.diagnostics = const <UyavaGraphDiagnosticPayload>[],
  });

  final String? flags;
  final bool? caseSensitiveOverride;
  final bool multiLine;
  final bool unicode;
  final bool dotAll;
  final List<UyavaGraphDiagnosticPayload> diagnostics;
}

_FlagResult _parseFlags(Object? raw) {
  if (raw == null) {
    return const _FlagResult(
      flags: null,
      caseSensitiveOverride: null,
      multiLine: false,
      unicode: false,
      dotAll: false,
    );
  }
  if (raw is! String) {
    return _FlagResult(
      flags: null,
      caseSensitiveOverride: null,
      multiLine: false,
      unicode: false,
      dotAll: false,
      diagnostics: <UyavaGraphDiagnosticPayload>[
        UyavaGraphDiagnosticPayload(
          code: UyavaGraphIntegrityCode.filtersInvalidMode.toWireString(),
          codeEnum: UyavaGraphIntegrityCode.filtersInvalidMode,
          level: UyavaGraphIntegrityCode.filtersInvalidMode.defaultLevel,
          context: <String, Object?>{'flags': raw},
        ),
      ],
    );
  }

  const List<String> allowedOrder = <String>['i', 'm', 's', 'u'];
  final List<String> normalized = <String>[];
  for (final String char in raw.split('')) {
    if (allowedOrder.contains(char) && !normalized.contains(char)) {
      normalized.add(char);
    }
  }

  final bool containsI = normalized.contains('i');
  final bool multiLine = normalized.contains('m');
  final bool dotAll = normalized.contains('s');
  final bool unicode = normalized.contains('u');

  final String normalizedFlags = normalized.isEmpty ? '' : normalized.join();

  return _FlagResult(
    flags: normalizedFlags.isEmpty ? null : normalizedFlags,
    caseSensitiveOverride: containsI ? false : null,
    multiLine: multiLine,
    unicode: unicode,
    dotAll: dotAll,
  );
}

List<String> _sanitizeIdList(Object? raw) {
  if (raw is! Iterable) return const <String>[];
  final List<String> values = <String>[];
  final Set<String> seen = <String>{};
  for (final Object? entry in raw) {
    final String? value = _trimmedOrNull(entry);
    if (value == null) continue;
    if (seen.add(value)) {
      values.add(value);
    }
  }
  return List<String>.unmodifiable(values);
}

int? _sanitizeDepth(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
  return null;
}

String? _trimmedOrNull(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}
