part of 'event_chains_panel.dart';

const EventChainTileController _chainTileController =
    EventChainTileController();

Color _colorWithOpacity(Color color, double opacity) {
  final int alpha = ((255 * opacity).round()).clamp(0, 255).toInt();
  return color.withAlpha(alpha);
}

class _ChainList extends StatelessWidget {
  const _ChainList({
    required this.chains,
    required this.onChainTap,
    required this.onAttemptSelected,
    required this.onReset,
    required this.onPinToggle,
  });

  final List<EventChainViewData> chains;
  final ValueChanged<String> onChainTap;
  final ValueChanged<String> onAttemptSelected;
  final ValueChanged<String> onReset;
  final ValueChanged<String> onPinToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: chains.length,
        separatorBuilder: (context, _) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final EventChainViewData data = chains[index];
          final EventChainTileState state = _chainTileController.build(data);

          return _ChainTile(
            key: ValueKey<String>('chain-tile-${state.chainId}'),
            state: state,
            onTap: () => onChainTap(state.chainId),
            onReset: () => onReset(state.chainId),
            onPinToggle: () => onPinToggle(state.chainId),
            onAttemptSelected: onAttemptSelected,
          );
        },
      ),
    );
  }
}

class _ChainTile extends StatelessWidget {
  const _ChainTile({
    super.key,
    required this.state,
    required this.onTap,
    required this.onReset,
    required this.onPinToggle,
    required this.onAttemptSelected,
  });

  final EventChainTileState state;
  final VoidCallback onTap;
  final VoidCallback onReset;
  final VoidCallback onPinToggle;
  final ValueChanged<String> onAttemptSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle summaryStyle =
        theme.textTheme.labelSmall ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
    final TextStyle progressStyle =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final BorderRadius borderRadius = BorderRadius.circular(12);
    final Color backgroundColor = theme.colorScheme.surfaceContainerHighest;
    final Color borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.7 : 0.55,
    );

    final Widget detail = state.expanded
        ? _ChainDetailContent(
            state: state,
            onAttemptSelected: onAttemptSelected,
          )
        : const SizedBox.shrink();

    final List<Widget> iconRowChildren = <Widget>[
      IconButton(
        icon: const Icon(Icons.push_pin_outlined),
        selectedIcon: const Icon(Icons.push_pin),
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        isSelected: state.pinned,
        tooltip: state.pinned ? 'Unpin chain' : 'Pin chain',
        onPressed: onPinToggle,
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        tooltip: 'Reset chain statistics',
        onPressed: state.canReset ? onReset : null,
      ),
    ];

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          state.chainId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          key: ValueKey<String>(
                            'chain-summary-${state.chainId}',
                          ),
                          text: TextSpan(
                            style: summaryStyle,
                            children: [
                              _statusSpan(
                                'Success ',
                                state.successCount,
                                _successHighlightColor,
                              ),
                              const TextSpan(text: ' · '),
                              _statusSpan(
                                'Fail ',
                                state.failureCount,
                                _failureHighlightColor,
                              ),
                              const TextSpan(text: ' · '),
                              _statusSpan(
                                'Active ',
                                state.activeCount,
                                _activeHighlightColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: iconRowChildren,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(state.progressLabel, style: progressStyle),
                            const SizedBox(width: 6),
                            Icon(
                              state.expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: detail,
              crossFadeState: state.expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 160),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  InlineSpan _statusSpan(String label, int value, Color highlight) {
    final TextStyle? style = value > 0 ? TextStyle(color: highlight) : null;
    return TextSpan(text: '$label$value', style: style);
  }
}

class _ChainDetailContent extends StatelessWidget {
  const _ChainDetailContent({
    required this.state,
    required this.onAttemptSelected,
  });

  final EventChainTileState state;
  final ValueChanged<String> onAttemptSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String description = state.description;
    final bool hasDescription = state.hasDescription;
    final bool hasTags = state.hasTags;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasDescription)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(description, style: theme.textTheme.bodySmall),
            ),
          if (hasTags) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String tag in state.tags)
                  _TagChip(theme: theme, tag: tag),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _AttemptsSection(
            attempts: state.attempts,
            selectedAttemptKey: state.selectedAttemptKey,
            onAttemptSelected: onAttemptSelected,
          ),
          const SizedBox(height: 16),
          _StepsSection(steps: state.steps),
        ],
      ),
    );
  }
}

const Color _successHighlightColor = Color(0xFF2E7D32);
const Color _failureHighlightColor = Color(0xFFC62828);
const Color _activeHighlightColor = Color(0xFFF9A825);
