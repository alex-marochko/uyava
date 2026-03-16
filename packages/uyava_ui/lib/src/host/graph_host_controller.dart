import 'package:flutter/widgets.dart';
import 'package:uyava_core/uyava_core.dart';
import '../config.dart';
import '../focus_controller.dart';
import '../journal/journal_host_adapter.dart';
import '../journal/journal_tabs.dart';
import '../layout_sizer.dart';
import '../viewport.dart';

/// Lightweight wrapper around [GraphController] plus shared host adapters.
class GraphHostController {
  GraphHostController({
    required this.renderConfig,
    required LayoutConfig layoutConfig,
    GraphController? graphController,
    LayoutSizingController? sizingController,
    GraphFocusController? focusController,
    GraphJournalHostAdapter? journalAdapter,
    GraphJournalDisplayController? journalDisplayController,
    GraphMetricsService? metricsService,
  }) : layoutSizing =
           sizingController ??
           LayoutSizingController(renderConfig: renderConfig) {
    this.graphController =
        graphController ??
        GraphController(
          layoutConfig: layoutConfig,
          diagnostics: GraphDiagnosticsBuffer(maxRecords: diagnosticsSoftLimit),
          metricsService: metricsService,
        );
    this.focusController = focusController ?? GraphFocusController();
    this.journalAdapter =
        journalAdapter ??
        GraphJournalHostAdapter(graphController: this.graphController);
    this.journalDisplayController =
        journalDisplayController ?? GraphJournalDisplayController();
  }

  final RenderConfig renderConfig;
  final LayoutSizingController layoutSizing;
  late final GraphController graphController;
  late final GraphFocusController focusController;
  late final GraphJournalHostAdapter journalAdapter;
  late final GraphJournalDisplayController journalDisplayController;
  static const int diagnosticsSoftLimit = 500;

  void dispose() {
    graphController.dispose();
    journalAdapter.dispose();
    focusController.dispose();
    journalDisplayController.dispose();
  }

  GraphViewportController createViewportController({
    required TransformationController transformationController,
    required ValueChanged<GraphViewportState> onStateChanged,
  }) {
    return GraphViewportController(
      renderConfig: renderConfig,
      transformationController: transformationController,
      onStateChanged: onStateChanged,
    );
  }
}
