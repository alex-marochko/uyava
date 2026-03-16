import 'package:collection/collection.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

/// Snapshot describing an event chain and its runtime statistics.
class GraphEventChainSnapshot {
  GraphEventChainSnapshot({
    required this.definition,
    required this.successCount,
    required this.failureCount,
    required List<GraphEventChainAttemptSnapshot> activeAttempts,
  }) : activeAttempts = List<GraphEventChainAttemptSnapshot>.unmodifiable(
         activeAttempts,
       );

  /// Latest chain definition provided by the host.
  final UyavaEventChainDefinitionPayload definition;

  /// Number of completed attempts for this chain.
  final int successCount;

  /// Number of failed attempts for this chain.
  final int failureCount;

  /// Currently active attempts (sequential or tagged).
  final List<GraphEventChainAttemptSnapshot> activeAttempts;

  /// Convenience accessor for the chain identifier.
  String get id => definition.id;
}

/// Snapshot describing the progress of a single attempt.
class GraphEventChainAttemptSnapshot {
  GraphEventChainAttemptSnapshot({
    required this.attemptId,
    required List<String> completedSteps,
    required this.nextStepIndex,
    required this.startedAt,
    required this.lastUpdatedAt,
  }) : completedSteps = List<String>.unmodifiable(completedSteps);

  /// Attempt identifier provided by the host (or `null` for sequential mode).
  final String? attemptId;

  /// Ordered list of completed step identifiers.
  final List<String> completedSteps;

  /// Index of the next expected step.
  final int nextStepIndex;

  /// Timestamp of the first recorded step (UTC).
  final DateTime startedAt;

  /// Timestamp of the most recent recorded step (UTC).
  final DateTime lastUpdatedAt;
}

/// Diagnostic produced while processing event chain payloads.
class GraphEventChainDiagnostic {
  const GraphEventChainDiagnostic({required this.code, this.context});

  final UyavaGraphIntegrityCode code;
  final Map<String, Object?>? context;
}

/// Registration result for event chain definitions.
class GraphEventChainRegistrationResult {
  const GraphEventChainRegistrationResult({
    required this.snapshot,
    required this.updated,
    required this.diagnostics,
  });

  /// Current snapshot for the chain after applying the definition.
  final GraphEventChainSnapshot? snapshot;

  /// Whether the definition changed the stored state.
  final bool updated;

  /// Diagnostics emitted while handling the definition.
  final List<GraphEventChainDiagnostic> diagnostics;
}

/// Runtime progress outcome for a processed event.
enum GraphEventChainProgressStatus { ignored, progressed, completed, failed }

/// Result of applying a runtime chain event.
class GraphEventChainProgressResult {
  const GraphEventChainProgressResult({
    required this.snapshot,
    required this.status,
    required this.diagnostics,
    this.attemptId,
  });

  /// Snapshot for the chain after the event (when available).
  final GraphEventChainSnapshot? snapshot;

  /// Status describing how the event affected the chain.
  final GraphEventChainProgressStatus status;

  /// Diagnostics produced while processing the event.
  final List<GraphEventChainDiagnostic> diagnostics;

  /// Attempt identifier associated with the processed event, if any.
  final String? attemptId;

  /// Whether the event modified the underlying state (progress/fail/complete).
  bool get applied => status != GraphEventChainProgressStatus.ignored;
}

/// Sanitized runtime event data consumed by the chain store.
class GraphEventChainEvent {
  const GraphEventChainEvent({
    required this.chainId,
    required this.stepId,
    required this.nodeId,
    required this.timestamp,
    this.edgeId,
    this.attemptId,
    this.severity,
    this.isFailure = false,
  });

  final String chainId;
  final String stepId;
  final String nodeId;
  final DateTime timestamp;
  final String? edgeId;
  final String? attemptId;
  final UyavaSeverity? severity;
  final bool isFailure;
}

/// In-memory store for event chain definitions and progress tracking.
class GraphEventChainStore {
  GraphEventChainStore();

  final Map<String, _ChainState> _chains = <String, _ChainState>{};
  final ListEquality<UyavaEventChainStepPayload> _stepListEquality =
      const ListEquality<UyavaEventChainStepPayload>();

  GraphEventChainRegistrationResult register(
    UyavaEventChainDefinitionPayload payload,
  ) {
    final _ChainState? existing = _chains[payload.id];
    if (existing == null) {
      final _ChainState state = _ChainState(payload);
      _chains[payload.id] = state;
      return GraphEventChainRegistrationResult(
        snapshot: state.toSnapshot(),
        updated: true,
        diagnostics: const <GraphEventChainDiagnostic>[],
      );
    }

    final List<GraphEventChainDiagnostic> diagnostics =
        <GraphEventChainDiagnostic>[];
    final bool stepsChanged = !_stepListEquality.equals(
      existing.definition.steps,
      payload.steps,
    );
    final bool metadataChanged = existing.definition != payload;

    existing.replaceDefinition(payload, resetStatistics: stepsChanged);

    if (stepsChanged) {
      diagnostics.add(
        GraphEventChainDiagnostic(
          code: UyavaGraphIntegrityCode.chainsConflictingDefinition,
          context: <String, Object?>{'chainId': payload.id},
        ),
      );
    }

    return GraphEventChainRegistrationResult(
      snapshot: existing.toSnapshot(),
      updated: metadataChanged || stepsChanged,
      diagnostics: diagnostics,
    );
  }

  GraphEventChainProgressResult record(GraphEventChainEvent event) {
    final _ChainState? state = _chains[event.chainId];
    if (state == null) {
      return GraphEventChainProgressResult(
        snapshot: null,
        status: GraphEventChainProgressStatus.ignored,
        diagnostics: <GraphEventChainDiagnostic>[
          GraphEventChainDiagnostic(
            code: UyavaGraphIntegrityCode.chainsUnknownId,
            context: <String, Object?>{'chainId': event.chainId},
          ),
        ],
        attemptId: event.attemptId,
      );
    }

    return state.record(event);
  }

  List<GraphEventChainSnapshot> allSnapshots() {
    return _chains.values
        .map((state) => state.toSnapshot())
        .toList(growable: false);
  }

  GraphEventChainSnapshot? snapshotFor(String chainId) {
    final _ChainState? state = _chains[chainId];
    return state?.toSnapshot();
  }

  bool reset(String chainId) {
    final _ChainState? state = _chains[chainId];
    if (state == null) {
      return false;
    }
    return state.reset();
  }

  bool resetAll() {
    bool changed = false;
    for (final _ChainState state in _chains.values) {
      if (state.reset()) {
        changed = true;
      }
    }
    return changed;
  }

  bool clear() {
    if (_chains.isEmpty) return false;
    _chains.clear();
    return true;
  }
}

class _ChainState {
  _ChainState(UyavaEventChainDefinitionPayload definition)
    : _definition = definition {
    _rebuildStepIndex();
  }

  UyavaEventChainDefinitionPayload _definition;
  int _successCount = 0;
  int _failureCount = 0;
  _AttemptState? _sequentialAttempt;
  final Map<String, _AttemptState> _attempts = <String, _AttemptState>{};
  final Map<String, UyavaEventChainStepPayload> _stepsById =
      <String, UyavaEventChainStepPayload>{};
  final Map<String, int> _stepIndexById = <String, int>{};

  UyavaEventChainDefinitionPayload get definition => _definition;

  GraphEventChainSnapshot toSnapshot() {
    final List<GraphEventChainAttemptSnapshot> attempts =
        <GraphEventChainAttemptSnapshot>[];
    if (_sequentialAttempt != null) {
      attempts.add(_sequentialAttempt!.toSnapshot(null));
    }
    final List<String> sortedAttemptIds = _attempts.keys.toList()..sort();
    for (final String attemptId in sortedAttemptIds) {
      attempts.add(_attempts[attemptId]!.toSnapshot(attemptId));
    }
    return GraphEventChainSnapshot(
      definition: _definition,
      successCount: _successCount,
      failureCount: _failureCount,
      activeAttempts: attempts,
    );
  }

  bool reset() {
    final bool hadSequentialAttempt = _sequentialAttempt != null;
    final bool hadNamedAttempts = _attempts.isNotEmpty;
    final bool hadHistory =
        _successCount != 0 ||
        _failureCount != 0 ||
        hadSequentialAttempt ||
        hadNamedAttempts;
    if (!hadHistory) {
      return false;
    }
    _successCount = 0;
    _failureCount = 0;
    _sequentialAttempt = null;
    if (_attempts.isNotEmpty) {
      _attempts.clear();
    }
    return true;
  }

  GraphEventChainProgressResult record(GraphEventChainEvent event) {
    final UyavaEventChainStepPayload? stepPayload = _stepsById[event.stepId];
    if (stepPayload == null) {
      return _result(
        GraphEventChainProgressStatus.ignored,
        diagnostics: <GraphEventChainDiagnostic>[
          GraphEventChainDiagnostic(
            code: UyavaGraphIntegrityCode.chainsUnknownStep,
            context: <String, Object?>{
              'chainId': event.chainId,
              'stepId': event.stepId,
            },
          ),
        ],
        attemptId: event.attemptId,
      );
    }

    if (stepPayload.nodeId != event.nodeId) {
      return _result(
        GraphEventChainProgressStatus.ignored,
        diagnostics: <GraphEventChainDiagnostic>[
          GraphEventChainDiagnostic(
            code: UyavaGraphIntegrityCode.chainsUnknownStep,
            context: <String, Object?>{
              'chainId': event.chainId,
              'stepId': event.stepId,
              'expectedNodeId': stepPayload.nodeId,
              'actualNodeId': event.nodeId,
            },
          ),
        ],
        attemptId: event.attemptId,
      );
    }

    if (stepPayload.edgeId != null && stepPayload.edgeId != event.edgeId) {
      return _result(
        GraphEventChainProgressStatus.ignored,
        diagnostics: <GraphEventChainDiagnostic>[
          GraphEventChainDiagnostic(
            code: UyavaGraphIntegrityCode.chainsUnknownStep,
            context: <String, Object?>{
              'chainId': event.chainId,
              'stepId': event.stepId,
              'expectedEdgeId': stepPayload.edgeId,
              'actualEdgeId': event.edgeId,
            },
          ),
        ],
        attemptId: event.attemptId,
      );
    }

    if (event.isFailure) {
      return _recordFailure(event);
    }

    if (event.attemptId == null) {
      return _recordSequential(event);
    }
    return _recordAttempt(event);
  }

  GraphEventChainProgressResult _recordFailure(GraphEventChainEvent event) {
    if (event.attemptId == null) {
      _failureCount++;
      _sequentialAttempt = null;
      return _result(GraphEventChainProgressStatus.failed, attemptId: null);
    }

    final String attemptId = event.attemptId!;
    _failureCount++;
    _attempts.remove(attemptId);
    return _result(GraphEventChainProgressStatus.failed, attemptId: attemptId);
  }

  GraphEventChainProgressResult _recordSequential(GraphEventChainEvent event) {
    final int stepIndex = _stepIndexById[event.stepId]!;
    final int lastIndex = _definition.steps.length - 1;
    final _AttemptState? attempt = _sequentialAttempt;

    if (attempt == null) {
      if (stepIndex != 0) {
        return _failWithInvalidOrder(
          expectedIndex: 0,
          actualStepId: event.stepId,
          attemptId: null,
        );
      }
      return _startSequentialAttempt(event, stepIndex, lastIndex);
    }

    final int expectedIndex = attempt.nextStepIndex;
    if (stepIndex == expectedIndex) {
      attempt.addStep(event.stepId, event.timestamp);
      if (attempt.nextStepIndex > lastIndex) {
        _successCount++;
        _sequentialAttempt = null;
        return _result(
          GraphEventChainProgressStatus.completed,
          attemptId: null,
        );
      }
      return _result(GraphEventChainProgressStatus.progressed, attemptId: null);
    }

    if (stepIndex == 0) {
      _failureCount++;
      final List<GraphEventChainDiagnostic> diagnostics =
          <GraphEventChainDiagnostic>[
            GraphEventChainDiagnostic(
              code: UyavaGraphIntegrityCode.chainsInvalidStepOrder,
              context: <String, Object?>{
                'chainId': _definition.id,
                'expectedStepId': _definition.steps[expectedIndex].stepId,
                'actualStepId': event.stepId,
              },
            ),
          ];
      return _startSequentialAttempt(
        event,
        stepIndex,
        lastIndex,
        diagnostics: diagnostics,
      );
    }

    if (stepIndex < expectedIndex) {
      // Duplicate step; ignore without altering state.
      return _result(GraphEventChainProgressStatus.ignored, attemptId: null);
    }

    _failureCount++;
    _sequentialAttempt = null;
    return _result(
      GraphEventChainProgressStatus.failed,
      diagnostics: <GraphEventChainDiagnostic>[
        GraphEventChainDiagnostic(
          code: UyavaGraphIntegrityCode.chainsInvalidStepOrder,
          context: <String, Object?>{
            'chainId': _definition.id,
            'expectedStepId': _definition.steps[expectedIndex].stepId,
            'actualStepId': event.stepId,
          },
        ),
      ],
      attemptId: null,
    );
  }

  GraphEventChainProgressResult _startSequentialAttempt(
    GraphEventChainEvent event,
    int stepIndex,
    int lastIndex, {
    List<GraphEventChainDiagnostic>? diagnostics,
  }) {
    final _AttemptState next = _AttemptState.start(
      stepId: event.stepId,
      timestamp: event.timestamp,
    );
    if (stepIndex == lastIndex) {
      _successCount++;
      _sequentialAttempt = null;
      return _result(
        GraphEventChainProgressStatus.completed,
        diagnostics: diagnostics,
        attemptId: null,
      );
    }

    _sequentialAttempt = next;
    return _result(
      GraphEventChainProgressStatus.progressed,
      diagnostics: diagnostics,
      attemptId: null,
    );
  }

  GraphEventChainProgressResult _recordAttempt(GraphEventChainEvent event) {
    final String attemptId = event.attemptId!;
    final int stepIndex = _stepIndexById[event.stepId]!;
    final int lastIndex = _definition.steps.length - 1;
    final _AttemptState? attempt = _attempts[attemptId];

    if (attempt == null) {
      if (stepIndex != 0) {
        return _failWithInvalidOrder(
          expectedIndex: 0,
          actualStepId: event.stepId,
          attemptId: attemptId,
        );
      }

      final _AttemptState next = _AttemptState.start(
        stepId: event.stepId,
        timestamp: event.timestamp,
      );
      if (stepIndex == lastIndex) {
        _successCount++;
        return _result(
          GraphEventChainProgressStatus.completed,
          attemptId: attemptId,
        );
      }

      _attempts[attemptId] = next;
      return _result(
        GraphEventChainProgressStatus.progressed,
        attemptId: attemptId,
      );
    }

    final int expectedIndex = attempt.nextStepIndex;
    if (stepIndex == expectedIndex) {
      attempt.addStep(event.stepId, event.timestamp);
      if (attempt.nextStepIndex > lastIndex) {
        _successCount++;
        _attempts.remove(attemptId);
        return _result(
          GraphEventChainProgressStatus.completed,
          attemptId: attemptId,
        );
      }
      return _result(
        GraphEventChainProgressStatus.progressed,
        attemptId: attemptId,
      );
    }

    if (stepIndex < expectedIndex) {
      // Duplicate step for the same attempt; ignore.
      return _result(
        GraphEventChainProgressStatus.ignored,
        attemptId: attemptId,
      );
    }

    _failureCount++;
    _attempts.remove(attemptId);
    return _result(
      GraphEventChainProgressStatus.failed,
      diagnostics: <GraphEventChainDiagnostic>[
        GraphEventChainDiagnostic(
          code: UyavaGraphIntegrityCode.chainsInvalidStepOrder,
          context: <String, Object?>{
            'chainId': _definition.id,
            'attemptId': attemptId,
            'expectedStepId': _definition.steps[expectedIndex].stepId,
            'actualStepId': event.stepId,
          },
        ),
      ],
      attemptId: attemptId,
    );
  }

  GraphEventChainProgressResult _failWithInvalidOrder({
    required int expectedIndex,
    required String actualStepId,
    required String? attemptId,
  }) {
    _failureCount++;
    String? expectedStepId;
    if (_definition.steps.isNotEmpty) {
      final int safeIndex = expectedIndex.clamp(
        0,
        _definition.steps.length - 1,
      );
      expectedStepId = _definition.steps[safeIndex].stepId;
    }
    return _result(
      GraphEventChainProgressStatus.failed,
      diagnostics: <GraphEventChainDiagnostic>[
        GraphEventChainDiagnostic(
          code: UyavaGraphIntegrityCode.chainsInvalidStepOrder,
          context: <String, Object?>{
            'chainId': _definition.id,
            if (expectedStepId != null) 'expectedStepId': expectedStepId,
            'actualStepId': actualStepId,
          },
        ),
      ],
      attemptId: attemptId,
    );
  }

  void replaceDefinition(
    UyavaEventChainDefinitionPayload payload, {
    required bool resetStatistics,
  }) {
    _definition = payload;
    _rebuildStepIndex();
    if (resetStatistics) {
      _successCount = 0;
      _failureCount = 0;
      _sequentialAttempt = null;
      _attempts.clear();
    }
  }

  void _rebuildStepIndex() {
    _stepsById.clear();
    _stepIndexById.clear();
    for (var index = 0; index < _definition.steps.length; index++) {
      final UyavaEventChainStepPayload step = _definition.steps[index];
      _stepsById[step.stepId] = step;
      _stepIndexById[step.stepId] = index;
    }
  }

  GraphEventChainProgressResult _result(
    GraphEventChainProgressStatus status, {
    List<GraphEventChainDiagnostic>? diagnostics,
    String? attemptId,
  }) {
    return GraphEventChainProgressResult(
      snapshot: toSnapshot(),
      status: status,
      diagnostics: diagnostics ?? const <GraphEventChainDiagnostic>[],
      attemptId: attemptId,
    );
  }
}

class _AttemptState {
  _AttemptState._({
    required List<String> completedSteps,
    required this.startedAt,
    required this.lastUpdatedAt,
  }) : _completedSteps = completedSteps;

  factory _AttemptState.start({
    required String stepId,
    required DateTime timestamp,
  }) {
    return _AttemptState._(
      completedSteps: <String>[stepId],
      startedAt: timestamp,
      lastUpdatedAt: timestamp,
    );
  }

  final List<String> _completedSteps;
  final DateTime startedAt;
  DateTime lastUpdatedAt;

  int get nextStepIndex => _completedSteps.length;

  void addStep(String stepId, DateTime timestamp) {
    _completedSteps.add(stepId);
    lastUpdatedAt = timestamp;
  }

  GraphEventChainAttemptSnapshot toSnapshot(String? attemptId) {
    return GraphEventChainAttemptSnapshot(
      attemptId: attemptId,
      completedSteps: List<String>.from(_completedSteps),
      nextStepIndex: nextStepIndex,
      startedAt: startedAt,
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}
