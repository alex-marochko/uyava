---
layout: ../../layouts/DocsLayout.astro
title: "SDK Integration"
description: "Technical reference for Uyava SDK APIs, console mirroring, and transports."
---

# SDK Integration (Reference)

This page is a technical reference for the `uyava` SDK APIs and behavior.

If you are onboarding, start with [Getting Started](/docs/getting-started) first, then use this page for exact API choices.

## Startup and graph APIs

Initialize once:

```dart
Uyava.initialize();
```

Graph snapshot and updates:

```dart
Uyava.replaceGraph(nodes: [...], edges: [...]);
Uyava.loadGraph(nodes: [...], edges: [...]);

Uyava.addNode(const UyavaNode(id: 'logic.auth', type: 'service'));
Uyava.addEdge(const UyavaEdge(id: 'ui->logic', from: 'ui', to: 'logic'));

Uyava.patchNode('logic.auth', {'label': 'Auth Service'});
Uyava.patchEdge('ui->logic', {'label': 'Auth request'});

Uyava.removeEdge('ui->logic');
Uyava.removeNode('logic.auth');
```

Reference rule: keep node/edge IDs stable and unique.

## Runtime event APIs

Node and edge events:

```dart
Uyava.emitNodeEvent(
  nodeId: 'logic.auth',
  message: 'Sign in pressed',
  severity: UyavaSeverity.info,
  tags: ['auth'],
  sourceRef: Uyava.caller(),
);

Uyava.emitEdgeEvent(
  edge: 'ui.login->logic.auth',
  message: 'Auth request sent',
  severity: UyavaSeverity.warn,
  sourceRef: Uyava.caller(),
);
```

Lifecycle signals:

```dart
Uyava.updateNodeLifecycle(
  nodeId: 'logic.auth',
  state: UyavaLifecycleState.initialized,
);

Uyava.updateNodesListLifecycle(
  nodeIds: ['logic.auth', 'data.session'],
  state: UyavaLifecycleState.disposed,
);

Uyava.updateSubtreeLifecycle(
  rootNodeId: 'feature.checkout',
  state: UyavaLifecycleState.disposed,
  includeRoot: true,
);
```

Important:

- `message` is required for `emitNodeEvent` and `emitEdgeEvent`.
- `sourceRef: Uyava.caller()` enables Desktop IDE jump-to-code behavior.

## Diagnostics APIs

Emit and clear diagnostics:

```dart
Uyava.postDiagnostic(
  code: 'auth.token_expired',
  level: UyavaDiagnosticLevel.warn,
  nodeId: 'logic.auth',
  context: {'tokenAgeMinutes': 87},
);

Uyava.clearDiagnostics();
```

Use diagnostics for integrity or domain issues that should be visible in the Diagnostics panel.

## Console mirroring

Enable console mirror output when you want standard terminal logs in parallel with Uyava hosts:

```dart
Uyava.enableConsoleLogging(
  config: UyavaConsoleLoggerConfig(
    minLevel: UyavaSeverity.info,
    includeTypes: {'nodeEvent', 'edgeEvent'},
    excludeTypes: {'graphDiagnostics'},
  ),
);
```

Disable when no longer needed:

```dart
await Uyava.disableConsoleLogging();
```

Notes:

- Console mirroring does not replace DevTools/Desktop visualization.
- `includeTypes` and `excludeTypes` are useful for noisy sessions.
- Keep it optional in production unless your support flow depends on it.

## Transport APIs

Uyava emits through a transport hub:

- default transport: VM Service (used by DevTools/Desktop)
- optional: file logging transport
- optional: custom transports (for internal pipelines)

```dart
Uyava.registerTransport(MyWebSocketTransport(uri: Uri.parse('ws://...')));
Uyava.unregisterTransport(const UyavaTransportChannel('my.websocket'));
```

For file transport usage and replay logs, see [Recording and .uyava Logs](/docs/recording-logs).

## Integrity rules and constraints

- Node and edge IDs must be unique.
- Colors must be `#RRGGBB` or `#AARRGGBB`.
- Shapes must match `^[a-z0-9_-]+$`.
- Unknown/dangling references are surfaced as diagnostics.
- Prefer structural stability (graph) + runtime variability (events, lifecycle, metrics, chains).

## Related references

- [Getting Started](/docs/getting-started)
- [Best Practices](/docs/best-practices)
- [Recording and .uyava Logs](/docs/recording-logs)
- [Under the Hood](/docs/architecture)
