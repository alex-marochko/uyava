---
layout: ../../layouts/DocsLayout.astro
title: "Best Practices"
description: "Practical guidance for modeling graphs, events, and Open in IDE."
---

# Best Practices

These recommendations keep your graphs readable, your sessions stable, and your IDE links accurate.

## Build a static graph skeleton

Define the full set of nodes and edges at startup. After that, update lifecycle only.

- Prefer `Uyava.replaceGraph()` once at launch.
- Avoid `addNode`/`removeNode` during runtime unless the structure is truly permanent.
- Use lifecycle states to express activity (`initialized`, `disposed`) instead of adding/removing nodes.

This keeps the layout stable and makes recordings deterministic.

## Keep data out of the structure

Files, users, sessions, or requests are data. Represent them as events + payloads, not as nodes.

- Nodes represent parts of your architecture.
- Event payloads represent runtime data.

## Model sessions as lifecycle states

If you have “active sessions” (send/receive, sync, playback), keep a static node for the session type and toggle its lifecycle:

```dart
Uyava.updateNodeLifecycle(
  nodeId: 'transfer.send_session',
  state: UyavaLifecycleState.initialized,
);
```

This avoids churn and gives a clear, dimmed/active story in the UI.

## Open in IDE: always pass source references

There are two levels of source references:

1) **Nodes** — set a static file reference when you add the node:

```dart
Uyava.addNode(
  const UyavaNode(
    id: 'network.http_client',
    type: 'api',
    label: 'HTTP Client',
  ),
  sourceRef: 'package:my_app/network/http_client.dart:1:1',
);
```

2) **Events** — capture the real call site:

```dart
Uyava.emitNodeEvent(
  nodeId: 'network.http_client',
  message: 'GET /ping',
  sourceRef: Uyava.caller(),
);
```

**Rule of thumb:** never hide all logging inside a single “logger.dart”.  
Instead, call the logger from the real code path and pass `Uyava.caller()` from there.

## Track UI lifecycle explicitly

If you expose UI nodes, activate and deactivate them from real UI code:

- `initState` → `initialized`
- `dispose` → `disposed`
- tab switches → `onUiTabChanged`

This keeps the UI layer readable without dynamic structure.

## Use event chains to tell a story

Chains are best for causal flow:

- session created → prepare → transfer complete
- selection accepted → transfer started → saved

Keep chain step IDs stable so filters and replay remain reliable.

## Attach metrics to events

Metrics belong to runtime events, not nodes.

```dart
Uyava.emitNodeEvent(
  nodeId: 'transfer.send_session',
  message: 'File sent',
  payload: {
    'metric': {
      'id': 'transfer.file_size_bytes',
      'value': bytes,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    },
  },
);
```

This powers dashboards without polluting your graph structure.

## Capture errors centrally

Add a dedicated `errors` node and hook global error handlers so the Journal mirrors your console:

```dart
FlutterError.onError = (details) {
  FlutterError.dumpErrorToConsole(details);
  Uyava.emitNodeEvent(
    nodeId: 'app.errors',
    message: details.exceptionAsString(),
    severity: UyavaSeverity.error,
  );
};
```

Keep the default error behavior; just mirror it into Uyava.

## Keep volume under control

High-frequency events can overwhelm the UI.

- Aggregate where possible (ex: sample throughput every N ms).
- Use severity only for meaningful states.
- Prefer single “summary” events to per‑frame noise.

## Make logs replayable

If you use `.uyava` recording:

- keep structure static,
- avoid runtime node removal,
- include source references for nodes and events.

The replay view is only as good as the structure you record.

