import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import '../transport.dart';
import 'io_adapters.dart';

/// Describes how Uyava file logging writes and rotates archives.
@immutable
class UyavaFileLoggerConfig {
  UyavaFileLoggerConfig({
    required this.directoryPath,
    this.filePrefix = 'uyava',
    this.maxFileSizeBytes = 32 * 1024 * 1024,
    this.maxDuration = const Duration(minutes: 30),
    this.maxFileCount = 5,
    this.maxExportCount,
    this.maxExportTotalBytes,
    this.retainLatestOnly = false,
    this.realtimeEnabled = true,
    this.realtimeSamplingRate = 1.0,
    this.realtimeBurstLimitPerSecond = 200,
    this.minLevel = UyavaSeverity.trace,
    List<String>? includeTypes,
    List<String>? excludeTypes,
    this.flushInterval = const Duration(milliseconds: 250),
    this.redaction = const UyavaRedactionConfig(),
    this.crashSafePersistence = false,
    this.panicMirrorFileName = 'panic-tail.jsonl',
    this.streamingJournalEnabled = false,
    this.streamingJournalFileName = 'panic-tail-active.jsonl',
    this.streamingJournalFlushInterval = const Duration(seconds: 2),
  }) : assert(directoryPath != ''),
       assert(maxFileSizeBytes > 0),
       assert(maxDuration > Duration.zero),
       assert(maxFileCount > 0),
       assert(maxExportCount == null || maxExportCount > 0),
       assert(maxExportTotalBytes == null || maxExportTotalBytes > 0),
       assert(realtimeSamplingRate >= 0 && realtimeSamplingRate <= 1),
       assert(realtimeBurstLimitPerSecond >= 0),
       assert(panicMirrorFileName.isNotEmpty),
       assert(streamingJournalFileName.isNotEmpty),
       assert(streamingJournalFlushInterval > Duration.zero),
       includeTypes = List<String>.unmodifiable(
         includeTypes ?? const <String>[],
       ),
       excludeTypes = List<String>.unmodifiable(
         excludeTypes ?? const <String>[],
       );

  final String directoryPath;
  final String filePrefix;
  final int maxFileSizeBytes;
  final Duration maxDuration;
  final int maxFileCount;
  final int? maxExportCount;
  final int? maxExportTotalBytes;
  final bool retainLatestOnly;
  final bool realtimeEnabled;
  final double realtimeSamplingRate;
  final int realtimeBurstLimitPerSecond;
  final UyavaSeverity minLevel;
  final List<String> includeTypes;
  final List<String> excludeTypes;
  final Duration flushInterval;
  final UyavaRedactionConfig redaction;
  final bool crashSafePersistence;
  final String panicMirrorFileName;
  final bool streamingJournalEnabled;
  final String streamingJournalFileName;
  final Duration streamingJournalFlushInterval;

  UyavaFileLoggerConfig copyWith({
    String? directoryPath,
    String? filePrefix,
    int? maxFileSizeBytes,
    Duration? maxDuration,
    int? maxFileCount,
    int? maxExportCount,
    int? maxExportTotalBytes,
    bool? retainLatestOnly,
    bool? realtimeEnabled,
    double? realtimeSamplingRate,
    int? realtimeBurstLimitPerSecond,
    UyavaSeverity? minLevel,
    List<String>? includeTypes,
    List<String>? excludeTypes,
    Duration? flushInterval,
    UyavaRedactionConfig? redaction,
    bool? crashSafePersistence,
    String? panicMirrorFileName,
    bool? streamingJournalEnabled,
    String? streamingJournalFileName,
    Duration? streamingJournalFlushInterval,
  }) {
    return UyavaFileLoggerConfig(
      directoryPath: directoryPath ?? this.directoryPath,
      filePrefix: filePrefix ?? this.filePrefix,
      maxFileSizeBytes: maxFileSizeBytes ?? this.maxFileSizeBytes,
      maxDuration: maxDuration ?? this.maxDuration,
      maxFileCount: maxFileCount ?? this.maxFileCount,
      maxExportCount: maxExportCount ?? this.maxExportCount,
      maxExportTotalBytes: maxExportTotalBytes ?? this.maxExportTotalBytes,
      retainLatestOnly: retainLatestOnly ?? this.retainLatestOnly,
      realtimeEnabled: realtimeEnabled ?? this.realtimeEnabled,
      realtimeSamplingRate: realtimeSamplingRate ?? this.realtimeSamplingRate,
      realtimeBurstLimitPerSecond:
          realtimeBurstLimitPerSecond ?? this.realtimeBurstLimitPerSecond,
      minLevel: minLevel ?? this.minLevel,
      includeTypes: includeTypes != null
          ? List<String>.unmodifiable(includeTypes)
          : this.includeTypes,
      excludeTypes: excludeTypes != null
          ? List<String>.unmodifiable(excludeTypes)
          : this.excludeTypes,
      flushInterval: flushInterval ?? this.flushInterval,
      redaction: redaction ?? this.redaction,
      crashSafePersistence: crashSafePersistence ?? this.crashSafePersistence,
      panicMirrorFileName: panicMirrorFileName ?? this.panicMirrorFileName,
      streamingJournalEnabled:
          streamingJournalEnabled ?? this.streamingJournalEnabled,
      streamingJournalFileName:
          streamingJournalFileName ?? this.streamingJournalFileName,
      streamingJournalFlushInterval:
          streamingJournalFlushInterval ?? this.streamingJournalFlushInterval,
    );
  }
}

@immutable
class UyavaFileLoggerTestOverrides {
  const UyavaFileLoggerTestOverrides({
    this.useSynchronousWorker = false,
    this.dropFlushResponses = false,
    this.ioAdapter,
  });

  final bool useSynchronousWorker;
  final bool dropFlushResponses;
  final FileLogIoAdapter? ioAdapter;
}

UyavaFileLoggerTestOverrides? fileLoggerTestOverrides;

@visibleForTesting
void setUyavaFileLoggerTestOverrides(UyavaFileLoggerTestOverrides? overrides) {
  fileLoggerTestOverrides = overrides;
}

/// Describes a materialized log archive exported from the file transport.
@immutable
class UyavaLogArchive {
  const UyavaLogArchive({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
    required this.startedAt,
    required this.completedAt,
    this.sourcePath,
  });

  final String path;
  final String fileName;
  final int sizeBytes;
  final DateTime startedAt;
  final DateTime completedAt;
  final String? sourcePath;

  File toFile() => File(path);
}

/// Identifies the reason a log archive became available.
enum UyavaLogArchiveEventKind { rotation, export, clone, recovery, panicSeal }

/// Broadcast to observers whenever a new log artifact is ready for consumption.
@immutable
class UyavaLogArchiveEvent {
  const UyavaLogArchiveEvent({required this.kind, required this.archive});

  final UyavaLogArchiveEventKind kind;
  final UyavaLogArchive archive;
}

/// Aggregated statistics about events that were discarded before reaching disk.
@immutable
class UyavaDiscardStats {
  UyavaDiscardStats({
    required this.totalCount,
    required Map<String, int> reasonCounts,
    required this.updatedAt,
    this.lastReason,
  }) : reasonCounts = Map<String, int>.unmodifiable(
         Map<String, int>.from(reasonCounts),
       );

  /// Total number of events discarded since the transport was started.
  final int totalCount;

  /// Breakdown of discard counts by reason (e.g. `realtime_sampling`).
  final Map<String, int> reasonCounts;

  /// Timestamp when the statistics were last updated.
  final DateTime updatedAt;

  /// Identifier of the most recent discard reason, if any.
  final String? lastReason;

  /// Convenience accessor returning the count for [reason] or zero.
  int countFor(String reason) => reasonCounts[reason] ?? 0;
}

/// Tagged options controlling payload redaction before logs are flushed.
@immutable
class UyavaRedactionConfig {
  const UyavaRedactionConfig({
    this.allowRawData = false,
    this.maskFields = const <String>[],
    this.dropFields = const <String>[],
    this.tagsAllowList,
    this.tagsDenyList,
    this.customHandler,
  });

  final bool allowRawData;
  final List<String> maskFields;
  final List<String> dropFields;
  final List<String>? tagsAllowList;
  final List<String>? tagsDenyList;
  final UyavaRedactionCallback? customHandler;
}

@immutable
class UyavaRedactionContext {
  const UyavaRedactionContext({
    required this.type,
    required this.scope,
    required this.payload,
  });

  final String type;
  final UyavaTransportScope scope;
  final Map<String, dynamic> payload;

  UyavaRedactionContext copyWith({Map<String, dynamic>? payload}) {
    return UyavaRedactionContext(
      type: type,
      scope: scope,
      payload: payload ?? this.payload,
    );
  }
}

typedef UyavaRedactionCallback =
    Map<String, dynamic>? Function(UyavaRedactionContext context);
