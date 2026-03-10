part of 'package:uyava_example/main.dart';

mixin _WrongDataTabMixin on _ExampleAppStateBase, _WrongDataLogicMixin {
  Widget _buildWrongDataTab() {
    final UyavaFileTransport? transport = currentFileTransport();
    final String? loggingDirectory = transport?.path;
    final bool loggingAvailable = transport != null;
    final UyavaDiscardStats? discardStats = _discardStats;

    final List<_WrongDataScenario> scenarios = <_WrongDataScenario>[
      _WrongDataScenario(
        title: 'Simulate Flutter framework error',
        description:
            'Schedules a synchronous widget-frame failure to exercise '
            'global FlutterError.onError logging. Expect the stack trace in '
            'console and a runtimeError panic tail in the .uyava archive.',
        onPressed: _triggerFlutterFrameworkError,
        buttonLabel: 'Throw Flutter error',
      ),
      _WrongDataScenario(
        title: 'Simulate async zone error',
        description:
            'Fires an unhandled Future error to validate runZoned capture '
            'and panic-tail flushing. Expect both console output and a '
            'runtimeError entry in the archive.',
        onPressed: _triggerAsyncZoneError,
        buttonLabel: 'Throw async error',
      ),
      _WrongDataScenario(
        title: 'Crash: Flutter framework error',
        description:
            'Reconfigures global error handlers to propagate and reports a '
            'FlutterError so the app terminates after panic-tail logging.',
        onPressed: _crashWithFlutterFrameworkError,
        buttonLabel: 'Crash via Flutter error',
      ),
      _WrongDataScenario(
        title: 'Crash: async zone error',
        description:
            'Turns on crash mode and throws an unhandled Future error captured '
            'by runZoned. Expect the app to exit once the panic-tail flushes.',
        onPressed: _crashWithAsyncZoneError,
        buttonLabel: 'Crash via async error',
      ),
      _WrongDataScenario(
        title: 'Self-loop edge (core validation)',
        description:
            'Adds a throwaway node + self-loop edge. Expect exactly one '
            '`edges.self_loop` entry.',
        onPressed: _emitSelfLoopEdge,
      ),
      _WrongDataScenario(
        title: 'Duplicate node ids + conflicting tags',
        description:
            'Publishes two payloads with the same id. First click emits '
            'a `nodes.duplicate_id` warning; change the payload or reuse the '
            'id with different tags to observe the follow-up '
            '`nodes.conflicting_tags` entry.',
        onPressed: _emitDuplicateNodeIds,
      ),
      _WrongDataScenario(
        title: 'Dangling edge (missing endpoints)',
        description:
            'Emits one edge with a missing source and another with a missing '
            'target. Expect both `edges.dangling_*` diagnostics.',
        onPressed: _emitDanglingEdge,
      ),
      _WrongDataScenario(
        title: 'Duplicate edge ids',
        description:
            'Creates two edges with the same id in a single payload. Expect '
            'a `edges.duplicate_id` warning for the latest writer.',
        onPressed: _emitDuplicateEdgeIds,
      ),
    ];

    return ListView(
      key: const ValueKey('wrong-data-list'),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset graph & diagnostics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Restores the base graph, clears all diagnostics in connected hosts, '
                  'and resets scenario counters.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  key: const ValueKey('reset-diagnostics-button'),
                  onPressed: _resetDiagnostics,
                  child: const Text('Reset diagnostics'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ErrorHooksCard(
          loggingAvailable: loggingAvailable,
          isolateErrorsEnabled: _isolateErrorsEnabled,
          captureCurrentIsolateErrors: _captureCurrentIsolateErrors,
          emitNonFatalDiagnostics: _emitNonFatalDiagnostics,
          isUpdating: _errorOptionsUpdating,
          onToggleIsolateErrors: (bool value) =>
              _applyErrorOptions(enableIsolateErrors: value),
          onToggleCaptureCurrent: (bool value) =>
              _applyErrorOptions(captureCurrentIsolateErrors: value),
          onToggleNonFatalDiagnostics: (bool value) =>
              _applyErrorOptions(emitNonFatalDiagnostics: value),
          onSpawnIsolateCrash: _spawnIsolateCrash,
          onAsyncOutsideGuard: _throwAsyncOutsideGuard,
          onPresentErrorOverride: _overrideOnErrorAndPresent,
          onEmitNonFatal: _emitNonFatalFlutterError,
          lastPanicDiagnostic: _lastPanicDiagnostic,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dropped events (discard stats stream)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Statistics update in real time through Uyava.discardStatsStream. '
                  'Adjust the minimum level, send lower-severity events from the '
                  'Targeted Events tab, or enable sampling to observe accumulated drops.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                DiscardStatsSummary(
                  loggingAvailable: loggingAvailable,
                  discardStats: discardStats,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minimum log level filter',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keeps events below the threshold out of the archive so the panic-tail stays compact. '
                  'Changing the value restarts the file transport.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                DropdownButton<UyavaSeverity>(
                  isExpanded: true,
                  value: _minLogLevel,
                  items: UyavaSeverity.values
                      .map(
                        (UyavaSeverity level) =>
                            DropdownMenuItem<UyavaSeverity>(
                              value: level,
                              child: Text(_severityLabel(level)),
                            ),
                      )
                      .toList(),
                  onChanged: (!loggingAvailable || _isUpdatingMinLevel)
                      ? null
                      : _changeMinLogLevel,
                ),
                if (!loggingAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'File logging is not available on this platform.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (_isUpdatingMinLevel) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panic-tail archives and live log',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  loggingDirectory != null
                      ? 'Current archives are stored in $loggingDirectory. '
                            'The stream below surfaces rotations, exports, and clones as soon as they are written without stopping the file logger.'
                      : 'File transport is not active. Enable logging to collect panic-tail archives.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ArchiveEventSection(
                  loggingAvailable: loggingAvailable,
                  streamAvailable: _archiveStreamAvailable,
                  events: _recentArchiveEvents,
                ),
                const SizedBox(height: 12),
                ArchiveActionButtons(
                  loggingAvailable: loggingAvailable,
                  isCloning: _isCloningLog,
                  isSending: _isSendingLog,
                  onClone: _cloneActiveArchive,
                  onExport: _sendLogArchive,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final _WrongDataScenario scenario in scenarios) ...[
          _DiagnosticScenarioCard(scenario: scenario),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _WrongDataScenario {
  const _WrongDataScenario({
    required this.title,
    required this.description,
    required this.onPressed,
    this.buttonLabel = 'Trigger diagnostics',
  });

  final String title;
  final String description;
  final VoidCallback onPressed;
  final String buttonLabel;
}

class _DiagnosticScenarioCard extends StatelessWidget {
  const _DiagnosticScenarioCard({required this.scenario});

  final _WrongDataScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scenario.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              scenario.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: scenario.onPressed,
              child: Text(scenario.buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorHooksCard extends StatelessWidget {
  const _ErrorHooksCard({
    required this.loggingAvailable,
    required this.isolateErrorsEnabled,
    required this.captureCurrentIsolateErrors,
    required this.emitNonFatalDiagnostics,
    required this.isUpdating,
    required this.onToggleIsolateErrors,
    required this.onToggleCaptureCurrent,
    required this.onToggleNonFatalDiagnostics,
    required this.onSpawnIsolateCrash,
    required this.onAsyncOutsideGuard,
    required this.onPresentErrorOverride,
    required this.onEmitNonFatal,
    required this.lastPanicDiagnostic,
  });

  final bool loggingAvailable;
  final bool isolateErrorsEnabled;
  final bool captureCurrentIsolateErrors;
  final bool emitNonFatalDiagnostics;
  final bool isUpdating;
  final ValueChanged<bool> onToggleIsolateErrors;
  final ValueChanged<bool> onToggleCaptureCurrent;
  final ValueChanged<bool> onToggleNonFatalDiagnostics;
  final VoidCallback onSpawnIsolateCrash;
  final VoidCallback onAsyncOutsideGuard;
  final VoidCallback onPresentErrorOverride;
  final VoidCallback onEmitNonFatal;
  final Map<String, dynamic>? lastPanicDiagnostic;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? body = theme.textTheme.bodySmall;
    final bool allowIsolateActions = loggingAvailable && isolateErrorsEnabled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error hooks and panic-tail demos',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Quick toggles for isolate forwarding, non-fatal diagnostics, and guard-zone checks. '
              'Use these to validate panic-tail coverage without editing the app.',
              style: body,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: isolateErrorsEnabled,
              onChanged: isUpdating ? null : onToggleIsolateErrors,
              title: const Text('Enable isolate error listener'),
              subtitle: const Text(
                'Forward spawned isolate errors via UyavaBootstrap.isolateErrorPort.',
              ),
            ),
            SwitchListTile(
              value: captureCurrentIsolateErrors,
              onChanged: isUpdating || !isolateErrorsEnabled
                  ? null
                  : onToggleCaptureCurrent,
              title: const Text('Capture current isolate (no runZoned)'),
              subtitle: const Text(
                'Guards async uncaught errors even when the app skips UyavaBootstrap.runZoned.',
              ),
            ),
            SwitchListTile(
              value: emitNonFatalDiagnostics,
              onChanged: isUpdating ? null : onToggleNonFatalDiagnostics,
              title: const Text('Emit diagnostics for non-fatal errors'),
              subtitle: const Text(
                'When off, runtimeError entries remain but diagnostics stay quiet.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: allowIsolateActions ? onSpawnIsolateCrash : null,
                  icon: const Icon(Icons.memory),
                  label: const Text('Spawn isolate crash'),
                ),
                OutlinedButton.icon(
                  onPressed: onAsyncOutsideGuard,
                  icon: const Icon(Icons.sync_problem_outlined),
                  label: const Text('Async throw (no guard)'),
                ),
                OutlinedButton.icon(
                  onPressed: onPresentErrorOverride,
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('Override onError + presentError'),
                ),
                OutlinedButton.icon(
                  onPressed: onEmitNonFatal,
                  icon: const Icon(Icons.report_gmailerrorred_outlined),
                  label: const Text('Non-fatal FlutterError'),
                ),
              ],
            ),
            if (lastPanicDiagnostic != null) ...[
              const SizedBox(height: 16),
              Text(
                'Last panic-tail diagnostic',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              _PanicTailPreview(data: lastPanicDiagnostic!, scheme: scheme),
            ],
          ],
        ),
      ),
    );
  }
}

class _PanicTailPreview extends StatelessWidget {
  const _PanicTailPreview({required this.data, required this.scheme});

  final Map<String, dynamic> data;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final Map<String, Object?> contextMap = Map<String, Object?>.from(
      data['context'] as Map? ?? <String, Object?>{},
    );
    final bool fatal = contextMap['fatal'] == true;
    final String? message = contextMap['message'] as String?;
    final Map<String, Object?>? panicTail = (contextMap['panicTail'] as Map?)
        ?.cast<String, Object?>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fatal ? 'Fatal path' : 'Non-fatal capture',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (panicTail != null && panicTail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Panic tail: available=${panicTail['available']} '
              'payloadBytes=${panicTail['payloadBytes'] ?? '-'} '
              'mirror=${panicTail['panicMirrorBytes'] ?? '-'}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
