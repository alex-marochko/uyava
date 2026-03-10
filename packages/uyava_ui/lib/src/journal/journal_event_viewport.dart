part of 'journal_event_list.dart';

class _FormattedEventsViewport extends StatefulWidget {
  const _FormattedEventsViewport({
    required this.entries,
    required this.scheme,
    required this.controller,
    required this.onUserScrollAway,
    required this.onLinkTap,
    required this.onEventTap,
    required this.onOpenInIde,
    required this.detailsMode,
    required this.selectedSequence,
    required this.onSelectEntry,
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
  final bool detailsMode;
  final int? selectedSequence;
  final ValueChanged<GraphJournalEventEntry>? onSelectEntry;
  final int softLimit;
  final int totalTrimmed;
  final int? totalAvailable;
  final VoidCallback? onLoadMore;

  @override
  State<_FormattedEventsViewport> createState() =>
      _FormattedEventsViewportState();
}

class _FormattedEventsViewportState extends State<_FormattedEventsViewport> {
  int _lastSeenTrimTotal = 0;
  bool _nearBottom = true;
  double _pendingTrimCompensation = 0;
  bool _trimCompensationScheduled = false;
  bool _loadMorePending = false;

  @override
  void initState() {
    super.initState();
    _lastSeenTrimTotal = widget.totalTrimmed;
    widget.controller.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant _FormattedEventsViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalTrimmed != _lastSeenTrimTotal) {
      _lastSeenTrimTotal = widget.totalTrimmed;
      _compensateAfterTrim(widget.totalTrimmed - oldWidget.totalTrimmed);
    }
    if (widget.entries.length != oldWidget.entries.length ||
        !identical(widget.entries, oldWidget.entries)) {
      _loadMorePending = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (!widget.controller.hasClients) {
      _nearBottom = true;
      return;
    }
    final ScrollPosition position = widget.controller.position;
    final double maxExtent = position.maxScrollExtent;
    if (maxExtent <= 0) {
      _nearBottom = true;
      return;
    }
    final double distanceToBottom = maxExtent - position.pixels;
    final bool nearBottom = distanceToBottom <= _kJournalEventSlackExtent;
    if (!nearBottom && _nearBottom) {
      widget.onUserScrollAway();
    }
    if (nearBottom &&
        widget.onLoadMore != null &&
        !_loadMorePending &&
        widget.totalAvailable != null &&
        widget.entries.length < widget.totalAvailable!) {
      _loadMorePending = true;
      widget.onLoadMore!.call();
    }
    _nearBottom = nearBottom;
  }

  void _compensateAfterTrim(int trimmedCount) {
    if (_nearBottom || trimmedCount <= 0) {
      return;
    }
    if (!widget.controller.hasClients) {
      return;
    }
    _pendingTrimCompensation += trimmedCount * kGraphJournalEventItemExtent;
    if (_trimCompensationScheduled) {
      return;
    }
    _trimCompensationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trimCompensationScheduled = false;
      if (!mounted || _pendingTrimCompensation <= 0) {
        _pendingTrimCompensation = 0;
        return;
      }
      if (!widget.controller.hasClients) {
        _pendingTrimCompensation = 0;
        return;
      }
      final double nextOffset = math.max(
        0.0,
        widget.controller.position.pixels - _pendingTrimCompensation,
      );
      _pendingTrimCompensation = 0;
      widget.controller.jumpTo(nextOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showSoftLimitHint =
        widget.softLimit > 0 &&
        (widget.entries.length >= widget.softLimit || widget.totalTrimmed > 0);
    final String limitDescription = widget.softLimit > 0
        ? widget.softLimit.toString()
        : 'recent';

    final Widget listView = ListView.builder(
      key: const PageStorageKey<String>('uyava_journal_events'),
      controller: widget.controller,
      physics: const AlwaysScrollableScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      padding: EdgeInsets.only(top: showSoftLimitHint ? 56 : 0, bottom: 8),
      itemExtent: kGraphJournalEventItemExtent,
      cacheExtent: kGraphJournalEventItemExtent * 40,
      itemCount: widget.entries.length,
      itemBuilder: (context, index) {
        final entry = widget.entries[index];
        return KeyedSubtree(
          key: ValueKey<int>(entry.sequence),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: _CompactEventRow(
              entry: entry,
              scheme: widget.scheme,
              onLinkTap: widget.onLinkTap,
              onEntryTap: widget.onEventTap,
              onOpenInIde: widget.onOpenInIde,
              detailsMode: widget.detailsMode,
              selected:
                  widget.selectedSequence != null &&
                  widget.selectedSequence == entry.sequence,
              onSelect: widget.onSelectEntry == null
                  ? null
                  : () => widget.onSelectEntry!(entry),
            ),
          ),
        );
      },
    );

    if (!showSoftLimitHint) {
      return listView;
    }

    return Stack(
      children: [
        listView,
        if (showSoftLimitHint)
          Positioned(
            top: _kJournalEventsOverflowInset,
            left: _kJournalEventsOverflowHintIndent,
            child: IgnorePointer(
              child: GraphJournalOverflowNotice(
                message:
                    'Showing the last $limitDescription events; older entries were trimmed automatically.',
              ),
            ),
          ),
      ],
    );
  }
}

class _CompactEventRow extends StatelessWidget {
  const _CompactEventRow({
    required this.entry,
    required this.scheme,
    this.onLinkTap,
    this.onEntryTap,
    this.onOpenInIde,
    required this.detailsMode,
    required this.selected,
    this.onSelect,
  });

  final GraphJournalEventEntry entry;
  final ColorScheme scheme;
  final ValueChanged<GraphJournalLinkTarget>? onLinkTap;
  final ValueChanged<GraphJournalEventEntry>? onEntryTap;
  final Future<void> Function(String sourceRef)? onOpenInIde;
  final bool detailsMode;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle primary =
        textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ) ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    final TextStyle secondary =
        textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant) ??
        const TextStyle(fontSize: 11.5);
    final TextStyle timestamp =
        textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ) ??
        TextStyle(
          fontSize: 11,
          color: scheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    final Color accent = colorForSeverity(
      entry.severity,
    ).withValues(alpha: 0.85);
    final GraphJournalLinkTarget? focusTarget = _linkTarget();
    final String? sourceRef = _sourceRef();
    final String timestampLabel = formatJournalTimestamp(
      entry.timestamp.toLocal(),
    );
    final String? relative = formatRelativeDuration(entry.deltaSincePrevious);
    final String clipboardText = formatEventEntryForClipboard(entry);
    final String subtitle = _buildSubtitle();
    final Color containerColor = selected
        ? scheme.tertiaryContainer.withValues(alpha: 0.65)
        : Colors.transparent;
    final Color containerBorder = selected
        ? scheme.tertiary.withValues(alpha: 0.9)
        : Colors.transparent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (details) => showJournalContextMenu(
        context: context,
        globalPosition: details.globalPosition,
        clipboardText: clipboardText,
        focusTarget: focusTarget,
        onLinkTap: onLinkTap,
        sourceRef: sourceRef,
        onOpenInIde: onOpenInIde,
      ),
      onLongPressStart: (details) => showJournalContextMenu(
        context: context,
        globalPosition: details.globalPosition,
        clipboardText: clipboardText,
        focusTarget: focusTarget,
        onLinkTap: onLinkTap,
        sourceRef: sourceRef,
        onOpenInIde: onOpenInIde,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap:
              (onSelect != null ||
                  onEntryTap != null ||
                  (focusTarget != null && onLinkTap != null))
              ? () => _handleTap(focusTarget)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: containerBorder, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool stackTimestamp = constraints.maxWidth < 360;
                final Widget timestampBlock = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(timestampLabel, style: timestamp),
                    if (relative != null) Text(relative, style: timestamp),
                  ],
                );

                final Widget textBlock = Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _primaryLabel(),
                        style: primary,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: secondary,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );

                final List<Widget> rowChildren = <Widget>[
                  Container(
                    width: 4,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  textBlock,
                ];

                if (!stackTimestamp) {
                  rowChildren
                    ..add(const SizedBox(width: 12))
                    ..add(timestampBlock);
                  return Row(children: rowChildren);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: rowChildren),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: timestampBlock,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(GraphJournalLinkTarget? focusTarget) {
    if (onSelect != null) {
      onSelect!();
    }
    if (onEntryTap != null) {
      onEntryTap!(entry);
    }
    final bool shouldTriggerLink = !detailsMode || onSelect == null;
    if (shouldTriggerLink && focusTarget != null && onLinkTap != null) {
      onLinkTap!(focusTarget);
    }
  }

  String _primaryLabel() {
    switch (entry.kind) {
      case GraphJournalEventKind.node:
        return entry.nodeEvent!.nodeId;
      case GraphJournalEventKind.edge:
        return '${entry.edgeEvent!.from} → ${entry.edgeEvent!.to}';
    }
  }

  String _buildSubtitle() {
    switch (entry.kind) {
      case GraphJournalEventKind.node:
        final UyavaNodeEvent event = entry.nodeEvent!;
        final List<String>? tags = event.tags;
        if (tags != null && tags.isNotEmpty) {
          return '${event.message} · [${tags.join(', ')}]';
        }
        return event.message;
      case GraphJournalEventKind.edge:
        return entry.edgeEvent!.message;
    }
  }

  GraphJournalLinkTarget? _linkTarget() {
    switch (entry.kind) {
      case GraphJournalEventKind.node:
        final UyavaNodeEvent? event = entry.nodeEvent;
        if (event == null) return null;
        return GraphJournalNodeLink(nodeId: event.nodeId, event: event);
      case GraphJournalEventKind.edge:
        final UyavaEvent? event = entry.edgeEvent;
        if (event == null) return null;
        return GraphJournalEdgeLink(
          from: event.from,
          to: event.to,
          event: event,
        );
    }
  }

  String? _sourceRef() {
    final String? value = switch (entry.kind) {
      GraphJournalEventKind.node => entry.nodeEvent?.sourceRef,
      GraphJournalEventKind.edge => entry.edgeEvent?.sourceRef,
    };
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
