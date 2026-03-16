part of 'journal_view_model.dart';

GraphJournalEventDetailCache buildJournalEventDetailCache(
  GraphJournalEventEntry entry,
) {
  final String timestamp = formatJournalTimestamp(entry.timestamp.toLocal());
  final String subject = switch (entry.kind) {
    GraphJournalEventKind.node => 'node:${entry.nodeEvent!.nodeId}',
    GraphJournalEventKind.edge =>
      'edge:${entry.edgeEvent!.from}->${entry.edgeEvent!.to}',
  };
  final GraphJournalLinkTarget? target = switch (entry.kind) {
    GraphJournalEventKind.node =>
      entry.nodeEvent == null
          ? null
          : GraphJournalNodeLink(
              nodeId: entry.nodeEvent!.nodeId,
              event: entry.nodeEvent!,
            ),
    GraphJournalEventKind.edge =>
      entry.edgeEvent == null
          ? null
          : GraphJournalEdgeLink(
              from: entry.edgeEvent!.from,
              to: entry.edgeEvent!.to,
              event: entry.edgeEvent!,
            ),
  };
  final String? relative = formatRelativeDuration(entry.deltaSincePrevious);
  final String? isolate = switch (entry.kind) {
    GraphJournalEventKind.node => formatIsolateLabel(
      isolateName: entry.nodeEvent?.isolateName,
      isolateNumber: entry.nodeEvent?.isolateNumber,
      isolateId: entry.nodeEvent?.isolateId,
    ),
    GraphJournalEventKind.edge => formatIsolateLabel(
      isolateName: entry.edgeEvent?.isolateName,
      isolateNumber: entry.edgeEvent?.isolateNumber,
      isolateId: entry.edgeEvent?.isolateId,
    ),
  };
  final String? sourceRef = switch (entry.kind) {
    GraphJournalEventKind.node => entry.nodeEvent?.sourceRef,
    GraphJournalEventKind.edge => entry.edgeEvent?.sourceRef,
  };

  return GraphJournalEventDetailCache(
    timestampLabel: timestamp,
    subjectLabel: subject,
    focusTarget: target,
    severity: entry.severity,
    severityLabel: entry.severity?.name.toUpperCase(),
    relativeLabel: relative,
    isolateLabel: isolate,
    sourceRef: sourceRef?.isNotEmpty == true ? sourceRef : null,
    message: entry.message,
    jsonPayload: formatEventEntryForClipboard(entry),
  );
}

class GraphJournalEventDetailCache {
  GraphJournalEventDetailCache({
    required this.timestampLabel,
    required this.subjectLabel,
    required this.focusTarget,
    required this.severity,
    this.severityLabel,
    this.relativeLabel,
    this.isolateLabel,
    this.sourceRef,
    required this.message,
    required this.jsonPayload,
  });

  final String timestampLabel;
  final String subjectLabel;
  final GraphJournalLinkTarget? focusTarget;
  final UyavaSeverity? severity;
  final String? severityLabel;
  final String? relativeLabel;
  final String? isolateLabel;
  final String? sourceRef;
  final String message;
  final String jsonPayload;
}
