import 'package:flutter/material.dart';
import 'package:uyava/uyava.dart';

String formatArchiveTimestamp(DateTime timestamp) {
  final DateTime local = timestamp.toLocal();
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${pad(local.hour)}:${pad(local.minute)}:${pad(local.second)}';
}

String formatArchiveSize(int bytes) {
  const double kb = 1024;
  const double mb = kb * 1024;
  if (bytes >= mb) {
    final double value = bytes / mb;
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} MB';
  }
  if (bytes >= kb) {
    final double value = bytes / kb;
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} KB';
  }
  return '$bytes bytes';
}

String archiveEventLabel(UyavaLogArchiveEventKind kind) {
  switch (kind) {
    case UyavaLogArchiveEventKind.rotation:
      return 'Rotation — file sealed';
    case UyavaLogArchiveEventKind.export:
      return 'Exported archive';
    case UyavaLogArchiveEventKind.clone:
      return 'Active archive clone';
    case UyavaLogArchiveEventKind.recovery:
      return 'Recovery after crash';
    case UyavaLogArchiveEventKind.panicSeal:
      return 'Emergency save (panic-tail)';
  }
}

class ArchiveEventSection extends StatelessWidget {
  const ArchiveEventSection({
    super.key,
    required this.loggingAvailable,
    required this.streamAvailable,
    required this.events,
  });

  final bool loggingAvailable;
  final bool streamAvailable;
  final List<UyavaLogArchiveEvent> events;

  @override
  Widget build(BuildContext context) {
    final TextStyle? bodyStyle = Theme.of(context).textTheme.bodySmall;
    if (!loggingAvailable) {
      return Text(
        'Enable file logging to see archives in real time.',
        style: bodyStyle,
      );
    }
    if (!streamAvailable) {
      return Text(
        'Archive streaming is not available on this platform.',
        style: bodyStyle,
      );
    }
    if (events.isEmpty) {
      return Text(
        'No archives have been created yet. Rotations, exports, and clones '
        'will appear here as soon as they are written.',
        style: bodyStyle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events.map((event) {
        final TextTheme textTheme = Theme.of(context).textTheme;
        final DateTime completedAt = event.archive.completedAt.toLocal();
        final String timestamp = completedAt.toIso8601String();
        final List<Widget> lines = <Widget>[
          Text(
            '${archiveEventLabel(event.kind)} • ${event.archive.fileName}',
            style: textTheme.bodyMedium,
          ),
          Text(
            '$timestamp • ${formatArchiveSize(event.archive.sizeBytes)}',
            style: textTheme.bodySmall,
          ),
          SelectableText(event.archive.path, style: textTheme.bodySmall),
        ];
        final String? sourcePath = event.archive.sourcePath;
        if (sourcePath != null && sourcePath != event.archive.path) {
          lines.add(
            SelectableText('Source: $sourcePath', style: textTheme.bodySmall),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines,
          ),
        );
      }).toList(),
    );
  }
}

class ArchiveActionButtons extends StatelessWidget {
  const ArchiveActionButtons({
    super.key,
    required this.loggingAvailable,
    required this.isCloning,
    required this.isSending,
    required this.onClone,
    required this.onExport,
  });

  final bool loggingAvailable;
  final bool isCloning;
  final bool isSending;
  final Future<void> Function(BuildContext context) onClone;
  final Future<void> Function(BuildContext context) onExport;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: !loggingAvailable || isCloning
                  ? null
                  : () => onClone(buttonContext),
              child: Text(isCloning ? 'Cloning...' : 'Clone active log'),
            ),
            ElevatedButton(
              onPressed: !loggingAvailable || isSending
                  ? null
                  : () => onExport(buttonContext),
              child: Text(isSending ? 'Exporting...' : 'Send log via email'),
            ),
          ],
        );
      },
    );
  }
}

class DiscardStatsSummary extends StatelessWidget {
  const DiscardStatsSummary({
    super.key,
    required this.loggingAvailable,
    required this.discardStats,
  });

  final bool loggingAvailable;
  final UyavaDiscardStats? discardStats;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    if (!loggingAvailable) {
      return Text(
        'File logging is disabled, so counters are unavailable.',
        style: textTheme.bodySmall,
      );
    }
    final UyavaDiscardStats? stats = discardStats;
    if (stats == null) {
      return Text(
        'No events have been dropped yet. Use filters or sampling to see the '
        'counters.',
        style: textTheme.bodySmall,
      );
    }

    final List<MapEntry<String, int>> entries =
        stats.reasonCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total drops: ${stats.totalCount}', style: textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          'Last reason: ${stats.lastReason ?? 'N/A'} '
          '(${formatArchiveTimestamp(stats.updatedAt)})',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Text(
            'Breakdown by reason is still empty.',
            style: textTheme.bodySmall,
          )
        else ...[
          Text('Reasons:', style: textTheme.bodySmall),
          const SizedBox(height: 4),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '- ${entry.key}: ${entry.value}',
                style: textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }
}
