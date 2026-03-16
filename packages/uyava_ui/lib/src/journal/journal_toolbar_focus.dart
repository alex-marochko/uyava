part of 'journal_toolbar.dart';

class _FocusSummaryButton extends StatelessWidget {
  const _FocusSummaryButton({
    required this.context,
    required this.summaryLabel,
    required this.paused,
    required this.onRemoveNode,
    required this.onRemoveEdge,
  });

  final GraphJournalFocusContext context;
  final String summaryLabel;
  final bool paused;
  final ValueChanged<String>? onRemoveNode;
  final ValueChanged<String>? onRemoveEdge;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? baseLabelStyle = Theme.of(context).textTheme.labelSmall;
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.7);
    final Color background = paused
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
        : scheme.tertiaryContainer.withValues(alpha: 0.65);
    final Color foreground = paused
        ? scheme.onSurfaceVariant
        : scheme.onTertiaryContainer;
    final bool canRemoveNodes = onRemoveNode != null;
    final bool canRemoveEdges = onRemoveEdge != null;
    final bool hasEntries = this.context.entries.isNotEmpty;

    return PopupMenuButton<_FocusMenuSelection?>(
      tooltip: 'Focused items',
      enabled: hasEntries,
      onSelected: (selection) {
        if (selection == null) return;
        if (selection.kind == _FocusMenuSelectionKind.node) {
          onRemoveNode?.call(selection.id);
        } else {
          onRemoveEdge?.call(selection.id);
        }
      },
      itemBuilder: (context) {
        if (!hasEntries) {
          return const <PopupMenuEntry<_FocusMenuSelection?>>[];
        }
        return this.context.entries
            .map((entry) {
              final bool canRemove = entry.isNode
                  ? canRemoveNodes
                  : canRemoveEdges;
              return PopupMenuItem<_FocusMenuSelection?>(
                value: canRemove
                    ? (entry.isNode
                          ? _FocusMenuSelection.node(entry.id)
                          : _FocusMenuSelection.edge(entry.id))
                    : null,
                enabled: canRemove,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.isNode ? Icons.circle : Icons.alt_route,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.label, overflow: TextOverflow.ellipsis),
                    ),
                    if (canRemove) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.close,
                        size: 14,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ],
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: Container(
        height: _kJournalToolbarButtonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.center_focus_strong,
              size: 16,
              color: foreground.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              summaryLabel,
              style: baseLabelStyle?.copyWith(
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusActions extends StatelessWidget {
  const _FocusActions({
    required this.focusContext,
    required this.focusFilterPaused,
    required this.onFocusFilterToggle,
    required this.onClearFocus,
    required this.onRevealFocus,
    required this.tooltip,
  });

  final GraphJournalFocusContext focusContext;
  final bool focusFilterPaused;
  final VoidCallback? onFocusFilterToggle;
  final VoidCallback? onClearFocus;
  final Future<void> Function()? onRevealFocus;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[
      _FocusPauseButton(
        paused: focusFilterPaused,
        onPressed: onFocusFilterToggle,
        tooltip: tooltip,
      ),
    ];
    final Widget? reveal = onRevealFocus == null
        ? null
        : _FocusRevealButton(onReveal: onRevealFocus!);
    if (reveal != null) {
      buttons.add(reveal);
    }
    if (onClearFocus != null) {
      buttons.add(_FocusClearButton(onPressed: onClearFocus!));
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: buttons,
    );
  }
}

class _FocusPauseButton extends StatelessWidget {
  const _FocusPauseButton({
    required this.paused,
    required this.onPressed,
    required this.tooltip,
  });

  final bool paused;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return UyavaToolbarIconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      isActive: !paused,
      icon: Icon(paused ? Icons.play_arrow : Icons.pause, size: 18),
    );
  }
}

class _FocusRevealButton extends StatelessWidget {
  const _FocusRevealButton({required Future<void> Function() onReveal})
    : _onReveal = onReveal;

  final Future<void> Function() _onReveal;

  @override
  Widget build(BuildContext context) {
    return UyavaToolbarIconButton(
      tooltip: 'Reveal focused items',
      onPressed: () {
        unawaited(_onReveal());
      },
      icon: const Icon(Icons.zoom_in_map, size: 18),
    );
  }
}

class _FocusClearButton extends StatelessWidget {
  const _FocusClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return UyavaToolbarIconButton(
      tooltip: 'Clear focus selection',
      onPressed: onPressed,
      icon: const Icon(Icons.filter_alt_off, size: 18),
    );
  }
}

enum _FocusMenuSelectionKind { node, edge }

class _FocusMenuSelection {
  const _FocusMenuSelection._(this.kind, this.id);

  const _FocusMenuSelection.node(String id)
    : this._(_FocusMenuSelectionKind.node, id);

  const _FocusMenuSelection.edge(String id)
    : this._(_FocusMenuSelectionKind.edge, id);

  final _FocusMenuSelectionKind kind;
  final String id;
}
