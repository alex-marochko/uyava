part of '../console_logger.dart';

/// Captures a rendered console log record queued for output.
@immutable
class UyavaConsoleLogRecord {
  const UyavaConsoleLogRecord({
    required this.timestamp,
    required this.severity,
    required this.type,
    this.code,
    this.subjects = const <String>[],
    this.message,
    this.context = const <String, Object?>{},
  });

  final DateTime timestamp;
  final UyavaSeverity severity;
  final String type;
  final String? code;
  final List<String> subjects;
  final String? message;
  final Map<String, Object?> context;
}

/// Formats log records into the compact console representation.
class UyavaConsoleFormatter {
  const UyavaConsoleFormatter._();

  static String format(
    UyavaConsoleLogRecord record, {
    required bool colorEnabled,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..write(_formatTimestamp(record.timestamp))
      ..write(' ')
      ..write(_formatSeverity(record.severity, colorEnabled))
      ..write(' ')
      ..write(record.type);

    if (record.code != null && record.code!.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(record.code);
    }

    if (record.subjects.isNotEmpty) {
      buffer
        ..write(' [')
        ..write(record.subjects.join(','))
        ..write(']');
    }

    if (record.message != null && record.message!.isNotEmpty) {
      buffer
        ..write(' - ')
        ..write(record.message);
    }

    if (record.context.isNotEmpty) {
      buffer.write(' ');
      _appendContext(buffer, record.context);
    }

    return buffer.toString();
  }

  static String _formatTimestamp(DateTime timestamp) {
    final int hours = timestamp.hour;
    final int minutes = timestamp.minute;
    final int seconds = timestamp.second;
    final int milliseconds = timestamp.millisecond;
    return '${_padTwoDigits(hours)}:${_padTwoDigits(minutes)}:'
        '${_padTwoDigits(seconds)}.${_padThreeDigits(milliseconds)}';
  }

  static String _padTwoDigits(int value) {
    if (value >= 10) {
      return '$value';
    }
    return '0$value';
  }

  static String _padThreeDigits(int value) {
    if (value >= 100) {
      return '$value';
    }
    if (value >= 10) {
      return '0$value';
    }
    return '00$value';
  }

  static String _formatSeverity(UyavaSeverity severity, bool colorEnabled) {
    final String label = severity.name.toUpperCase().padRight(5);
    if (!colorEnabled) {
      return label;
    }
    final _AnsiColorStyle style =
        _severityColors[severity] ?? _AnsiColorStyle.fallback;
    return '${style.prefix}$label${_AnsiColorStyle.reset}';
  }

  static void _appendContext(
    StringBuffer buffer,
    Map<String, Object?> context,
  ) {
    bool first = true;
    context.forEach((String key, Object? value) {
      if (!first) {
        buffer.write(' ');
      }
      first = false;
      buffer
        ..write(key)
        ..write('=')
        ..write(value);
    });
  }
}

/// Minimal representation of ANSI foreground colors for severity labels.
class _AnsiColorStyle {
  const _AnsiColorStyle(this.prefix);

  final String prefix;

  static const String reset = '\x1B[0m';

  static const _AnsiColorStyle fallback = _AnsiColorStyle('');

  static const _AnsiColorStyle grey = _AnsiColorStyle('\x1B[38;5;244m');
  static const _AnsiColorStyle blue = _AnsiColorStyle('\x1B[38;5;45m');
  static const _AnsiColorStyle cyan = _AnsiColorStyle('\x1B[36m');
  static const _AnsiColorStyle yellow = _AnsiColorStyle('\x1B[33m');
  static const _AnsiColorStyle red = _AnsiColorStyle('\x1B[31m');
  static const _AnsiColorStyle brightRed = _AnsiColorStyle('\x1B[91m');
}

const Map<UyavaSeverity, _AnsiColorStyle> _severityColors =
    <UyavaSeverity, _AnsiColorStyle>{
      UyavaSeverity.trace: _AnsiColorStyle.grey,
      UyavaSeverity.debug: _AnsiColorStyle.blue,
      UyavaSeverity.info: _AnsiColorStyle.cyan,
      UyavaSeverity.warn: _AnsiColorStyle.yellow,
      UyavaSeverity.error: _AnsiColorStyle.red,
      UyavaSeverity.fatal: _AnsiColorStyle.brightRed,
    };
