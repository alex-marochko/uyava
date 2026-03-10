import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uyava_core/uyava_core.dart';

import '../theme.dart';
import 'journal_actions.dart';
import 'journal_link.dart';
import 'journal_shared_widgets.dart';

class GraphJournalDiagnosticsList extends StatelessWidget {
  const GraphJournalDiagnosticsList({
    super.key,
    required this.records,
    required this.scheme,
    required this.controller,
    required this.onUserScrollAway,
    required this.emptyMessage,
    this.onLinkTap,
    this.onOpenDocs,
    this.forceRaw = false,
  });

  final List<GraphDiagnosticRecord> records;
  final ColorScheme scheme;
  final ScrollController controller;
  final VoidCallback onUserScrollAway;
  final ValueChanged<GraphJournalLinkTarget>? onLinkTap;
  final String emptyMessage;
  final Future<void> Function(GraphDiagnosticRecord record)? onOpenDocs;
  final bool forceRaw;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return GraphJournalEmptyState(
        icon: Icons.fact_check,
        message: emptyMessage,
      );
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        final double maxExtent = notification.metrics.maxScrollExtent;
        if (maxExtent <= 0) {
          return false;
        }
        final double threshold =
            notification.metrics.viewportDimension * 0.05 + 32.0;
        final bool nearBottom =
            notification.metrics.pixels >= maxExtent - threshold;
        if (!nearBottom) {
          onUserScrollAway();
        }
        return false;
      },
      child: ListView.builder(
        controller: controller,
        key: const PageStorageKey<String>('uyava_journal_diagnostics'),
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          Duration? delta;
          if (index > 0) {
            delta = record.timestamp.difference(records[index - 1].timestamp);
            if (delta.isNegative) {
              delta = Duration.zero;
            }
          }
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == records.length - 1 ? 0 : 6,
            ),
            child: _DiagnosticTile(
              record: record,
              scheme: scheme,
              onLinkTap: onLinkTap,
              deltaSincePrevious: delta,
              onOpenDocs: onOpenDocs,
              forceRaw: forceRaw,
            ),
          );
        },
      ),
    );
  }
}

class _DiagnosticTile extends StatefulWidget {
  const _DiagnosticTile({
    required this.record,
    required this.scheme,
    this.onLinkTap,
    this.deltaSincePrevious,
    this.onOpenDocs,
    this.forceRaw = false,
  });

  final GraphDiagnosticRecord record;
  final ColorScheme scheme;
  final ValueChanged<GraphJournalLinkTarget>? onLinkTap;
  final Duration? deltaSincePrevious;
  final Future<void> Function(GraphDiagnosticRecord record)? onOpenDocs;
  final bool forceRaw;

  @override
  State<_DiagnosticTile> createState() => _DiagnosticTileState();
}

class _DiagnosticTileState extends State<_DiagnosticTile> {
  bool _raw = false;

  @override
  void didUpdateWidget(covariant _DiagnosticTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.record, oldWidget.record)) {
      _raw = false;
    }
  }

  void _toggleRaw() {
    setState(() {
      _raw = !_raw;
    });
  }

  Widget _buildDiagnosticDetailsContent({
    required TextStyle base,
    required ColorScheme scheme,
  }) {
    final ValueChanged<GraphJournalLinkTarget>? linkHandler = widget.onLinkTap;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        SelectionContainer.disabled(
          child: Text(
            'Subjects:',
            style: base.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final subject in widget.record.subjects)
          GraphJournalLinkText(
            label: subject,
            onPressed: linkHandler == null
                ? null
                : () =>
                      linkHandler(GraphJournalSubjectLink(subjectId: subject)),
          ),
      ],
    );
  }

  Iterable<Widget> _buildContextPreview({
    required TextStyle base,
    required ColorScheme scheme,
  }) sync* {
    final Map<String, Object?>? context = widget.record.context;
    if (context == null || context.isEmpty) {
      return;
    }
    final String? message = context['message'] as String?;
    final String? stackTrace = context['stackTrace'] as String?;
    final Map<String, Object?>? runtimeContext =
        (context['runtimeContext'] as Map?)?.cast<String, Object?>();
    final Map<String, Object?>? panicTail = (context['panicTail'] as Map?)
        ?.cast<String, Object?>();
    final Map<String, Object?>? archive = (context['archive'] as Map?)
        ?.cast<String, Object?>();
    final String? loggingError = context['loggingError'] as String?;

    if (message != null && message.isNotEmpty) {
      yield Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message',
              style: base.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(message, style: base.copyWith(color: scheme.onSurface)),
          ],
        ),
      );
    }

    if (stackTrace != null && stackTrace.isNotEmpty) {
      yield Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stack trace',
              style: base.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                stackTrace,
                style: base.copyWith(
                  fontFamily: 'monospace',
                  height: 1.2,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (runtimeContext != null && runtimeContext.isNotEmpty) {
      yield _buildFormattedMap(
        title: 'Runtime context',
        data: runtimeContext,
        base: base,
        scheme: scheme,
      );
    }

    if (panicTail != null && panicTail.isNotEmpty) {
      yield _buildFormattedMap(
        title: 'Panic tail',
        data: panicTail,
        base: base,
        scheme: scheme,
      );
    }

    if (archive != null && archive.isNotEmpty) {
      yield _buildFormattedMap(
        title: 'Archive',
        data: archive,
        base: base,
        scheme: scheme,
      );
    }

    if (loggingError != null && loggingError.isNotEmpty) {
      yield Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logging error',
              style: base.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(loggingError, style: base.copyWith(color: scheme.onSurface)),
          ],
        ),
      );
    }
  }

  Widget _buildFormattedMap({
    required String title,
    required Map<String, Object?> data,
    required TextStyle base,
    required ColorScheme scheme,
  }) {
    final String formatted = const JsonEncoder.withIndent('  ').convert(data);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: base.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              formatted,
              style: base.copyWith(
                fontFamily: 'monospace',
                height: 1.2,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GraphDiagnosticRecord record = widget.record;
    final ColorScheme scheme = widget.scheme;
    final bool showRaw = widget.forceRaw || _raw;

    final DateTime local = record.timestamp.toLocal();
    final String timestamp = formatJournalTimestamp(local);
    final String? relative = formatRelativeDuration(widget.deltaSincePrevious);
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final TextStyle secondary = base.copyWith(color: scheme.onSurfaceVariant);

    final Color containerColor = scheme.surfaceContainerHighest.withValues(
      alpha: 0.9,
    );
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.6);
    final String clipboardText = formatDiagnosticForClipboard(record);

    final List<GraphJournalMetadataChip> metadata = <GraphJournalMetadataChip>[
      GraphJournalMetadataChip(
        icon: Icons.schedule,
        label: timestamp,
        tooltip: 'Timestamp',
        scheme: scheme,
      ),
      if (relative != null)
        GraphJournalMetadataChip(
          icon: Icons.timelapse,
          label: relative,
          tooltip: 'Time since previous diagnostic',
          scheme: scheme,
        ),
    ];

    final Widget? docsButton = widget.onOpenDocs == null
        ? null
        : TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => widget.onOpenDocs!(record),
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: const Text('Docs'),
          );

    final List<Widget> actionButtons = <Widget>[
      GraphJournalRawToggleButton(
        scheme: scheme,
        active: showRaw,
        tooltip: showRaw
            ? 'Show formatted diagnostic'
            : 'Show raw diagnostic JSON',
        onPressed: widget.forceRaw ? null : _toggleRaw,
      ),
      Tooltip(
        message: 'Copy entry',
        child: IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.copy_outlined),
          onPressed: () {
            unawaited(Clipboard.setData(ClipboardData(text: clipboardText)));
          },
        ),
      ),
    ];
    if (docsButton != null) {
      actionButtons.add(
        Tooltip(message: 'Open documentation', child: docsButton),
      );
    }

    final List<Widget> headerChildren = <Widget>[
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          Text(
            record.codeEnum?.name ?? record.code,
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text('Source: ${record.source.name}', style: secondary),
    ];

    final bool hasSubjects = record.subjects.isNotEmpty;

    final List<Widget> bodyChildren = <Widget>[];
    if (showRaw) {
      bodyChildren
        ..add(const SizedBox(height: 8))
        ..add(
          SelectionArea(
            child: Text(
              formatDiagnosticJson(record, widget.deltaSincePrevious),
              style: base.copyWith(
                fontFamily: 'monospace',
                color: scheme.onSurface,
              ),
              maxLines: null,
            ),
          ),
        );
    } else {
      if (metadata.isNotEmpty || hasSubjects) {
        bodyChildren
          ..add(const SizedBox(height: 6))
          ..add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: metadata.isEmpty
                      ? const SizedBox.shrink()
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: metadata,
                        ),
                ),
              ],
            ),
          );
      }
      if (hasSubjects) {
        bodyChildren.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _buildDiagnosticDetailsContent(base: base, scheme: scheme),
          ),
        );
      }
      bodyChildren.addAll(_buildContextPreview(base: base, scheme: scheme));
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: (details) => showJournalContextMenu(
        context: context,
        globalPosition: details.globalPosition,
        clipboardText: clipboardText,
      ),
      onLongPressStart: (details) => showJournalContextMenu(
        context: context,
        globalPosition: details.globalPosition,
        clipboardText: clipboardText,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SelectionArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DiagnosticLevelBadge(
                          level: record.level,
                          scheme: scheme,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [...headerChildren, ...bodyChildren],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GraphJournalActionDivider(color: scheme.outlineVariant),
              const SizedBox(width: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actionButtons,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticLevelBadge extends StatelessWidget {
  const _DiagnosticLevelBadge({required this.level, required this.scheme});

  final UyavaDiagnosticLevel level;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (level) {
      UyavaDiagnosticLevel.info => scheme.primary,
      UyavaDiagnosticLevel.warning => colorForSeverity(UyavaSeverity.warn),
      UyavaDiagnosticLevel.error => scheme.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
