---
layout: ../../layouts/DocsLayout.astro
title: "SDK Integration"
description: "Instrument apps and ship Uyava data safely."
---

# SDK Integration

The `uyava` SDK runs inside your app and publishes structured events to connected hosts. It normalizes payloads, applies validation rules, and sends data through registered transports.

## Core flow

1) Initialize once at startup:

```dart
Uyava.initialize();
```

2) Send a graph snapshot:

```dart
Uyava.replaceGraph(
  nodes: const [
    UyavaNode(id: 'ui.login', type: 'screen', label: 'Login', tags: ['ui']),
  ],
  edges: const [
    UyavaEdge(id: 'ui.login->logic.auth', from: 'ui.login', to: 'logic.auth'),
  ],
);
```

3) Apply incremental updates as needed:

```dart
Uyava.addNode(const UyavaNode(id: 'logic.auth', type: 'service', label: 'Auth'));
Uyava.patchNode('logic.auth', {'label': 'Auth Service', 'tags': ['auth']});
Uyava.removeEdge('ui.login->logic.auth');
```

## Runtime events

Events power pulses, badges, and the journal.

```dart
Uyava.emitNodeEvent(
  nodeId: 'logic.auth',
  message: 'Sign in pressed',
  severity: UyavaSeverity.info,
  tags: ['auth'],
);

Uyava.emitEdgeEvent(
  edge: 'ui.login->logic.auth',
  message: 'Auth request sent',
  severity: UyavaSeverity.warn,
);
```

The `message` field is mandatory and appears in the Journal and log exports.

## Lifecycle updates

Use lifecycle signals to dim inactive nodes:

```dart
Uyava.updateNodeLifecycle(
  nodeId: 'logic.auth',
  state: UyavaLifecycleState.initialized,
);

Uyava.updateNodesListLifecycle(
  nodeIds: ['logic.auth', 'data.session'],
  state: UyavaLifecycleState.disposed,
);
```

## Source references

Add `sourceRef` to nodes or events so Desktop can open the IDE at the right file:

```dart
Uyava.addNode(
  const UyavaNode(id: 'logic.auth', type: 'service', label: 'Auth'),
  sourceRef: Uyava.caller(),
);
```

## Diagnostics

You can emit app-specific diagnostics or clear the buffer:

```dart
Uyava.postDiagnostic(
  code: 'auth.token_expired',
  level: UyavaDiagnosticLevel.warn,
  nodeId: 'logic.auth',
);

Uyava.clearDiagnostics();
```

## Transports

Uyava publishes events to a transport hub.

- Default: VM Service transport for DevTools and Desktop.
- Optional: file logging and custom transports.

```dart
Uyava.registerTransport(MyWebSocketTransport(uri: Uri.parse('ws://...')));
```

See Recording and .uyava Logs for file logging details.

## Data integrity rules

- Node and edge IDs must be unique.
- Colors must be `#RRGGBB` or `#AARRGGBB`.
- Shapes must match `^[a-z0-9_-]+$`.
- Dangling edges are dropped and reported in diagnostics.

Follow these rules to keep the graph stable and diagnostics clean.
