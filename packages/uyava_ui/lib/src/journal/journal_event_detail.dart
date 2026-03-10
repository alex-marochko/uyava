import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'journal_entry.dart';
import 'journal_link.dart';
import 'journal_shared_widgets.dart';
import 'journal_view_model.dart';

class GraphJournalEventDetailsPane extends StatefulWidget {
  const GraphJournalEventDetailsPane({
    super.key,
    required this.entry,
    required this.cacheEntry,
    required this.scheme,
    this.onLinkTap,
    this.onOpenInIde,
  });

  final GraphJournalEventEntry entry;
  final GraphJournalEventDetailCache cacheEntry;
  final ColorScheme scheme;
  final ValueChanged<GraphJournalLinkTarget>? onLinkTap;
  final Future<void> Function(String sourceRef)? onOpenInIde;

  @override
  State<GraphJournalEventDetailsPane> createState() =>
      _GraphJournalEventDetailsPaneState();
}

class _GraphJournalEventDetailsPaneState
    extends State<GraphJournalEventDetailsPane> {
  late final ScrollController _payloadScrollController;

  @override
  void initState() {
    super.initState();
    _payloadScrollController = ScrollController();
  }

  @override
  void dispose() {
    _payloadScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final GraphJournalEventDetailCache cacheEntry = widget.cacheEntry;
    final ColorScheme scheme = widget.scheme;
    final TextStyle base =
        textTheme.bodySmall ?? const TextStyle(fontSize: 12, height: 1.35);
    final TextStyle mono = base.copyWith(
      fontFamily: 'monospace',
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.6);
    final Color background = scheme.surfaceContainerHighest.withValues(
      alpha: 0.9,
    );

    final List<GraphJournalMetadataChip> metadata = <GraphJournalMetadataChip>[
      GraphJournalMetadataChip(
        icon: Icons.schedule,
        label: cacheEntry.timestampLabel,
        tooltip: 'Timestamp',
        scheme: scheme,
      ),
      if (cacheEntry.relativeLabel != null)
        GraphJournalMetadataChip(
          icon: Icons.timelapse,
          label: cacheEntry.relativeLabel!,
          tooltip: 'Time since previous event',
          scheme: scheme,
        ),
      if (cacheEntry.isolateLabel != null)
        GraphJournalMetadataChip(
          icon: Icons.memory,
          label: cacheEntry.isolateLabel!,
          tooltip: 'Isolate',
          scheme: scheme,
        ),
      if (cacheEntry.sourceRef != null)
        GraphJournalMetadataChip(
          icon: Icons.code,
          label: cacheEntry.sourceRef!,
          tooltip: cacheEntry.sourceRef,
          scheme: scheme,
          onPressed: widget.onOpenInIde == null
              ? null
              : () => unawaited(widget.onOpenInIde!(cacheEntry.sourceRef!)),
          interactionKey: const Key('uyava_journal_source_ref'),
        ),
    ];

    final Widget subject =
        cacheEntry.focusTarget != null && widget.onLinkTap != null
        ? GraphJournalLinkText(
            label: cacheEntry.subjectLabel,
            onPressed: () => widget.onLinkTap!(cacheEntry.focusTarget!),
          )
        : Text(
            cacheEntry.subjectLabel,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          );

    final Widget? severityBadge = cacheEntry.severityLabel == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorForSeverity(
                cacheEntry.severity,
              ).withValues(alpha: 0.2),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
            child: Text(
              cacheEntry.severityLabel!,
              style: base.copyWith(
                color: colorForSeverity(cacheEntry.severity),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          );

    final Widget infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle.merge(
          style:
              textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ) ??
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          child: subject,
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: metadata),
      ],
    );

    final Widget actionsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (severityBadge != null) severityBadge,
        Tooltip(
          message: 'Copy entry',
          child: IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              unawaited(
                Clipboard.setData(ClipboardData(text: cacheEntry.jsonPayload)),
              );
            },
          ),
        ),
      ],
    );

    final Widget header = LayoutBuilder(
      builder: (context, constraints) {
        final bool narrow = constraints.maxWidth < 360;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              infoColumn,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: actionsColumn),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: infoColumn),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: actionsColumn,
            ),
          ],
        );
      },
    );

    final Widget messageBlock = SelectableText(
      cacheEntry.message,
      style:
          textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
            height: 1.4,
          ) ??
          base.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
    );

    final Widget jsonView = Scrollbar(
      thumbVisibility: true,
      controller: _payloadScrollController,
      child: SingleChildScrollView(
        controller: _payloadScrollController,
        primary: false,
        padding: const EdgeInsets.all(8),
        child: SelectionArea(
          child: Text(widget.cacheEntry.jsonPayload, style: mono),
        ),
      ),
    );

    final Widget payloadCard = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: jsonView,
    );

    return Container(
      key: const Key('uyava_journal_event_details_panel'),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool allowExpand =
              !constraints.hasBoundedHeight || constraints.maxHeight >= 220;
          final List<Widget> children = <Widget>[
            header,
            const SizedBox(height: 12),
            messageBlock,
            const SizedBox(height: 12),
            allowExpand ? Expanded(child: payloadCard) : payloadCard,
          ];
          if (allowExpand) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          }
          return SingleChildScrollView(
            primary: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          );
        },
      ),
    );
  }
}
