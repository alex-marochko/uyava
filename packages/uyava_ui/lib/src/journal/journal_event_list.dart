import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

import '../theme.dart';
import 'journal_actions.dart';
import 'journal_entry.dart';
import 'journal_event_detail.dart';
import 'journal_link.dart';
import 'journal_shared_widgets.dart';
import 'journal_view_model.dart';

part 'journal_event_viewport.dart';

const double kGraphJournalEventItemExtent = 52.0;
const double _kJournalEventSlackExtent = kGraphJournalEventItemExtent * 3;
const double _kJournalEventsOverflowInset = 8.0;
const double _kJournalEventsOverflowHintIndent = 40.0;
const double _kJournalDetailsSplitBreakpoint = 720;

class GraphJournalEventList extends StatelessWidget {
  const GraphJournalEventList({
    super.key,
    required this.entries,
    required this.scheme,
    required this.controller,
    required this.onUserScrollAway,
    required this.emptyMessage,
    this.onLinkTap,
    this.onEventTap,
    this.onOpenInIde,
    required this.detailsMode,
    required this.detailCache,
    required this.detailCacheBuilder,
    this.selectedSequence,
    this.onSelectEntry,
    required this.softLimit,
    required this.totalTrimmed,
    this.totalAvailable,
    this.onLoadMore,
  });

  final List<GraphJournalEventEntry> entries;
  final ColorScheme scheme;
  final ScrollController controller;
  final VoidCallback onUserScrollAway;
  final ValueChanged<GraphJournalLinkTarget>? onLinkTap;
  final ValueChanged<GraphJournalEventEntry>? onEventTap;
  final Future<void> Function(String sourceRef)? onOpenInIde;
  final String emptyMessage;
  final bool detailsMode;
  final Map<int, GraphJournalEventDetailCache> detailCache;
  final GraphJournalEventDetailCache Function(GraphJournalEventEntry entry)
  detailCacheBuilder;
  final int? selectedSequence;
  final ValueChanged<GraphJournalEventEntry>? onSelectEntry;
  final int softLimit;
  final int totalTrimmed;
  final int? totalAvailable;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return GraphJournalEmptyState(
        icon: Icons.timeline,
        message: emptyMessage,
        padding: const EdgeInsets.symmetric(vertical: 28),
      );
    }

    GraphJournalEventEntry? selectedEntry;
    if (detailsMode && selectedSequence != null) {
      try {
        selectedEntry = entries.firstWhere(
          (entry) => entry.sequence == selectedSequence,
        );
      } catch (_) {
        selectedEntry = null;
      }
    }

    final Widget formattedViewport = _FormattedEventsViewport(
      entries: entries,
      scheme: scheme,
      controller: controller,
      onUserScrollAway: onUserScrollAway,
      onLinkTap: onLinkTap,
      onEventTap: onEventTap,
      onOpenInIde: onOpenInIde,
      detailsMode: detailsMode,
      selectedSequence: selectedSequence,
      onSelectEntry: onSelectEntry,
      softLimit: softLimit,
      totalTrimmed: totalTrimmed,
      totalAvailable: totalAvailable,
      onLoadMore: onLoadMore,
    );

    if (!detailsMode || selectedEntry == null) {
      return formattedViewport;
    }

    final GraphJournalEventEntry nonNullEntry = selectedEntry;
    final GraphJournalEventDetailCache cacheEntry = detailCache.putIfAbsent(
      nonNullEntry.sequence,
      () => detailCacheBuilder(nonNullEntry),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stackVertically =
            constraints.maxWidth < _kJournalDetailsSplitBreakpoint;
        final Widget detailsPanel = GraphJournalEventDetailsPane(
          entry: nonNullEntry,
          cacheEntry: cacheEntry,
          scheme: scheme,
          onLinkTap: onLinkTap,
          onOpenInIde: onOpenInIde,
        );
        if (stackVertically) {
          return Column(
            children: [
              Expanded(child: formattedViewport),
              const SizedBox(height: 12),
              SizedBox(
                height: math.min(320, constraints.maxHeight * 0.55),
                child: detailsPanel,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: formattedViewport),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: detailsPanel),
          ],
        );
      },
    );
  }
}
