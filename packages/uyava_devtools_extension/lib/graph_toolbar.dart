import 'package:flutter/material.dart';
import 'package:uyava_ui/uyava_ui.dart';

class DevToolsGraphToolbar extends StatelessWidget {
  const DevToolsGraphToolbar({
    super.key,
    required this.viewportController,
    required this.renderConfig,
    required this.viewportSize,
    required this.displayNodes,
    required this.parentIds,
    required this.onManualViewportChange,
    required this.onFitVisibleNodes,
    required this.isPanModeEnabled,
    required this.onPanModeChanged,
    this.onReloadLayout,
  });

  final GraphViewportController viewportController;
  final RenderConfig renderConfig;
  final Size viewportSize;
  final List<DisplayNode> displayNodes;
  final Set<String> parentIds;
  final VoidCallback onManualViewportChange;
  final VoidCallback onFitVisibleNodes;
  final bool isPanModeEnabled;
  final ValueChanged<bool> onPanModeChanged;
  final VoidCallback? onReloadLayout;

  @override
  Widget build(BuildContext context) {
    return GraphViewportToolbar(
      viewportController: viewportController,
      renderConfig: renderConfig,
      viewportSize: viewportSize,
      displayNodes: displayNodes,
      parentIds: parentIds,
      onManualViewportChange: onManualViewportChange,
      onFitVisibleNodes: onFitVisibleNodes,
      isPanModeEnabled: isPanModeEnabled,
      onPanModeChanged: onPanModeChanged,
      onReloadLayout: onReloadLayout,
    );
  }
}
