import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

const DiagnosticDocRepository diagnosticDocRepository =
    DiagnosticDocRepository._();

/// Displays an inline dialog containing documentation for [record].
Future<void> showDiagnosticDocsDialog({
  required BuildContext context,
  required GraphDiagnosticRecord record,
  DiagnosticDocRepository repository = diagnosticDocRepository,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _DiagnosticDocsDialog(
      record: record,
      entry: repository.lookup(record.codeEnum),
    ),
  );
}

/// Reference data for built-in diagnostic codes.
class DiagnosticDocRepository {
  const DiagnosticDocRepository._();

  DiagnosticDocEntry? lookup(UyavaGraphIntegrityCode? code) {
    if (code == null) return null;
    return _entries[code];
  }

  Iterable<DiagnosticDocEntry> get entries => _entries.values;
}

/// Content rendered for a single diagnostic entry.
class DiagnosticDocEntry {
  const DiagnosticDocEntry({
    required this.code,
    required this.headline,
    required this.summary,
    required this.whenItFires,
    required this.howToFix,
  });

  final UyavaGraphIntegrityCode code;
  final String headline;
  final String summary;
  final List<String> whenItFires;
  final List<String> howToFix;
}

class _DiagnosticDocsDialog extends StatelessWidget {
  const _DiagnosticDocsDialog({required this.record, required this.entry});

  final GraphDiagnosticRecord record;
  final DiagnosticDocEntry? entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme scheme = theme.colorScheme;
    final Size size = MediaQuery.of(context).size;
    final double width = math.min(size.width * 0.9, 720);
    final double height = math.min(size.height * 0.85, 720);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: math.max(height, 360),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogHeader(record: record),
              const SizedBox(height: 8),
              Text(
                record.code,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SubjectsSection(record: record),
                      const SizedBox(height: 12),
                      _ContextSection(record: record),
                      if (entry != null) ...[
                        const SizedBox(height: 16),
                        _DocEntrySection(entry: entry!),
                      ] else ...[
                        const SizedBox(height: 16),
                        _FallbackDocSection(record: record),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.record});

  final GraphDiagnosticRecord record;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme scheme = theme.colorScheme;
    final UyavaGraphIntegrityCode? codeEnum = record.codeEnum;
    final String title = codeEnum?.name ?? record.code;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Severity: ${record.level.name}',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            codeEnum?.category ?? record.code.split('.').first,
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onTertiaryContainer,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubjectsSection extends StatelessWidget {
  const _SubjectsSection({required this.record});

  final GraphDiagnosticRecord record;

  @override
  Widget build(BuildContext context) {
    final List<String> subjects = record.subjects;
    if (subjects.isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subjects', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subjects
              .map(
                (subject) => Chip(
                  label: Text(subject),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: scheme.outlineVariant),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _ContextSection extends StatelessWidget {
  const _ContextSection({required this.record});

  final GraphDiagnosticRecord record;

  @override
  Widget build(BuildContext context) {
    if (record.context == null || record.context!.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String prettyContext = const JsonEncoder.withIndent(
      '  ',
    ).convert(record.context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Context', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: SelectableText(
            prettyContext,
            style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _DocEntrySection extends StatelessWidget {
  const _DocEntrySection({required this.entry});

  final DiagnosticDocEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.headline,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(entry.summary, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        if (entry.whenItFires.isNotEmpty)
          _DocBulletList(title: 'When it fires', items: entry.whenItFires),
        const SizedBox(height: 12),
        if (entry.howToFix.isNotEmpty)
          _DocBulletList(title: 'How to fix it', items: entry.howToFix),
      ],
    );
  }
}

class _DocBulletList extends StatelessWidget {
  const _DocBulletList({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackDocSection extends StatelessWidget {
  const _FallbackDocSection({required this.record});

  final GraphDiagnosticRecord record;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentation in progress',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This diagnostic (${record.code}) was emitted by the app or a newer '
          'Uyava build. Consult docs/diagnostics/README.md in the repo for the '
          'latest reference or check your host project documentation.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

const Map<UyavaGraphIntegrityCode, DiagnosticDocEntry>
_entries = <UyavaGraphIntegrityCode, DiagnosticDocEntry>{
  UyavaGraphIntegrityCode.nodesMissingId: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.nodesMissingId,
    headline: 'Node is missing a stable id',
    summary:
        'A node entry lacked a deterministic `id`, was empty, or was not a map. '
        'The controller drops the node entirely to keep references consistent.',
    whenItFires: <String>[
      'A node map omits `id`, provides an empty string, or the `nodes` array '
          'contains non-map entries.',
    ],
    howToFix: <String>[
      'Ensure every emitted node has a non-empty string id before serializing.',
      'Filter malformed entries out of the payload before calling Uyava.',
    ],
  ),
  UyavaGraphIntegrityCode.nodesDuplicateId: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.nodesDuplicateId,
    headline: 'Duplicate node ids in the same payload',
    summary:
        'Two or more nodes shared the same id; Uyava kept the most recent one.',
    whenItFires: <String>[
      'Multiple node entries with the same `id` appear during hydration.',
    ],
    howToFix: <String>[
      'Deduplicate nodes upstream and only send one entry per logical node.',
      'Avoid reusing ids for different entities across updates.',
    ],
  ),
  UyavaGraphIntegrityCode.nodesInvalidColor: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.nodesInvalidColor,
    headline: 'Node color could not be parsed',
    summary:
        'The provided `color` was not a supported hex/material value, so it was '
        'stripped from the payload.',
    whenItFires: <String>[
      'Colors use unsupported formats, contain typos, or include whitespace.',
    ],
    howToFix: <String>[
      'Normalize colors to `#RRGGBB`/`#AARRGGBB` or known palette tokens.',
      'Leave `color` null and rely on tags when unsure.',
    ],
  ),
  UyavaGraphIntegrityCode.nodesInvalidShape: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.nodesInvalidShape,
    headline: 'Node shape token was rejected',
    summary:
        'Shapes outside the supported set are dropped and nodes render with the '
        'default outline.',
    whenItFires: <String>[
      'The `shape` field is provided but contains an unknown token.',
    ],
    howToFix: <String>[
      'Use documented shape ids such as `rectangle`, `circle`, or `stadium`.',
      'Trim whitespace and validate enums before emission.',
    ],
  ),
  UyavaGraphIntegrityCode.nodesConflictingColor: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.nodesConflictingColor,
    headline: 'Color conflicts for the same node id',
    summary:
        'The same node id was rehydrated with a different color, signaling that '
        'multiple sources disagree on styling.',
    whenItFires: <String>[
      'Distinct payloads reuse an id while providing different `color` values.',
    ],
    howToFix: <String>[
      'Establish a single styling source of truth before sending updates.',
      'Reconcile conflicting colors before publishing the graph.',
    ],
  ),
  UyavaGraphIntegrityCode.nodesConflictingTags: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.nodesConflictingTags,
    headline: 'Tag conflicts for the same node id',
    summary:
        'Uyava detected inconsistent tag sets for a reused node id. Tags drive '
        'filters and dashboards, so conflicts are surfaced.',
    whenItFires: <String>[
      'A later payload sends the same node id with a different `tags` list.',
    ],
    howToFix: <String>[
      'Consolidate tagging logic or compute tags server-side before emitting.',
      'Ensure tag casing/normalization is identical across emitters.',
    ],
  ),
  UyavaGraphIntegrityCode.edgesMissingId: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.edgesMissingId,
    headline: 'Edge is missing its id',
    summary:
        'An edge entry lacked an `id` or the edges array contained invalid '
        'objects, so the edge was dropped.',
    whenItFires: <String>[
      'Edge payload omits `id`, supplies an empty string, or entry is not a map.',
    ],
    howToFix: <String>[
      'Provide unique, non-empty ids for every edge before serialization.',
    ],
  ),
  UyavaGraphIntegrityCode.edgesDuplicateId: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.edgesDuplicateId,
    headline: 'Duplicate edge ids detected',
    summary:
        'The payload contained multiple edges with the same id; only the most '
        'recent is kept.',
    whenItFires: <String>['Hydration data repeats an edge id.'],
    howToFix: <String>[
      'Deduplicate connections upstream and avoid recycling ids for distinct '
          'edges.',
    ],
  ),
  UyavaGraphIntegrityCode.edgesMissingSource: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.edgesMissingSource,
    headline: 'Edge lacks a source node',
    summary:
        'The edge entry does not specify `source`, so it cannot be rendered.',
    whenItFires: <String>['Edge payloads omit or blank out `source`.'],
    howToFix: <String>[
      'Ensure each edge references a valid existing node via the `source` field.',
    ],
  ),
  UyavaGraphIntegrityCode.edgesMissingTarget: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.edgesMissingTarget,
    headline: 'Edge lacks a target node',
    summary:
        'The edge entry does not specify `target` and therefore is discarded.',
    whenItFires: <String>['Edge payloads omit or blank out `target`.'],
    howToFix: <String>[
      'Populate `target` with the downstream node id before sending.',
    ],
  ),
  UyavaGraphIntegrityCode.edgesDanglingSource: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.edgesDanglingSource,
    headline: 'Source node does not exist',
    summary:
        'After sanitizing nodes, the referenced `source` id is missing, so the '
        'edge cannot be attached.',
    whenItFires: <String>[
      'Edges are emitted before their source nodes or keep pointing to deleted '
          'nodes.',
    ],
    howToFix: <String>[
      'Emit nodes before edges and purge edges when nodes are removed.',
      'Keep node ids stable across refreshes.',
    ],
  ),
  UyavaGraphIntegrityCode.edgesDanglingTarget: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.edgesDanglingTarget,
    headline: 'Target node does not exist',
    summary:
        'The edge points to a node id that is not part of the sanitized graph.',
    whenItFires: <String>[
      'Edges reference targets that were never registered or were deleted.',
    ],
    howToFix: <String>[
      'Create target nodes before wiring edges and remove stale edges promptly.',
    ],
  ),
  UyavaGraphIntegrityCode.edgesSelfLoop: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.edgesSelfLoop,
    headline: 'Edge forms a self-loop',
    summary:
        'Source and target ids match, creating a loop the layout engine does '
        'not support.',
    whenItFires: <String>[
      'Edge payloads repeat the same id for `source` and `target`.',
    ],
    howToFix: <String>[
      'Model self-interactions with events/metrics or add an intermediate node.',
    ],
  ),
  UyavaGraphIntegrityCode.metricsMissingId: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.metricsMissingId,
    headline: 'Metric definition missing id',
    summary:
        'A `defineMetric` event did not include an id, so the definition was '
        'rejected.',
    whenItFires: <String>[
      'Metric definition maps omit `id` or include blank strings.',
    ],
    howToFix: <String>[
      'Assign deterministic ids that align with the emitting subsystem.',
    ],
  ),
  UyavaGraphIntegrityCode.metricsConflictingDefinition: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.metricsConflictingDefinition,
    headline: 'Metric aggregators changed',
    summary:
        'The same metric id was re-registered with a different aggregator set; '
        'Uyava reset stored aggregates to stay consistent.',
    whenItFires: <String>[
      'A definition changes its `aggregators` list compared to the previous '
          'registration.',
    ],
    howToFix: <String>[
      'Create a new metric id when changing aggregators, or accept the reset '
          'and backfill values if necessary.',
    ],
  ),
  UyavaGraphIntegrityCode.metricsInvalidAggregator: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.metricsInvalidAggregator,
    headline: 'Metric aggregators invalid',
    summary:
        'Aggregator entries were empty or contained unknown values, so the '
        'definition was normalized with a default and flagged.',
    whenItFires: <String>[
      'Aggregator arrays include typos or non-string values.',
      'A custom list resolves to zero valid aggregators.',
    ],
    howToFix: <String>[
      'Limit aggregators to the `UyavaMetricAggregator` enum.',
      'Provide `[]` to accept the default `last` aggregator instead of invalid '
          'data.',
    ],
  ),
  UyavaGraphIntegrityCode.metricsInvalidValue: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.metricsInvalidValue,
    headline: 'Metric sample value invalid',
    summary:
        'A metric sample lacked a numeric value or provided a timestamp that '
        'could not be parsed.',
    whenItFires: <String>[
      '`value` is null, NaN, or a non-numeric string.',
      'Timestamp strings fail ISO-8601 parsing.',
    ],
    howToFix: <String>[
      'Send doubles for values and ISO-8601 UTC timestamps for `timestamp`.',
      'Drop invalid samples before forwarding them to Uyava.',
    ],
  ),
  UyavaGraphIntegrityCode.metricsUnknownId: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.metricsUnknownId,
    headline: 'Metric sample references unknown id',
    summary:
        'A sample references a metric that has not been defined, so the sample '
        'was ignored.',
    whenItFires: <String>[
      'Samples emit before `defineMetric` succeeds.',
      'Typo in the metric id while submitting samples.',
    ],
    howToFix: <String>[
      'Register metrics during startup and cache samples until registration is '
          'acknowledged.',
      'Reuse generated constants for ids instead of manual strings.',
    ],
  ),
  UyavaGraphIntegrityCode.chainsMissingId: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.chainsMissingId,
    headline: 'Chain definition missing id',
    summary: 'Chain metadata lacked an `id`, so the definition was rejected.',
    whenItFires: <String>[
      'Chain maps omit the `id` field or provide empty values.',
    ],
    howToFix: <String>[
      'Assign descriptive ids before sending, e.g. `checkout.happy_path`.',
    ],
  ),
  UyavaGraphIntegrityCode.chainsMissingTag: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.chainsMissingTag,
    headline: 'Chain definition missing tags',
    summary:
        'Chains require at least one tag for filtering. Definitions without '
        'tags are rejected.',
    whenItFires: <String>[
      'No `tags` list provided and legacy `tag` field empty.',
    ],
    howToFix: <String>[
      'Populate `tags` with at least one normalized value that categorizes the '
          'chain.',
    ],
  ),
  UyavaGraphIntegrityCode.chainsInvalidStep: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.chainsInvalidStep,
    headline: 'Chain steps malformed',
    summary:
        'Step arrays contained non-map entries, missing ids/node ids, or were '
        'empty, so the definition could not be used.',
    whenItFires: <String>[
      'A step entry is missing `stepId` or `nodeId`.',
      'The `steps` list is empty or not iterable.',
    ],
    howToFix: <String>[
      'Validate steps before emission and ensure each includes `stepId` and '
          '`nodeId`.',
    ],
  ),
  UyavaGraphIntegrityCode.chainsConflictingStep: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.chainsConflictingStep,
    headline: 'Duplicate step ids inside a chain',
    summary:
        'Two steps share the same `stepId`, which makes runtime tracking '
        'ambiguous.',
    whenItFires: <String>[
      'A step id appears more than once in the definition.',
    ],
    howToFix: <String>[
      'Give every step a unique identifier, even if labels repeat.',
    ],
  ),
  UyavaGraphIntegrityCode.chainsConflictingDefinition: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.chainsConflictingDefinition,
    headline: 'Chain redefined with different steps',
    summary:
        'The same chain id was re-registered with a structurally different set '
        'of steps. Runtime stats were reset.',
    whenItFires: <String>[
      'Steps were reordered or changed without changing the chain id.',
    ],
    howToFix: <String>[
      'Version breaking changes under a new id when historical stats matter.',
    ],
  ),
  UyavaGraphIntegrityCode.chainsUnknownId: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.chainsUnknownId,
    headline: 'Runtime chain event references unknown id',
    summary: 'An event attempted to update a chain that is not registered yet.',
    whenItFires: <String>[
      'Instrumentation emits progress before sending the definition.',
      'Typo in chain id while logging events.',
    ],
    howToFix: <String>[
      'Register all chains during startup.',
      'Use shared constants for chain ids to avoid typos.',
    ],
  ),
  UyavaGraphIntegrityCode.chainsUnknownStep: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.chainsUnknownStep,
    headline: 'Runtime event references unknown step',
    summary:
        'A progress event referenced a step that does not exist in the '
        'definition or used the wrong node/edge for that step.',
    whenItFires: <String>[
      'Step ids in instrumentation drift from the definition.',
      'Events use the right step id but wrong nodeId/edgeId pair.',
    ],
    howToFix: <String>[
      'Keep code-generated definitions in sync with instrumentation.',
      'Verify node/edge bindings for each step before emitting events.',
    ],
  ),
  UyavaGraphIntegrityCode.chainsInvalidStepOrder: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.chainsInvalidStepOrder,
    headline: 'Event order violated the definition',
    summary:
        'Steps arrived out of sequence for the active attempt, causing the '
        'attempt to fail.',
    whenItFires: <String>[
      'Sequential attempts receive a later step before the expected one.',
      'Named attempts emit duplicate or skipped steps.',
    ],
    howToFix: <String>[
      'Buffer/sequence events before forwarding them to Uyava.',
      'Ensure attempt ids are unique per concurrent execution.',
    ],
  ),
  UyavaGraphIntegrityCode.filtersInvalidPattern: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.filtersInvalidPattern,
    headline: 'Filter regex failed to compile',
    summary:
        'A regex pattern or flag set could not be parsed, so the search filter '
        'was discarded.',
    whenItFires: <String>[
      'User-entered regex has syntax errors.',
      'Unsupported flags were provided with the pattern.',
    ],
    howToFix: <String>[
      'Validate regex client-side and fall back to substring mode when invalid.',
      'Restrict flags to the supported subset (`i`, `m`, `s`, `u`).',
    ],
  ),
  UyavaGraphIntegrityCode.filtersUnknownNode: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.filtersUnknownNode,
    headline: 'Filter references unknown node ids',
    summary:
        'An include/exclude set pointed at nodes that are not present in the '
        'current graph. Filters still apply to known ids.',
    whenItFires: <String>[
      'Saved filters reference nodes that were renamed or deleted.',
    ],
    howToFix: <String>[
      'Refresh saved filters after structural changes.',
      'Drive selectors from live data so users cannot pick missing ids.',
    ],
  ),
  UyavaGraphIntegrityCode.filtersUnknownEdge: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.filtersUnknownEdge,
    headline: 'Filter references unknown edge ids',
    summary:
        'Edge include/exclude sets contained ids that are not part of the '
        'current graph.',
    whenItFires: <String>[
      'Saved filters still reference edges removed upstream.',
    ],
    howToFix: <String>[
      'Synchronize stored filters with the deployed edge ids and drop stale '
          'entries.',
    ],
  ),
  UyavaGraphIntegrityCode.filtersInvalidMode: DiagnosticDocEntry(
    code: UyavaGraphIntegrityCode.filtersInvalidMode,
    headline: 'Filter mode/logic invalid',
    summary:
        'A filter section specified an unsupported mode, logic operator, '
        'severity operator, or flag type.',
    whenItFires: <String>[
      'Payload enums do not map to known `UyavaFilter*` codecs.',
      'Boolean fields such as `caseSensitive` receive non-boolean data.',
    ],
    howToFix: <String>[
      'Clamp payloads to the enums exposed by the SDK.',
      'Sanitize user input before forwarding it to Uyava.',
    ],
  ),
};
