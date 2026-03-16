part of '../file_logger.dart';

@immutable
class _FileLoggerContext {
  _FileLoggerContext(this.config)
    : sessionId = _generateSessionId(),
      configSummary = _buildConfigSummary(config),
      hostMetadata = _buildHostMetadata();

  final UyavaFileLoggerConfig config;
  final String sessionId;
  final Map<String, Object?> configSummary;
  final Map<String, Object?> hostMetadata;

  static Map<String, Object?> _buildConfigSummary(
    UyavaFileLoggerConfig config,
  ) {
    return <String, Object?>{
      'maxFileSizeBytes': config.maxFileSizeBytes,
      'maxDurationMinutes': config.maxDuration.inMinutes,
      'maxFileCount': config.maxFileCount,
      'maxExportCount': config.maxExportCount,
      'maxExportTotalBytes': config.maxExportTotalBytes,
      'retainLatestOnly': config.retainLatestOnly,
      'realtimeEnabled': config.realtimeEnabled,
      'realtimeSamplingRate': config.realtimeSamplingRate,
      'realtimeBurstLimitPerSecond': config.realtimeBurstLimitPerSecond,
      'minLevel': config.minLevel.name,
      'includeTypes': List<String>.from(config.includeTypes),
      'excludeTypes': List<String>.from(config.excludeTypes),
      'crashSafePersistence': config.crashSafePersistence,
      'panicMirrorFileName': config.panicMirrorFileName,
      'streamingJournalEnabled': config.streamingJournalEnabled,
      'streamingJournalFileName': config.streamingJournalFileName,
      'streamingJournalFlushIntervalMs':
          config.streamingJournalFlushInterval.inMilliseconds,
    };
  }

  static Map<String, Object?> _buildHostMetadata() {
    return <String, Object?>{
      'pid': pid,
      'isolate': Isolate.current.debugName ?? Isolate.current.hashCode,
      'platform': Platform.operatingSystem,
    };
  }

  static String _generateSessionId() {
    final int micros = DateTime.now().microsecondsSinceEpoch;
    final int randomBits = Random().nextInt(0x3fffffff);
    return '${micros.toRadixString(16)}-${randomBits.toRadixString(16)}';
  }
}
