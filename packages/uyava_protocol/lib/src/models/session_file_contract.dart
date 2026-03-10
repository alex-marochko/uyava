// Contract for Uyava `.uyava` session archives (record/replay).
//
// Format: gzip/zstd-compressed NDJSON. The first line is a `sessionHeader`
// record, followed by event/marker/control records. Fields are intentionally
// conservative to keep compatibility as the format evolves.

const int kUyavaSessionFormatVersion = 1;

/// High-level kind of a record inside a `.uyava` archive.
enum UyavaSessionRecordKind { header, event, marker, control }

/// Compression algorithms supported for session archives.
enum UyavaSessionCompression { gzip, zstd, none }

extension UyavaSessionCompressionCodec on UyavaSessionCompression {
  String toWire() {
    switch (this) {
      case UyavaSessionCompression.gzip:
        return 'gzip';
      case UyavaSessionCompression.zstd:
        return 'zstd';
      case UyavaSessionCompression.none:
        return 'none';
    }
  }

  static UyavaSessionCompression fromWire(Object? raw) {
    if (raw == null) return UyavaSessionCompression.gzip;
    final String value = raw.toString().toLowerCase().trim();
    switch (value) {
      case 'zstd':
        return UyavaSessionCompression.zstd;
      case 'none':
        return UyavaSessionCompression.none;
      case 'gzip':
      default:
        return UyavaSessionCompression.gzip;
    }
  }
}

/// Summary of redaction rules applied while recording.
class UyavaSessionRedactionSummary {
  const UyavaSessionRedactionSummary({
    this.redactionApplied = false,
    this.allowRawData,
    this.maskFields = const <String>[],
    this.dropFields = const <String>[],
    this.tagsAllowList = const <String>[],
    this.tagsDenyList = const <String>[],
  });

  /// Whether any redaction rules were applied.
  final bool redactionApplied;

  /// Whether raw payloads were allowed to pass through.
  final bool? allowRawData;

  /// Indexed JSON paths that were masked.
  final List<String> maskFields;

  /// Indexed JSON paths that were dropped.
  final List<String> dropFields;

  /// Tag allow-list applied during recording.
  final List<String> tagsAllowList;

  /// Tag deny-list applied during recording.
  final List<String> tagsDenyList;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'redactionApplied': redactionApplied,
      if (allowRawData != null) 'allowRawData': allowRawData,
      if (maskFields.isNotEmpty) 'maskFields': List<String>.from(maskFields),
      if (dropFields.isNotEmpty) 'dropFields': List<String>.from(dropFields),
      if (tagsAllowList.isNotEmpty)
        'tagsAllowList': List<String>.from(tagsAllowList),
      if (tagsDenyList.isNotEmpty)
        'tagsDenyList': List<String>.from(tagsDenyList),
    };
  }

  factory UyavaSessionRedactionSummary.fromJson(Object? raw) {
    if (raw is! Map) {
      return const UyavaSessionRedactionSummary();
    }
    final Map<Object?, Object?> json = raw;
    return UyavaSessionRedactionSummary(
      redactionApplied: _coerceBool(json['redactionApplied']) ?? false,
      allowRawData: _coerceBool(json['allowRawData']),
      maskFields: _coerceStringList(json['maskFields']),
      dropFields: _coerceStringList(json['dropFields']),
      tagsAllowList: _coerceStringList(json['tagsAllowList']),
      tagsDenyList: _coerceStringList(json['tagsDenyList']),
    );
  }
}

/// Header for a `.uyava` session archive.
class UyavaSessionHeader {
  const UyavaSessionHeader({
    required this.sessionId,
    required this.startedAt,
    this.formatVersion = kUyavaSessionFormatVersion,
    this.appName,
    this.appVersion,
    this.buildNumber,
    this.platform,
    this.platformVersion,
    this.timezone,
    this.reason,
    this.compression = UyavaSessionCompression.gzip,
    this.redaction,
    this.hostMetadata = const <String, Object?>{},
    this.recorderMetadata = const <String, Object?>{},
  });

  /// Semver-like schema version for the archive.
  final int formatVersion;

  /// Unique session identifier for the archive.
  final String sessionId;

  /// Wall-clock start time for the recording (ISO 8601).
  final DateTime startedAt;

  /// Human-readable app name (if provided by the recorder).
  final String? appName;

  /// Human-readable app version (e.g. semantic version).
  final String? appVersion;

  /// Build identifier (e.g. build number or git commit).
  final String? buildNumber;

  /// Platform or OS identifier (e.g. macos, windows, ios, android).
  final String? platform;

  /// Platform version (e.g. 14.4.1, 15.0.0).
  final String? platformVersion;

  /// Local timezone at the time the recording started.
  final String? timezone;

  /// Optional user-provided reason for the recording.
  final String? reason;

  /// Compression algorithm used for the archive.
  final UyavaSessionCompression compression;

  /// Summary of redaction applied at record time.
  final UyavaSessionRedactionSummary? redaction;

  /// Host metadata (device, locale, CPU, etc) provided by the recorder.
  final Map<String, Object?> hostMetadata;

  /// Recorder version/config metadata (e.g. logger config summary).
  final Map<String, Object?> recorderMetadata;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': 'sessionHeader',
      'formatVersion': formatVersion,
      // Keep schemaVersion for backward compatibility with existing logs.
      'schemaVersion': formatVersion,
      'sessionId': sessionId,
      'startedAt': startedAt.toIso8601String(),
      if (_isNonEmpty(appName) ||
          _isNonEmpty(appVersion) ||
          _isNonEmpty(buildNumber))
        'app': <String, Object?>{
          if (_isNonEmpty(appName)) 'name': appName,
          if (_isNonEmpty(appVersion)) 'version': appVersion,
          if (_isNonEmpty(buildNumber)) 'build': buildNumber,
        },
      if (_isNonEmpty(platform) ||
          _isNonEmpty(platformVersion) ||
          _isNonEmpty(timezone))
        'platform': <String, Object?>{
          if (_isNonEmpty(platform)) 'os': platform,
          if (_isNonEmpty(platformVersion)) 'version': platformVersion,
          if (_isNonEmpty(timezone)) 'timezone': timezone,
        },
      if (_isNonEmpty(reason)) 'reason': reason,
      'compression': compression.toWire(),
      if (redaction != null) 'redaction': redaction!.toJson(),
      if (hostMetadata.isNotEmpty) 'hostMetadata': hostMetadata,
      if (recorderMetadata.isNotEmpty) 'recorder': recorderMetadata,
    };
  }

  factory UyavaSessionHeader.fromJson(Map<String, dynamic> json) {
    final int formatVersion =
        _coerceInt(json['formatVersion']) ??
        _coerceInt(json['schemaVersion']) ??
        kUyavaSessionFormatVersion;
    return UyavaSessionHeader(
      formatVersion: formatVersion,
      sessionId: _coerceString(json['sessionId']) ?? '',
      startedAt:
          _parseDate(json['startedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      appName: _coerceString(_extractMap(json['app'])?['name']),
      appVersion: _coerceString(_extractMap(json['app'])?['version']),
      buildNumber: _coerceString(_extractMap(json['app'])?['build']),
      platform: _coerceString(_extractMap(json['platform'])?['os']),
      platformVersion: _coerceString(_extractMap(json['platform'])?['version']),
      timezone: _coerceString(_extractMap(json['platform'])?['timezone']),
      reason: _coerceString(json['reason']),
      compression: UyavaSessionCompressionCodec.fromWire(json['compression']),
      redaction: UyavaSessionRedactionSummary.fromJson(json['redaction']),
      hostMetadata: _coerceStringMap(json['hostMetadata']),
      recorderMetadata: _coerceStringMap(json['recorder']),
    );
  }

  /// Throws if the header claims an unsupported future format version.
  void assertSupported(int maxSupportedFormatVersion) {
    if (formatVersion > maxSupportedFormatVersion) {
      throw FormatException(
        'Unsupported Uyava session format: $formatVersion '
        '(max supported $maxSupportedFormatVersion)',
      );
    }
  }
}

/// Event record inside a `.uyava` archive.
class UyavaSessionEventRecord {
  const UyavaSessionEventRecord({
    required this.type,
    required this.timestamp,
    required this.monotonicMicros,
    required this.payload,
    this.scope,
    this.sequenceId,
    this.redactedKeys = const <String>[],
    this.hostMetadata = const <String, Object?>{},
  });

  /// Event type (e.g. snapshot.replaceGraph, nodeEvent).
  final String type;

  /// Wall-clock timestamp (ISO 8601).
  final DateTime timestamp;

  /// Monotonic microseconds since the session start.
  final int monotonicMicros;

  /// Event payload, already redacted if applicable.
  final Map<String, Object?> payload;

  /// Optional scope hint (snapshot/realtime/diagnostic).
  final String? scope;

  /// Optional sequence id to preserve ordering across shards.
  final String? sequenceId;

  /// JSON paths removed or masked during redaction.
  final List<String> redactedKeys;

  /// Host metadata captured alongside this event.
  final Map<String, Object?> hostMetadata;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'recordType': 'event',
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'monotonicMicros': monotonicMicros,
      'payload': payload,
      if (_isNonEmpty(scope)) 'scope': scope,
      if (_isNonEmpty(sequenceId)) 'sequenceId': sequenceId,
      if (redactedKeys.isNotEmpty)
        'redactedKeys': List<String>.from(redactedKeys),
      if (hostMetadata.isNotEmpty) 'hostMetadata': hostMetadata,
    };
  }

  factory UyavaSessionEventRecord.fromJson(Map<String, dynamic> json) {
    final int monotonicMicros =
        _coerceInt(json['monotonicMicros']) ??
        _coerceInt(json['timestampMicros']) ??
        0;
    return UyavaSessionEventRecord(
      type: _coerceString(json['type']) ?? '',
      timestamp:
          _parseDate(json['timestamp']) ??
          DateTime.fromMicrosecondsSinceEpoch(monotonicMicros, isUtc: true),
      monotonicMicros: monotonicMicros,
      payload: _coerceStringMap(json['payload']),
      scope: _coerceString(json['scope']),
      sequenceId: _coerceString(json['sequenceId']),
      redactedKeys: _coerceStringList(json['redactedKeys']),
      hostMetadata: _coerceStringMap(json['hostMetadata']),
    );
  }
}

/// Marker record displayed on the replay timeline.
class UyavaSessionMarkerRecord {
  const UyavaSessionMarkerRecord({
    required this.id,
    required this.label,
    required this.timestamp,
    required this.offsetMicros,
    this.kind,
    this.level,
    this.meta = const <String, Object?>{},
  });

  /// Stable marker id for deduplication.
  final String id;

  /// Human-readable marker label.
  final String label;

  /// Wall-clock timestamp (ISO 8601).
  final DateTime timestamp;

  /// Monotonic offset in microseconds from session start.
  final int offsetMicros;

  /// Marker kind (e.g. manual, error, checkpoint).
  final String? kind;

  /// Marker severity/level (e.g. info, warn, error).
  final String? level;

  /// Optional structured metadata for the marker.
  final Map<String, Object?> meta;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'recordType': 'marker',
      'type': '_marker',
      'id': id,
      'label': label,
      'timestamp': timestamp.toIso8601String(),
      'offsetMicros': offsetMicros,
      if (_isNonEmpty(kind)) 'kind': kind,
      if (_isNonEmpty(level)) 'level': level,
      if (meta.isNotEmpty) 'meta': meta,
    };
  }

  factory UyavaSessionMarkerRecord.fromJson(Map<String, dynamic> json) {
    final int offsetMicros = _coerceInt(json['offsetMicros']) ?? 0;
    return UyavaSessionMarkerRecord(
      id: _coerceString(json['id']) ?? '',
      label: _coerceString(json['label']) ?? '',
      timestamp:
          _parseDate(json['timestamp']) ??
          DateTime.fromMicrosecondsSinceEpoch(offsetMicros, isUtc: true),
      offsetMicros: offsetMicros,
      kind: _coerceString(json['kind']),
      level: _coerceString(json['level']),
      meta: _coerceStringMap(json['meta']),
    );
  }
}

/// Normalizes records according to the supported format version.
class UyavaSessionFormatAdapter {
  const UyavaSessionFormatAdapter({
    this.maxSupportedFormatVersion = kUyavaSessionFormatVersion,
  });

  /// Highest format version supported by this adapter.
  final int maxSupportedFormatVersion;

  UyavaSessionHeader parseHeader(Map<String, dynamic> json) {
    final UyavaSessionHeader header = UyavaSessionHeader.fromJson(json);
    header.assertSupported(maxSupportedFormatVersion);
    return header;
  }

  ParsedUyavaSessionRecord parseRecord(Map<String, dynamic> json) {
    final String? recordType = _coerceString(json['recordType']);
    if (recordType == 'marker' || json['type'] == '_marker') {
      return ParsedUyavaSessionRecord.marker(
        UyavaSessionMarkerRecord.fromJson(json),
      );
    }
    if (recordType == 'header' || json['type'] == 'sessionHeader') {
      return ParsedUyavaSessionRecord.header(parseHeader(json));
    }
    return ParsedUyavaSessionRecord.event(
      UyavaSessionEventRecord.fromJson(json),
    );
  }
}

/// Union for parsed session records.
class ParsedUyavaSessionRecord {
  const ParsedUyavaSessionRecord.header(this.header)
    : kind = UyavaSessionRecordKind.header,
      event = null,
      marker = null;

  const ParsedUyavaSessionRecord.event(this.event)
    : kind = UyavaSessionRecordKind.event,
      header = null,
      marker = null;

  const ParsedUyavaSessionRecord.marker(this.marker)
    : kind = UyavaSessionRecordKind.marker,
      header = null,
      event = null;

  final UyavaSessionRecordKind kind;
  final UyavaSessionHeader? header;
  final UyavaSessionEventRecord? event;
  final UyavaSessionMarkerRecord? marker;
}

bool _isNonEmpty(String? value) => value != null && value.isNotEmpty;

int? _coerceInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) {
    final int? parsed = int.tryParse(raw);
    return parsed;
  }
  return null;
}

bool? _coerceBool(Object? raw) {
  if (raw is bool) return raw;
  if (raw is String) {
    final String normalized = raw.toLowerCase().trim();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

String? _coerceString(Object? raw) {
  if (raw == null) return null;
  final String value = raw.toString();
  return value.isEmpty ? null : value;
}

DateTime? _parseDate(Object? raw) {
  final String? value = _coerceString(raw);
  if (value == null) return null;
  return DateTime.tryParse(value);
}

Map<String, Object?> _coerceStringMap(Object? raw) {
  if (raw is! Map) return <String, Object?>{};
  final Map<String, Object?> result = <String, Object?>{};
  raw.forEach((Object? key, Object? value) {
    if (key == null) return;
    result[key.toString()] = value;
  });
  return result;
}

List<String> _coerceStringList(Object? raw) {
  if (raw is! Iterable) return const <String>[];
  final List<String> result = <String>[];
  for (final Object? value in raw) {
    final String? coerced = _coerceString(value);
    if (coerced != null) {
      result.add(coerced);
    }
  }
  return result;
}

Map<String, Object?>? _extractMap(Object? raw) {
  if (raw is! Map) return null;
  final Map<String, Object?> result = <String, Object?>{};
  raw.forEach((Object? key, Object? value) {
    if (key == null) return;
    result[key.toString()] = value;
  });
  return result;
}
