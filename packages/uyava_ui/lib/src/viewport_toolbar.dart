import 'package:flutter/material.dart';

import 'config.dart';
import 'graph_painter.dart';
import 'viewport.dart';

/// Shared toolbar for viewport controls and interaction mode toggles.
class GraphViewportToolbar extends StatelessWidget {
  const GraphViewportToolbar({
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
    final bool hasVisibleNodes = displayNodes.isNotEmpty;
    final Color surface = Theme.of(context).colorScheme.surface;
    return Card(
      elevation: 4,
      color: surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isPanModeEnabled
                  ? 'Disable drag-to-pan mode'
                  : 'Enable drag-to-pan mode',
              icon: Icon(
                isPanModeEnabled ? Icons.pan_tool : Icons.pan_tool_alt,
              ),
              color: isPanModeEnabled
                  ? Theme.of(context).colorScheme.primary
                  : null,
              onPressed: () => onPanModeChanged(!isPanModeEnabled),
            ),
            IconButton(
              tooltip: 'Re-run layout',
              icon: const Icon(Icons.restart_alt),
              onPressed: onReloadLayout,
            ),
            IconButton(
              tooltip: 'Zoom out',
              icon: const Icon(Icons.remove),
              onPressed: () {
                onManualViewportChange();
                viewportController.zoomBy(
                  1.0 / renderConfig.viewportZoomStep,
                  viewportSize,
                );
              },
            ),
            IconButton(
              tooltip: 'Reset view',
              icon: const Icon(Icons.center_focus_strong),
              onPressed: () {
                onManualViewportChange();
                final Rect? bounds = computeDisplayNodeBounds(
                  displayNodes,
                  renderConfig,
                  parentIds: parentIds,
                  padding: 0,
                );
                if (bounds != null) {
                  viewportController.centerOnPoint(
                    bounds.center,
                    viewportSize,
                    scale: renderConfig.defaultViewportScale,
                  );
                } else {
                  viewportController.reset(viewportSize);
                }
              },
            ),
            IconButton(
              tooltip: 'Fit visible nodes',
              icon: const Icon(Icons.fit_screen),
              onPressed: hasVisibleNodes
                  ? () {
                      onManualViewportChange();
                      onFitVisibleNodes();
                    }
                  : null,
            ),
            IconButton(
              tooltip: 'Zoom in',
              icon: const Icon(Icons.add),
              onPressed: () {
                onManualViewportChange();
                viewportController.zoomBy(
                  renderConfig.viewportZoomStep,
                  viewportSize,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
