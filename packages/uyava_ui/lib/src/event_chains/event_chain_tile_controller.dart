part of 'event_chains_panel.dart';

/// Derives render-friendly state for an event chain tile.
class EventChainTileController {
  const EventChainTileController();

  EventChainTileState build(EventChainViewData viewData) {
    final GraphEventChainSnapshot snapshot = viewData.snapshot;
    final UyavaEventChainDefinitionPayload definition = snapshot.definition;
    final String title = _resolveTitle(definition.label, snapshot.id);

    return EventChainTileState(
      chainId: snapshot.id,
      title: title,
      successCount: snapshot.successCount,
      failureCount: snapshot.failureCount,
      activeCount: snapshot.activeAttempts.length,
      progressLabel: viewData.progressLabel,
      description: (definition.description ?? '').trim(),
      tags: definition.tags,
      attempts: viewData.attempts,
      selectedAttemptKey: viewData.selectedAttemptKey,
      steps: _buildSteps(definition.steps, viewData.selectedAttempt),
      expanded: viewData.isSelected,
      pinned: viewData.pinned,
    );
  }

  List<ChainStepViewModel> _buildSteps(
    List<UyavaEventChainStepPayload> steps,
    GraphEventChainAttemptSnapshot? attempt,
  ) {
    final Set<String> completedSteps =
        attempt?.completedSteps.toSet() ?? const <String>{};
    final int nextIndex = attempt?.nextStepIndex ?? 0;

    final List<ChainStepViewModel> result = <ChainStepViewModel>[];
    for (int index = 0; index < steps.length; index++) {
      final UyavaEventChainStepPayload step = steps[index];
      final ChainStepStatus status;
      if (completedSteps.contains(step.stepId) ||
          (attempt != null && index < nextIndex)) {
        status = ChainStepStatus.completed;
      } else if (attempt != null && index == nextIndex) {
        status = ChainStepStatus.current;
      } else {
        status = ChainStepStatus.pending;
      }

      result.add(
        ChainStepViewModel(
          index: index,
          stepId: step.stepId,
          subtitle: _stepSubtitle(step),
          status: status,
        ),
      );
    }
    return result;
  }

  String _resolveTitle(String? label, String fallback) {
    final String normalized = (label ?? '').trim();
    return normalized.isNotEmpty ? normalized : fallback;
  }

  String _stepSubtitle(UyavaEventChainStepPayload step) {
    final List<String> segments = <String>['Node: ${step.nodeId}'];
    if ((step.edgeId ?? '').isNotEmpty) {
      segments.add('Edge: ${step.edgeId}');
    }
    if (step.expectedSeverity != null) {
      segments.add('Expected: ${step.expectedSeverity!.name}');
    }
    return segments.join(' · ');
  }
}

class EventChainTileState {
  const EventChainTileState({
    required this.chainId,
    required this.title,
    required this.successCount,
    required this.failureCount,
    required this.activeCount,
    required this.progressLabel,
    required this.description,
    required this.tags,
    required this.attempts,
    required this.selectedAttemptKey,
    required this.steps,
    required this.expanded,
    required this.pinned,
  });

  final String chainId;
  final String title;
  final int successCount;
  final int failureCount;
  final int activeCount;
  final String progressLabel;
  final String description;
  final List<String> tags;
  final List<EventChainAttemptViewData> attempts;
  final String? selectedAttemptKey;
  final List<ChainStepViewModel> steps;
  final bool expanded;
  final bool pinned;

  bool get canReset => successCount > 0 || failureCount > 0 || activeCount > 0;
  bool get hasDescription => description.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
}

class ChainStepViewModel {
  const ChainStepViewModel({
    required this.index,
    required this.stepId,
    required this.subtitle,
    required this.status,
  });

  final int index;
  final String stepId;
  final String subtitle;
  final ChainStepStatus status;
}

enum ChainStepStatus { completed, current, pending }
