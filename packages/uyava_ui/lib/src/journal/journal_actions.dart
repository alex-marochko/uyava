import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uyava_core/uyava_core.dart';

import 'journal_entry.dart';
import 'journal_link.dart';

Future<void> copyVisibleLog({
  required List<GraphJournalEventEntry> events,
  required List<GraphDiagnosticRecord> diagnostics,
  required bool includeEvents,
  required bool includeDiagnostics,
}) async {
  if (!includeEvents && !includeDiagnostics) {
    return;
  }
  final Map<String, Object?> payload = <String, Object?>{};
  if (includeEvents) {
    payload['events'] = [
      for (final entry in events) eventEntryToJsonObject(entry),
    ];
  }
  if (includeDiagnostics) {
    payload['diagnostics'] = [
      for (final record in diagnostics) diagnosticRecordToJsonObject(record),
    ];
  }
  if (payload.isEmpty) {
    return;
  }
  final String text = const JsonEncoder.withIndent('  ').convert(payload);
  await Clipboard.setData(ClipboardData(text: text));
}

Future<void> showJournalContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required String clipboardText,
  GraphJournalLinkTarget? focusTarget,
  ValueChanged<GraphJournalLinkTarget>? onLinkTap,
  String? sourceRef,
  Future<void> Function(String sourceRef)? onOpenInIde,
}) async {
  final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[
    if (focusTarget != null && onLinkTap != null)
      const PopupMenuItem<String>(
        value: 'focus',
        child: Text('Focus on graph'),
      ),
    if (sourceRef != null && sourceRef.isNotEmpty && onOpenInIde != null)
      const PopupMenuItem<String>(
        value: 'open_in_ide',
        child: Text('Open in IDE…'),
      ),
    const PopupMenuItem<String>(value: 'copy', child: Text('Copy entry')),
  ];

  final String? action = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      globalPosition.dx,
      globalPosition.dy,
    ),
    items: items,
  );
  if (action == 'copy') {
    await Clipboard.setData(ClipboardData(text: clipboardText));
  } else if (action == 'focus' && focusTarget != null) {
    onLinkTap?.call(focusTarget);
  } else if (action == 'open_in_ide' && sourceRef != null) {
    await onOpenInIde?.call(sourceRef);
  }
}

String formatJournalTimestamp(DateTime local) {
  final String hh = local.hour.toString().padLeft(2, '0');
  final String mm = local.minute.toString().padLeft(2, '0');
  final String ss = local.second.toString().padLeft(2, '0');
  final String ms = local.millisecond.toString().padLeft(3, '0');
  return '$hh:$mm:$ss.$ms';
}

String? formatRelativeDuration(Duration? delta) {
  if (delta == null) return null;
  Duration value = delta;
  if (value.isNegative) value = Duration.zero;
  if (value.inMilliseconds < 1) return '+0 ms';
  if (value.inMilliseconds < 1000) {
    return '+${value.inMilliseconds} ms';
  }
  if (value.inSeconds < 60) {
    final double seconds = value.inMilliseconds / 1000.0;
    return '+${seconds.toStringAsFixed(seconds >= 10 ? 1 : 2)} s';
  }
  final int minutes = value.inMinutes;
  final int seconds = value.inSeconds.remainder(60);
  if (minutes < 60) {
    return '+${minutes}m ${seconds}s';
  }
  final int hours = value.inHours;
  final int mins = minutes.remainder(60);
  return '+${hours}h ${mins}m';
}

String? formatIsolateLabel({
  String? isolateName,
  int? isolateNumber,
  String? isolateId,
}) {
  final String? name = isolateName != null && isolateName.isNotEmpty
      ? isolateName
      : null;
  final String? number = isolateNumber != null
      ? '#${isolateNumber.toString()}'
      : null;
  String? id;
  if (isolateId != null && isolateId.isNotEmpty) {
    id = isolateId.length <= 8
        ? isolateId
        : '${isolateId.substring(0, 4)}…${isolateId.substring(isolateId.length - 3)}';
  }
  if (name != null && number != null) return '$name ($number)';
  if (name != null) return name;
  if (number != null && id != null) return '$number · $id';
  return number ?? id;
}

String formatEventEntryForClipboard(GraphJournalEventEntry entry) {
  return formatEventEntryJson(entry);
}

String formatDiagnosticForClipboard(GraphDiagnosticRecord record) {
  return const JsonEncoder.withIndent(
    '  ',
  ).convert(diagnosticRecordToJsonObject(record));
}

String formatEventEntryJson(
  GraphJournalEventEntry entry, {
  bool pretty = true,
}) {
  final Map<String, Object?> data = eventEntryToJsonObject(entry);
  final JsonEncoder encoder = pretty
      ? const JsonEncoder.withIndent('  ')
      : const JsonEncoder();
  return encoder.convert(data);
}

String formatDiagnosticJson(
  GraphDiagnosticRecord record,
  Duration? deltaSincePrevious,
) {
  final Map<String, Object?> data = diagnosticRecordToJsonObject(
    record,
    deltaSincePrevious: deltaSincePrevious,
  );
  return const JsonEncoder.withIndent('  ').convert(data);
}

Map<String, Object?> eventEntryToJsonObject(GraphJournalEventEntry entry) {
  final Map<String, Object?> data = <String, Object?>{
    'sequence': entry.sequence,
    'kind': entry.kind.name,
    'timestamp': entry.timestamp.toUtc().toIso8601String(),
    'timestampLocal': entry.timestamp.toLocal().toIso8601String(),
    'severity': entry.severity?.name,
    'deltaSincePreviousMs': entry.deltaSincePrevious?.inMilliseconds,
    'message': entry.message,
  };

  final Map<String, Object?> isolate =
      <String, Object?>{
        'id': entry.isolateId,
        'name': entry.isolateName,
        'number': entry.isolateNumber,
      }..removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty),
      );
  if (isolate.isNotEmpty) {
    data['isolate'] = isolate;
  }

  switch (entry.kind) {
    case GraphJournalEventKind.node:
      final UyavaNodeEvent event = entry.nodeEvent!;
      data.addAll(<String, Object?>{
        'nodeId': event.nodeId,
        'tags': event.tags,
        'sourceRef': event.sourceRef,
      });
    case GraphJournalEventKind.edge:
      final UyavaEvent event = entry.edgeEvent!;
      data.addAll(<String, Object?>{
        'from': event.from,
        'to': event.to,
        'sourceRef': event.sourceRef,
      });
  }

  data.removeWhere((key, value) {
    if (value == null) return true;
    if (value is String && value.isEmpty) return true;
    if (value is Iterable && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    return false;
  });

  return data;
}

Map<String, Object?> diagnosticRecordToJsonObject(
  GraphDiagnosticRecord record, {
  Duration? deltaSincePrevious,
}) {
  final Map<String, Object?> data = <String, Object?>{
    'code': record.code,
    'codeEnum': record.codeEnum?.name,
    'level': record.level.name,
    'source': record.source.name,
    'timestamp': record.timestamp.toUtc().toIso8601String(),
    'timestampLocal': record.timestamp.toLocal().toIso8601String(),
    'deltaSincePreviousMs': deltaSincePrevious?.inMilliseconds,
    'subjects': record.subjects,
    'context': record.context,
  };

  data.removeWhere((key, value) {
    if (value == null) return true;
    if (value is String && value.isEmpty) return true;
    if (value is Iterable && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    return false;
  });

  return data;
}
