# Uyava UI

`uyava_ui` contains shared Flutter UI building blocks used by Uyava hosts
(DevTools extension and desktop app): graph rendering helpers, panel widgets,
filters UI, metrics dashboard, event chains UI, and journal components.

It is a presentation package on top of `uyava_core` + `uyava_protocol`.

## What is in this package

- Rendering/config primitives:
  - `RenderConfig`, `LayoutSizingController`
  - geometry/adapters/grouping helpers
  - policies (`EdgeAggregationPolicy`, `CloudVisibilityPolicy`)
- Host coordination:
  - `GraphHostController`
  - `GraphViewCoordinator`
  - `GraphViewState`
- Reusable panels/widgets:
  - `UyavaFiltersPanel`
  - `UyavaMetricsDashboard`
  - `UyavaEventChainsPanel`
  - `UyavaGraphJournalPanel`
  - `PanelShellView` + split/persistence helpers

## Minimal integration example

```dart
import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

class UyavaUiDemo extends StatefulWidget {
  const UyavaUiDemo({super.key});

  @override
  State<UyavaUiDemo> createState() => _UyavaUiDemoState();
}

class _UyavaUiDemoState extends State<UyavaUiDemo> {
  late final GraphViewCoordinator coordinator = GraphViewCoordinator(
    renderConfig: const RenderConfig(),
    layoutConfig: const LayoutConfig(),
  );

  @override
  void initState() {
    super.initState();
    coordinator.graphController.replaceGraph({
      'nodes': const [
        {'id': 'auth.service', 'type': 'service'},
        {'id': 'auth.repo', 'type': 'repository'},
      ],
      'edges': const [
        {'id': 'auth.service->auth.repo', 'source': 'auth.service', 'target': 'auth.repo'},
      ],
    }, const Size2D(900, 600));
  }

  @override
  void dispose() {
    coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UyavaFiltersPanel(controller: coordinator.graphController),
        Expanded(
          child: UyavaMetricsDashboard(controller: coordinator.graphController),
        ),
      ],
    );
  }
}
```

## Notes

- This package is Flutter-only and depends on `uyava_core` + `uyava_protocol`.
- It provides reusable host-facing UI blocks, not a standalone app.
- `publish_to: none` means the package is currently workspace-internal.

## Related docs

- Getting started: https://uyava.io/docs/getting-started
- Graph concepts: https://uyava.io/docs/concepts-graph
- Metrics dashboard: https://uyava.io/docs/metrics-dashboard
- Session/replay docs: https://uyava.io/docs/session-file-format
- Repository: https://github.com/alex-marochko/uyava

## License

MIT — see `LICENSE`.
