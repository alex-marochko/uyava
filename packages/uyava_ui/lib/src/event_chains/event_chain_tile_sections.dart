part of 'event_chains_panel.dart';

class _AttemptsSection extends StatelessWidget {
  const _AttemptsSection({
    required this.attempts,
    required this.selectedAttemptKey,
    required this.onAttemptSelected,
  });

  final List<EventChainAttemptViewData> attempts;
  final String? selectedAttemptKey;
  final ValueChanged<String> onAttemptSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasAttempts = attempts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Active attempts',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (!hasAttempts)
          const _AttemptChipsPlaceholder()
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final EventChainAttemptViewData attempt in attempts)
                _AttemptChip(
                  theme: theme,
                  attempt: attempt,
                  isSelected: attempt.key == selectedAttemptKey,
                  onTap: () => onAttemptSelected(attempt.key),
                ),
            ],
          ),
      ],
    );
  }
}

class _AttemptChip extends StatelessWidget {
  const _AttemptChip({
    required this.theme,
    required this.attempt,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeData theme;
  final EventChainAttemptViewData attempt;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? labelStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
    );

    return ChoiceChip(
      label: Text('${attempt.index + 1}', style: labelStyle),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: _colorWithOpacity(colors.surfaceContainerHighest, 0.2),
      selectedColor: _colorWithOpacity(colors.primary, 0.2),
      side: BorderSide(
        color: isSelected
            ? _colorWithOpacity(colors.primary, 0.5)
            : _colorWithOpacity(colors.outlineVariant, 0.5),
      ),
    );
  }
}

class _AttemptChipsPlaceholder extends StatelessWidget {
  const _AttemptChipsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Chip(
      avatar: Icon(
        Icons.hourglass_empty,
        size: 16,
        color: _colorWithOpacity(colors.onSurfaceVariant, 0.8),
      ),
      label: Text(
        'No active attempts',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      backgroundColor: _colorWithOpacity(colors.surfaceContainerHighest, 0.2),
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection({required this.steps});

  final List<ChainStepViewModel> steps;

  static const Color _successColor = Color(0xFF2E7D32);
  static const Color _activeColor = Color(0xFFF9A825);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Steps',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (steps.isEmpty)
          Text(
            'No steps defined for this chain',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (BuildContext context, int index) {
              final ChainStepViewModel step = steps[index];
              final Color iconColor = _colorForStatus(step.status, theme);
              final IconData iconData = _iconForStatus(step.status);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(iconData, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${step.index + 1}. ${step.stepId}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: step.status == ChainStepStatus.current
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.subtitle,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Color _colorForStatus(ChainStepStatus status, ThemeData theme) {
    switch (status) {
      case ChainStepStatus.completed:
        return _successColor;
      case ChainStepStatus.current:
        return _activeColor;
      case ChainStepStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _iconForStatus(ChainStepStatus status) {
    switch (status) {
      case ChainStepStatus.completed:
        return Icons.check_circle;
      case ChainStepStatus.current:
        return Icons.play_circle_outline;
      case ChainStepStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.theme, required this.tag});

  final ThemeData theme;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No event chains',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
