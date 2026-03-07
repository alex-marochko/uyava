---
layout: ../../layouts/DocsLayout.astro
title: "LLM Integration Spec (Agents)"
description: "Machine-oriented specification for AI coding agents integrating Uyava into Flutter apps."
---

# LLM Integration Spec (Agents)

Use this page as the single context link for AI coding agents (Cursor, Copilot, Claude, etc.) when they need to instrument Flutter code with Uyava.

Goal: prevent hallucinated APIs and enforce consistent Uyava integration patterns.

## Dependency setup (required)

Install SDK:

```bash
flutter pub add uyava
```

Optional (if file logging is required):

```bash
flutter pub add path_provider
```

If the task is to generate replay files directly (without SDK calls), use:

- [Session File Format (.uyava)](/docs/session-file-format)

## What Uyava is (for agents)

- Uyava is a structured runtime instrumentation SDK for Flutter.
- It models architecture as a graph (nodes + directed edges), then overlays runtime events.
- It is not a plain text logger. Do not replace Uyava calls with `print()` or `debugPrint()` when instrumentation is requested.

## Host connection check (required for verification)

After instrumentation, verify that data appears in at least one host:

1. DevTools host:
- run app in debug/profile
- open Flutter DevTools
- select Uyava extension tab

2. Desktop host:
- open Uyava Desktop
- attach VM Service URI from running app
- confirm graph/events are visible

## Canonical integration flow

### 1) Initialize once

```dart
import 'package:flutter/widgets.dart';
import 'package:uyava/uyava.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Uyava.initialize();
  runApp(const MyApp());
}
```

### 2) Publish a stable graph snapshot

```dart
Uyava.replaceGraph(
  nodes: const [
    UyavaNode(id: 'ui.login', type: 'screen', label: 'Login', tags: ['ui']),
    UyavaNode(id: 'logic.auth', type: 'service', label: 'Auth', tags: ['auth']),
  ],
  edges: const [
    UyavaEdge(id: 'ui.login->logic.auth', from: 'ui.login', to: 'logic.auth'),
  ],
);
```

### 3) Emit runtime events (message is required)

```dart
Uyava.emitNodeEvent(
  nodeId: 'logic.auth',
  message: 'Sign in pressed',
  severity: UyavaSeverity.info,
);

Uyava.emitEdgeEvent(
  edge: 'ui.login->logic.auth',
  message: 'Auth request dispatched',
  severity: UyavaSeverity.info,
);
```

`message` must be non-empty (empty/whitespace throws).

### 4) Prefer source references for IDE navigation

```dart
Uyava.emitNodeEvent(
  nodeId: 'logic.auth',
  message: 'Auth started',
  sourceRef: Uyava.caller(),
);
```

### 5) Optional: metrics and event chains

```dart
Uyava.defineMetric(
  id: 'auth.latency_ms',
  label: 'Auth latency',
  unit: 'ms',
  tags: ['auth', 'latency'],
  aggregators: [
    UyavaMetricAggregator.last,
    UyavaMetricAggregator.min,
    UyavaMetricAggregator.max,
    UyavaMetricAggregator.sum,
    UyavaMetricAggregator.count,
  ],
);

Uyava.defineEventChain(
  id: 'auth.login_flow',
  tags: ['auth'],
  steps: const [
    UyavaEventChainStep(stepId: 'open', nodeId: 'ui.login'),
    UyavaEventChainStep(stepId: 'submit', nodeId: 'logic.auth'),
    UyavaEventChainStep(stepId: 'success', nodeId: 'logic.auth'),
  ],
);
```

`defineEventChain` must include at least one tag and valid steps; invalid definitions fail sanitization.

Supported metric aggregators: `last`, `min`, `max`, `sum`, `count`.

## API quick reference (use exact names)

- `Uyava.initialize()`
- `Uyava.replaceGraph({List<UyavaNode>? nodes, List<UyavaEdge>? edges})`
- `Uyava.addNode(UyavaNode node, {String? sourceRef})`
- `Uyava.addEdge(UyavaEdge edge)`
- `Uyava.patchNode(String nodeId, Map<String, Object?> changes)`
- `Uyava.patchEdge(String edgeId, Map<String, Object?> changes)`
- `Uyava.removeNode(String nodeId)`
- `Uyava.removeEdge(String edgeId)`
- `Uyava.emitNodeEvent({required String nodeId, required String message, ...})`
- `Uyava.emitEdgeEvent({required String edge, required String message, ...})`
- `Uyava.updateNodeLifecycle({required String nodeId, required UyavaLifecycleState state})`
- `Uyava.updateNodesListLifecycle({required List<String> nodeIds, required UyavaLifecycleState state})`
- `Uyava.defineMetric(...)`
- `Uyava.defineEventChain(...)`
- `Uyava.enableFileLogging(...)` / `Uyava.exportCurrentArchive()` / `Uyava.cloneActiveArchive()`
- `Uyava.enableConsoleLogging(...)` / `Uyava.disableConsoleLogging()`
- `Uyava.caller()` for source references

## Optional bootstrap pattern for global error capture

Use when you also enable file logging and want global uncaught error capture:

```dart
final transport = await Uyava.enableFileLogging(
  config: UyavaFileLoggerConfig(directoryPath: '/tmp/uyava'),
);

await UyavaBootstrap.runZoned(
  () async {
    WidgetsFlutterBinding.ensureInitialized();
    Uyava.initialize();
    runApp(const MyApp());
  },
  transport: transport,
);
```

## Guardrails (must follow)

1. Keep node/edge IDs unique and stable.
2. Do not generate ephemeral IDs from request payloads/time for structural nodes.
3. Keep graph structure mostly static; represent runtime variability with events, lifecycle, metrics.
4. Colors must be `#RRGGBB` or `#AARRGGBB`.
5. Shapes must match `^[a-z0-9_-]+$`.
6. Always provide non-empty `message` for `emitNodeEvent` and `emitEdgeEvent`.
7. Use existing edge IDs in `emitEdgeEvent(edge: ...)` when possible.
8. Prefer `sourceRef: Uyava.caller()` for node/event emissions in domain code paths.
9. Do not substitute Uyava instrumentation with plain console logging.
10. If API details are uncertain, do not invent signatures; keep to documented calls on this page.

## End-to-end implementation recipe for agents

When user asks "instrument feature X with Uyava", do this in order:

1. Ensure dependency exists (`uyava` in project).
2. Ensure single startup initialization (`Uyava.initialize()`).
3. Define/refresh stable structural nodes and edges for that feature.
4. Instrument runtime actions with `emitNodeEvent`/`emitEdgeEvent` (non-empty messages).
5. Add lifecycle updates where components activate/deactivate.
6. Optionally add metric definitions + metric samples in event payloads.
7. Optionally add event chains for multi-step flows.
8. Add `sourceRef: Uyava.caller()` where code navigation matters.
9. Verify data in DevTools/Desktop host.
10. Report exactly what was instrumented and where.

## Anti-patterns (do not generate)

- `print('...')` instead of `Uyava.emitNodeEvent(...)` when asked to add Uyava instrumentation.
- Missing `message` in event emission.
- Dynamic node IDs like `screen_${DateTime.now()}` for static architecture components.
- Rebuilding full graph on every user action when only events are needed.
- Generating a single synthetic global root node and attaching the whole graph under it.

## Agent completion checklist

Before returning code, verify:

1. `Uyava.initialize()` is called once at startup.
2. Graph IDs are stable and unique.
3. Every event emission includes a meaningful non-empty message.
4. New metrics/chains use stable IDs and valid tags.
5. No invented Uyava APIs were introduced.
