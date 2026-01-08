---
layout: ../../layouts/DocsLayout.astro
title: "Under the Hood"
description: "How the SDK, core, and UI fit together."
---

# Under the Hood

Uyava is a layered system designed to keep UI, data validation, and SDK transport concerns cleanly separated.

## Package roles

- `uyava` (SDK): runs inside your app, normalizes payloads, and publishes events.
- `uyava_protocol`: shared wire models and validation helpers.
- `uyava_core`: graph controller, filters, metrics, event chains, diagnostics.
- `uyava_ui`: shared renderer, interaction, panels, and layout.
- `uyava_devtools_extension`: Flutter web host inside DevTools.
- `uyava_desktop`: desktop host with VM Service client and replay.

## Data flow

1) Your app calls the SDK (initialize, replaceGraph, emit events).
2) The SDK publishes events through a transport hub.
3) Hosts subscribe to VM Service events and parse payloads.
4) The host forwards sanitized data into `GraphController`.
5) `GraphController` computes layout, filters, metrics, chains, and diagnostics.
6) `uyava_ui` renders the graph and panels with the shared state.

## Event scopes

Events carry a scope to help hosts route them:

- `snapshot`: graph mutations and full snapshots.
- `realtime`: transient node/edge events.
- `diagnostic`: integrity warnings and lifecycle clears.

## Filtering pipeline

Filters live in `GraphFilterEngine` and produce a `GraphFilterResult`:

- `visibleNodes`, `visibleEdges`
- `visibleMetrics`, `visibleEventChains`
- `hiddenByDepthNodeIds` and auto-collapsed parents

Hosts render and persist only filtered data, keeping UI consistent across DevTools and Desktop.

## Logging pipeline

File logging uses `UyavaFileTransport`:

- Writes gzip-compressed NDJSON `.uyava` archives.
- Runs compression, rotation, and retention in a worker isolate.
- Supports sampling, severity gates, and redaction.
- Exposes exports and archive events for share workflows.

## Diagnostics pipeline

Validation happens in `uyava_protocol` and `uyava_core`:

- Tag, color, and shape normalization.
- Duplicate IDs emit warnings but keep last writer.
- Dangling edges are dropped with diagnostics.
- Chain and metric validation surface explicit codes.

Diagnostics are visible in the Journal panel and can be cleared via the SDK.
