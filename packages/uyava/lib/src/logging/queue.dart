part of '../file_logger.dart';

class _QueuedRecord {
  const _QueuedRecord(this.record, this.timestampMicros);

  final Map<String, dynamic> record;
  final int timestampMicros;
}

class _LogEventQueue {
  _LogEventQueue({required this.config, required this.hostMetadata});

  final UyavaFileLoggerConfig config;
  final Map<String, Object?> hostMetadata;

  final Map<String, int> _discardCounts = <String, int>{};
  final Map<String, int> _discardLifetimeCounts = <String, int>{};
  int _discardLifetimeTotal = 0;
  String? _lastDiscardReason;
  final StreamController<UyavaDiscardStats> _discardStatsController =
      StreamController<UyavaDiscardStats>.broadcast(sync: true);
  UyavaDiscardStats? _latestDiscardStats;

  final Random _random = Random();
  DateTime? _burstWindowStart;
  int _burstCount = 0;
  int _sequenceCounter = 0;

  Stream<UyavaDiscardStats> get discardStatsStream =>
      _discardStatsController.stream;

  UyavaDiscardStats? get latestDiscardStats => _latestDiscardStats;

  bool shouldAllow(UyavaTransportEvent event) => accepts(event);

  bool accepts(UyavaTransportEvent event) {
    if (config.includeTypes.isNotEmpty &&
        !config.includeTypes.contains(event.type)) {
      _recordDiscard('include_filter', event);
      return false;
    }
    if (config.excludeTypes.contains(event.type)) {
      _recordDiscard('exclude_filter', event);
      return false;
    }
    final UyavaSeverity? severity = _resolveEventSeverity(event);
    if (severity != null && severity.index < config.minLevel.index) {
      _recordDiscard('severity_min_level', event);
      return false;
    }
    if (event.scope == UyavaTransportScope.realtime) {
      if (!config.realtimeEnabled) {
        _recordDiscard('realtime_disabled', event);
        return false;
      }
      if (config.realtimeSamplingRate < 1.0 &&
          _random.nextDouble() > config.realtimeSamplingRate) {
        _recordDiscard('realtime_sampling', event);
        return false;
      }
      _refreshBurstWindow();
      if (config.realtimeBurstLimitPerSecond > 0 &&
          _burstCount >= config.realtimeBurstLimitPerSecond) {
        _recordDiscard('realtime_burst', event);
        return false;
      }
      _burstCount += 1;
    }
    return true;
  }

  List<_QueuedRecord> prepareRecords(
    UyavaTransportEvent event, {
    required bool recordDiscardOnDrop,
  }) {
    final List<_QueuedRecord> ready = <_QueuedRecord>[];
    ready.addAll(_drainDiscardRecords());

    final _PendingRedaction redaction = _applyRedaction(event);
    if (redaction.dropReason != null) {
      if (recordDiscardOnDrop) {
        _recordDiscard(redaction.dropReason!, event);
        ready.addAll(_drainDiscardRecords());
      }
      return ready;
    }

    final Map<String, dynamic> payload =
        redaction.payload ?? <String, dynamic>{};
    final String sequenceId = event.sequenceId ?? _nextSequenceId(event.scope);
    final Map<String, dynamic> record = <String, dynamic>{
      'type': event.type,
      'scope': event.scope.name,
      'timestamp': event.timestamp.toIso8601String(),
      'payload': payload,
      'sequenceId': sequenceId,
      'hostMetadata': hostMetadata,
      if (redaction.redactedKeys.isNotEmpty)
        'redactedKeys': List<String>.from(redaction.redactedKeys),
    };
    ready.add(_QueuedRecord(record, event.timestamp.microsecondsSinceEpoch));
    return ready;
  }

  List<_QueuedRecord> drainDiscardAggregates() => _drainDiscardRecords();

  Future<void> dispose() async {
    await _discardStatsController.close();
  }

  List<_QueuedRecord> _drainDiscardRecords() {
    if (_discardCounts.isEmpty) return const <_QueuedRecord>[];
    final DateTime now = DateTime.now();
    final int timestampMicros = now.microsecondsSinceEpoch;
    final List<MapEntry<String, int>> entries = _discardCounts.entries.toList();
    _discardCounts.clear();
    return entries.map((MapEntry<String, int> entry) {
      final Map<String, dynamic> record = <String, dynamic>{
        'type': '_control.aggregateRealtimeDiscard',
        'scope': UyavaTransportScope.diagnostic.name,
        'timestamp': now.toIso8601String(),
        'payload': <String, Object?>{'reason': entry.key, 'count': entry.value},
        'hostMetadata': hostMetadata,
      };
      return _QueuedRecord(record, timestampMicros);
    }).toList();
  }

  void _recordDiscard(String reason, UyavaTransportEvent event) {
    _discardCounts.update(reason, (int value) => value + 1, ifAbsent: () => 1);
    _discardLifetimeCounts.update(
      reason,
      (int value) => value + 1,
      ifAbsent: () => 1,
    );
    _discardLifetimeTotal += 1;
    _lastDiscardReason = reason;
    final DateTime now = DateTime.now();
    _emitDiscardStats(now);
  }

  void _emitDiscardStats(DateTime updatedAt) {
    final UyavaDiscardStats stats = UyavaDiscardStats(
      totalCount: _discardLifetimeTotal,
      reasonCounts: _discardLifetimeCounts,
      updatedAt: updatedAt,
      lastReason: _lastDiscardReason,
    );
    _latestDiscardStats = stats;
    if (!_discardStatsController.isClosed) {
      _discardStatsController.add(stats);
    }
  }

  void _refreshBurstWindow() {
    final DateTime now = DateTime.now();
    if (_burstWindowStart == null ||
        now.difference(_burstWindowStart!) >= const Duration(seconds: 1)) {
      _burstWindowStart = now;
      _burstCount = 0;
    }
  }

  UyavaSeverity? _resolveEventSeverity(UyavaTransportEvent event) {
    final UyavaSeverity? direct = _parseSeverity(event.payload['severity']);
    if (direct != null) {
      return direct;
    }
    return _parseSeverity(event.payload['level']);
  }

  UyavaSeverity? _parseSeverity(Object? raw) {
    if (raw == null) return null;
    final String normalized = raw.toString().trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final UyavaSeverity candidate in UyavaSeverity.values) {
      if (candidate.name == normalized) {
        return candidate;
      }
    }
    return null;
  }

  String _nextSequenceId(UyavaTransportScope scope) {
    _sequenceCounter += 1;
    return '${scope.name}-${_sequenceCounter.toRadixString(16)}';
  }

  _PendingRedaction _applyRedaction(UyavaTransportEvent event) {
    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      event.payload,
    );
    final Set<String> redactedKeys = <String>{};
    final UyavaRedactionConfig rules = config.redaction;

    if (!rules.allowRawData && payload.remove('rawData') != null) {
      redactedKeys.add('rawData');
    }

    for (final String keyPath in rules.dropFields) {
      if (_applyPathOperation(payload, keyPath, _PathAction.drop)) {
        redactedKeys.add(keyPath);
      }
    }

    for (final String keyPath in rules.maskFields) {
      if (_applyPathOperation(payload, keyPath, _PathAction.mask)) {
        redactedKeys.add(keyPath);
      }
    }

    final List<String>? allow = rules.tagsAllowList;
    final List<String>? deny = rules.tagsDenyList;
    if (payload.containsKey('tags') && payload['tags'] is List) {
      final List<dynamic> rawTags = List<dynamic>.from(payload['tags'] as List);
      final List<String> filtered = <String>[];
      final Set<String> denySet = deny != null
          ? deny.map((String value) => value.toLowerCase()).toSet()
          : const <String>{};
      final Set<String>? allowSet = allow
          ?.map((String value) => value.toLowerCase())
          .toSet();
      for (final dynamic tag in rawTags) {
        final String? tagStr = tag is String ? tag : tag?.toString();
        if (tagStr == null) continue;
        final String lower = tagStr.toLowerCase();
        if (allowSet != null && !allowSet.contains(lower)) {
          continue;
        }
        if (denySet.contains(lower)) {
          continue;
        }
        filtered.add(tagStr);
      }
      payload['tags'] = filtered;
    }

    Map<String, dynamic>? localPayload = payload;
    if (rules.customHandler != null) {
      final Map<String, dynamic>? customResult = rules.customHandler!(
        UyavaRedactionContext(
          type: event.type,
          scope: event.scope,
          payload: Map<String, dynamic>.from(payload),
        ),
      );
      if (customResult == null) {
        return _PendingRedaction.drop(dropReason: 'custom_handler');
      }
      localPayload = customResult;
    }

    return _PendingRedaction(payload: localPayload, redactedKeys: redactedKeys);
  }
}

class _PendingRedaction {
  _PendingRedaction({required this.payload, required this.redactedKeys})
    : dropReason = null;

  _PendingRedaction.drop({required this.dropReason})
    : payload = null,
      redactedKeys = const <String>{};

  final Map<String, dynamic>? payload;
  final Set<String> redactedKeys;
  final String? dropReason;
}

enum _PathAction { drop, mask }

bool _applyPathOperation(
  Map<String, dynamic> payload,
  String path,
  _PathAction action,
) {
  final List<_PathSegment> segments = _PathSegment.parse(path);
  if (segments.isEmpty) return false;
  final _PathTraversal traversal = _PathTraversal(payload);
  return traversal.apply(segments, action);
}

class _PathSegment {
  const _PathSegment(this.key, {this.index});

  final String key;
  final int? index;

  static List<_PathSegment> parse(String path) {
    final List<_PathSegment> result = <_PathSegment>[];
    final List<String> parts = path.split('.');
    for (final String part in parts) {
      final int bracketIndex = part.indexOf('[');
      if (bracketIndex == -1) {
        result.add(_PathSegment(part));
        continue;
      }
      final String prefix = part.substring(0, bracketIndex);
      final int endIndex = part.indexOf(']', bracketIndex);
      if (endIndex == -1) {
        return const <_PathSegment>[];
      }
      final String indexStr = part.substring(bracketIndex + 1, endIndex);
      final int? index = int.tryParse(indexStr);
      result.add(_PathSegment(prefix, index: index));
    }
    return result;
  }
}

class _PathTraversal {
  _PathTraversal(this.root);

  final Map<String, dynamic> root;

  bool apply(List<_PathSegment> segments, _PathAction action) {
    dynamic current = root;
    for (int i = 0; i < segments.length; i++) {
      final _PathSegment segment = segments[i];
      if (current is! Map<String, dynamic>) {
        return false;
      }
      if (!current.containsKey(segment.key)) {
        return false;
      }
      if (i == segments.length - 1) {
        if (segment.index == null) {
          if (action == _PathAction.drop) {
            current.remove(segment.key);
          } else {
            current[segment.key] = '***';
          }
          return true;
        }
        final dynamic listValue = current[segment.key];
        if (listValue is! List) {
          return false;
        }
        final int? idx = segment.index;
        if (idx == null || idx < 0 || idx >= listValue.length) {
          return false;
        }
        if (action == _PathAction.drop) {
          listValue.removeAt(idx);
        } else {
          listValue[idx] = '***';
        }
        return true;
      }
      current = current[segment.key];
      if (segment.index != null) {
        if (current is List &&
            segment.index! >= 0 &&
            segment.index! < current.length) {
          current = current[segment.index!];
        } else {
          return false;
        }
      }
    }
    return false;
  }
}
