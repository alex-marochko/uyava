import 'package:flutter/foundation.dart';
import 'package:uyava_core/uyava_core.dart';

/// Identifies which element of the graph a journal link should target.
enum GraphJournalLinkKind { node, edge, subject }

/// Base class describing a journal link to a graph element.
@immutable
sealed class GraphJournalLinkTarget {
  const GraphJournalLinkTarget({required this.kind});

  final GraphJournalLinkKind kind;
}

/// Represents a journal link pointing to a concrete node.
class GraphJournalNodeLink extends GraphJournalLinkTarget {
  const GraphJournalNodeLink({required this.nodeId, this.event})
    : super(kind: GraphJournalLinkKind.node);

  final String nodeId;
  final UyavaNodeEvent? event;
}

/// Represents a journal link pointing to a directed edge.
class GraphJournalEdgeLink extends GraphJournalLinkTarget {
  const GraphJournalEdgeLink({required this.from, required this.to, this.event})
    : super(kind: GraphJournalLinkKind.edge);

  final String from;
  final String to;
  final UyavaEvent? event;
}

/// Represents a journal link derived from diagnostics subjects.
class GraphJournalSubjectLink extends GraphJournalLinkTarget {
  const GraphJournalSubjectLink({required this.subjectId})
    : super(kind: GraphJournalLinkKind.subject);

  final String subjectId;
}
