import 'package:uyava_core/uyava_core.dart';

import 'journal_controller.dart';

/// Convenience adapter that wires common host-side plumbing into the shared
/// [GraphJournalController].
///
/// Hosts forward node/edge events through the adapter, while diagnostics are
/// synchronized automatically via the supplied [GraphController].
class GraphJournalHostAdapter {
  GraphJournalHostAdapter({
    required GraphController graphController,
    int maxEntriesSoftLimit = 20000,
  }) : _graphController = graphController,
       controller = GraphJournalController(
         graphController: graphController,
         maxEntriesSoftLimit: maxEntriesSoftLimit,
       );

  final GraphController _graphController;

  /// Backing journal controller consumed by the shared panel.
  final GraphJournalController controller;

  /// Shorthand to record a node event.
  void recordNodeEvent(UyavaNodeEvent event) {
    controller.addNodeEvent(event);
  }

  /// Shorthand to record an edge event.
  void recordEdgeEvent(UyavaEvent event) {
    controller.addEdgeEvent(event);
  }

  /// Clears the entire journal (events + diagnostics).
  void clearLog() {
    controller.clearLog();
  }

  /// Records a structured journal action diagnostic for observability.
  void logAction({
    required String action,
    Map<String, Object?>? context,
    UyavaDiagnosticLevel level = UyavaDiagnosticLevel.info,
  }) {
    _graphController.addAppDiagnostic(
      code: 'journal.$action',
      level: level,
      subjects: const <String>['journal'],
      context: <String, Object?>{
        'action': action,
        if (context != null) ...context,
      },
    );
  }

  void dispose() {
    controller.dispose();
  }
}
