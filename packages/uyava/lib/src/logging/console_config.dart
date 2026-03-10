import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

/// Controls how ANSI colors are applied to console output.
enum UyavaConsoleColorMode { auto, always, never }

/// Configuration for the console logger.
@immutable
class UyavaConsoleLoggerConfig {
  UyavaConsoleLoggerConfig({
    this.minLevel = UyavaSeverity.info,
    Iterable<String> includeTypes = const <String>[],
    Iterable<String> excludeTypes = const <String>[],
    this.colorMode = UyavaConsoleColorMode.auto,
    this.bufferCapacity = 512,
    this.flushInterval = const Duration(milliseconds: 100),
    this.sink,
  }) : assert(bufferCapacity >= 0, 'bufferCapacity must be >= 0'),
       assert(flushInterval >= Duration.zero, 'flushInterval must be >= 0'),
       includeTypes = Set<String>.unmodifiable(includeTypes),
       excludeTypes = Set<String>.unmodifiable(excludeTypes);

  /// Minimum severity that will be written to the console.
  final UyavaSeverity minLevel;

  /// Restricts output to the provided event types when non-empty.
  final Set<String> includeTypes;

  /// Excludes specific event types from the console stream.
  final Set<String> excludeTypes;

  /// Determines when ANSI colors are applied.
  final UyavaConsoleColorMode colorMode;

  /// Maximum number of records kept in memory before older ones are dropped.
  ///
  /// When zero, records are written synchronously without buffering.
  final int bufferCapacity;

  /// Delay between buffered flushes.
  ///
  /// Zero triggers immediate flushes for each record.
  final Duration flushInterval;

  /// Destination sink (defaults to [stdout] when null).
  final IOSink? sink;
}
