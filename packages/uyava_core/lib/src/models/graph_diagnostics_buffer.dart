import 'dart:collection';
import 'dart:convert';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'graph_integrity.dart';

typedef _Clock = DateTime Function();

List<String> _normalizeSubjects(Iterable<String> input) {
  final LinkedHashSet<String> values = LinkedHashSet<String>();
  for (final raw in input) {
    if (raw.isEmpty) continue;
    values.add(raw);
  }
  return List<String>.unmodifiable(values);
}

Map<String, Object?> _canonicalizeContext(Map<String, Object?> input) {
  final List<String> sortedKeys = input.keys.toList()..sort();
  return Map<String, Object?>.unmodifiable({
    for (final key in sortedKeys) key: _canonicalizeValue(input[key]),
  });
}

Object? _canonicalizeValue(Object? value) {
  if (value is Map<String, Object?>) {
    return _canonicalizeContext(value);
  }
  if (value is Map) {
    return _canonicalizeContext(
      value.map((key, val) => MapEntry(key.toString(), val)),
    );
  }
  if (value is Iterable) {
    return value.map(_canonicalizeValue).toList(growable: false);
  }
  return value;
}

Iterable<String> _subjectsFromIntegrity(GraphIntegrityIssue issue) {
  final List<String> raw = <String>[];
  if (issue.nodeId != null && issue.nodeId!.isNotEmpty) {
    raw.add(issue.nodeId!);
  }
  if (issue.edgeId != null && issue.edgeId!.isNotEmpty) {
    raw.add(issue.edgeId!);
  }
  return raw;
}

String? _normalizeSourceMeta(String? value) {
  if (value == null) return null;
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

enum GraphDiagnosticSource { core, app }

class GraphDiagnosticRecord {
  GraphDiagnosticRecord._({
    required this.source,
    required this.code,
    required this.level,
    required this.subjects,
    required this.timestamp,
    this.context,
    this.codeEnum,
    this.sourceId,
    this.sourceType,
  });

  factory GraphDiagnosticRecord({
    required GraphDiagnosticSource source,
    required String code,
    required UyavaDiagnosticLevel level,
    required Iterable<String> subjects,
    DateTime? timestamp,
    Map<String, Object?>? context,
    UyavaGraphIntegrityCode? codeEnum,
    String? sourceId,
    String? sourceType,
  }) {
    final UyavaGraphIntegrityCode? resolvedEnum =
        codeEnum ?? UyavaGraphIntegrityCode.fromWireString(code);
    final String resolvedCode = resolvedEnum?.toWireString() ?? code;
    final List<String> normalizedSubjects = _normalizeSubjects(subjects);
    final Map<String, Object?>? canonicalContext = context == null
        ? null
        : _canonicalizeContext(context);
    final DateTime resolvedTimestamp = (timestamp ?? DateTime.now()).toUtc();
    final String? normalizedSourceId = _normalizeSourceMeta(sourceId);
    final String? normalizedSourceType = _normalizeSourceMeta(sourceType);

    return GraphDiagnosticRecord._(
      source: source,
      code: resolvedCode,
      level: level,
      subjects: normalizedSubjects,
      timestamp: resolvedTimestamp,
      context: canonicalContext,
      codeEnum: resolvedEnum,
      sourceId: normalizedSourceId,
      sourceType: normalizedSourceType,
    );
  }

  factory GraphDiagnosticRecord.fromIntegrity(
    GraphIntegrityIssue issue, {
    required GraphDiagnosticSource source,
    required DateTime timestamp,
    String? sourceId,
    String? sourceType,
  }) {
    return GraphDiagnosticRecord(
      source: source,
      code: issue.wireCode,
      level: issue.level,
      subjects: _subjectsFromIntegrity(issue),
      timestamp: timestamp,
      context: issue.context,
      codeEnum: issue.code,
      sourceId: sourceId,
      sourceType: sourceType,
    );
  }

  factory GraphDiagnosticRecord.fromPayload(
    UyavaGraphDiagnosticPayload payload, {
    required GraphDiagnosticSource source,
    DateTime? timestampOverride,
    String? sourceId,
    String? sourceType,
  }) {
    return GraphDiagnosticRecord(
      source: source,
      code: payload.code,
      level: payload.level,
      subjects: payload.subjects,
      timestamp: timestampOverride ?? payload.timestamp,
      context: payload.context,
      codeEnum: payload.codeEnum,
      sourceId: sourceId,
      sourceType: sourceType,
    );
  }

  final GraphDiagnosticSource source;
  final String code;
  final UyavaDiagnosticLevel level;
  final List<String> subjects;
  final Map<String, Object?>? context;
  final DateTime timestamp;
  final UyavaGraphIntegrityCode? codeEnum;
  final String? sourceId;
  final String? sourceType;
}

class GraphDiagnosticsBuffer {
  GraphDiagnosticsBuffer({DateTime Function()? clock, this.maxRecords})
    : _clock = clock ?? DateTime.now;

  final _Clock _clock;
  final LinkedHashMap<String, GraphDiagnosticRecord> _records =
      LinkedHashMap<String, GraphDiagnosticRecord>();
  final int? maxRecords;
  int _totalTrimmed = 0;

  bool get isEmpty => _records.isEmpty;

  List<GraphDiagnosticRecord> get records =>
      List<GraphDiagnosticRecord>.unmodifiable(_records.values);

  int get totalTrimmed => _totalTrimmed;

  void clear() {
    _records.clear();
    _totalTrimmed = 0;
  }

  void replaceCoreIssues(Iterable<GraphIntegrityIssue> issues) {
    _records.removeWhere(
      (key, record) => record.source == GraphDiagnosticSource.core,
    );
    for (final issue in issues) {
      final record = GraphDiagnosticRecord.fromIntegrity(
        issue,
        source: GraphDiagnosticSource.core,
        timestamp: _clock().toUtc(),
      );
      _insert(record);
    }
  }

  void addAppDiagnostic({
    required String code,
    required UyavaDiagnosticLevel level,
    Iterable<String>? subjects,
    Map<String, Object?>? context,
    UyavaGraphIntegrityCode? codeEnum,
    DateTime? timestamp,
    String? sourceId,
    String? sourceType,
  }) {
    final record = GraphDiagnosticRecord(
      source: GraphDiagnosticSource.app,
      code: code,
      level: level,
      subjects: subjects ?? const <String>[],
      context: context,
      codeEnum: codeEnum,
      timestamp: (timestamp ?? _clock()).toUtc(),
      sourceId: sourceId,
      sourceType: sourceType,
    );
    _insert(record);
  }

  void addAppDiagnosticPayload(
    UyavaGraphDiagnosticPayload payload, {
    DateTime? timestamp,
    String? sourceId,
    String? sourceType,
  }) {
    final String canonicalCode =
        payload.codeEnum?.toWireString() ?? payload.code;
    addAppDiagnostic(
      code: canonicalCode,
      level: payload.level,
      subjects: payload.subjects,
      context: payload.context,
      codeEnum: payload.codeEnum,
      timestamp: timestamp ?? payload.timestamp,
      sourceId: sourceId,
      sourceType: sourceType,
    );
  }

  void _insert(GraphDiagnosticRecord record) {
    final String key = _composeKey(record);
    if (_records.containsKey(key)) {
      _records.remove(key);
    }
    _records[key] = record;
    _trimIfNeeded();
  }

  static String _composeKey(GraphDiagnosticRecord record) {
    final String subjectKey = record.subjects.join('|');
    final Object? context = record.context;
    final String contextKey = context == null
        ? ''
        : const JsonEncoder().convert(context);
    final String sourceId = record.sourceId ?? '';
    final String sourceType = record.sourceType ?? '';
    return '${record.source.name}|${record.code}|${record.level.name}|$subjectKey|$contextKey|$sourceId|$sourceType';
  }

  void _trimIfNeeded() {
    final int? limit = maxRecords;
    if (limit == null || limit <= 0) return;
    while (_records.length > limit) {
      final String? firstKey = _records.keys.isEmpty
          ? null
          : _records.keys.first;
      if (firstKey == null) break;
      _records.remove(firstKey);
      _totalTrimmed++;
    }
  }
}
