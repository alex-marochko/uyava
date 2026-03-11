<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

![CI](https://github.com/alex-marochko/uyava/actions/workflows/packages_ci.yml/badge.svg)

Uyava Core provides the graph models, controller, math types, and pluggable layout engines used by the Uyava DevTools extension and SDKs. It is UI-agnostic and has no Flutter dependencies.

## Features

- UI-free graph models (`UyavaNode`, `UyavaEdge`, `UyavaEvent`).
- `GraphController` that orchestrates layout and exposes positions.
- Pluggable `LayoutEngine` abstraction with a default `ForceDirectedLayout`.
- Example alternative layout: `GridLayout` (static grid) to demonstrate interchangeability.
- Lightweight math types (`Vector2`, `Size2D`), no `dart:ui` in core.

## Getting started

Add `uyava_core` as a dependency and import `package:uyava_core/uyava_core.dart`.
Core is a pure Dart package (no Flutter dependency). Flutter UIs should adapt between `Size`/`Offset` and `Size2D`/`Vector2` at the boundary.

## Usage

The default `GraphController` uses `ForceDirectedLayout`. You can inject any `LayoutEngine`, e.g., the included `GridLayout`:

```dart
import 'package:uyava_core/uyava_core.dart';

void main() {
  final controller = GraphController(
    // Swap in any custom LayoutEngine here
    engine: GridLayout(padding: 32, minCellSize: 72),
  );

  final graph = {
    'nodes': [
      {'id': 'a', 'label': 'A'},
      {'id': 'b', 'label': 'B'},
      {'id': 'c', 'label': 'C'},
    ],
    'edges': [
      {'id': 'e1', 'source': 'a', 'target': 'b'},
      {'id': 'e2', 'source': 'b', 'target': 'c'},
    ],
  };

  controller.replaceGraph(graph, const Size2D(800, 600));
  // For force-directed, you would call controller.step() until converged.
  // GridLayout is static and converged immediately.
  print(controller.positions); // {a: Vector2(...), b: Vector2(...), c: Vector2(...)}
}
```

## Additional information

Layering & dependency rules:

- Core has no Flutter or UI dependencies. It exposes pure Dart types and APIs.
- UIs (e.g., the DevTools extension) adapt platform types to core types:
  - `Size` ↔ `Size2D`
  - `Offset` ↔ `Vector2`
- `GraphController` depends only on `LayoutEngine`. Swap engines to change layout behavior without touching UI code.

If you create your own layout, implement `LayoutEngine`, ship it from a separate package or your app, and inject it into `GraphController(engine: YourLayout())`.

## License
MIT — see `LICENSE` in this package for details.
