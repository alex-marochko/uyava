---
layout: ../../layouts/DocsLayout.astro
title: "Graph Model and Styling"
description: "Nodes, edges, groups, lifecycle, and visual semantics."
---

# Graph Model and Styling

Uyava models your app as a directed graph with optional hierarchy. The SDK sends snapshots and incremental updates; the host renders a stable, deterministic view.

## Nodes

Nodes describe logical parts of your system.

Required fields:

- `id` (unique, stable)
- `type` (controls icon and default styling)
- `label`

Optional fields:

- `description`
- `tags` (normalized, deduped, lowercased for matching)
- `color` (hex: #RRGGBB or #AARRGGBB)
- `shape` (must match `^[a-z0-9_-]+$`)
- `parentId` (for grouping)
- `lifecycle` (initialized, disposed, unknown)

Uniqueness is enforced by the core. Duplicate IDs keep the latest payload and emit diagnostics.

## Edges

Edges are directed connections between nodes.

Required fields:

- `id` (unique)
- `from` and `to` (node IDs)

Optional fields:

- `label`, `description`, `tags`, `color`
- `data.bidirectional` (if you want arrows on both ends)

If an edge references missing nodes, it is dropped and a diagnostics entry is emitted.

## Groups and hierarchy

Use `parentId` to group nodes. Collapsing a parent does not animate through multiple states; it switches instantly to keep visibility deterministic. When collapsed:

- Child nodes are hidden.
- Event pulses are aggregated at the parent.
- Edges route through the visible ancestor.

## Lifecycle dimming

Nodes can report lifecycle state:

- `unknown` (default, dimmed slightly)
- `initialized` (full opacity)
- `disposed` (dimmed heavily)

This helps highlight which parts of the graph are active at runtime.

## Color and icon rules

Uyava resolves node color in this order:

1) `colorPriorityIndex` (if provided by the SDK, mapped to a shared palette)
2) Explicit `color` (hex)
3) The first tag from the shared catalog
4) Type default (built-in palette in the UI)

Shared tag catalog (lowercase):

`ui, state, domain, data, network, external, integration, test, critical, legacy, experimental, platform, shared, core, feature, infra, observability, security, auth`

Priority palette (hex):

`#1F6FEB, #58A6FF, #3FB950, #F78166, #FF7B72, #D29922, #A371F7, #8B949E`

Icons follow the node `type` (screen, service, repository, queue, etc). Unknown types fall back to a neutral icon.

## Severity colors

Severity tints node pulses, edge dots, and badges:

- trace: gray
- debug: blue-gray
- info: blue
- warn: amber
- error: red accent
- fatal: red

Warn and above can be emphasized by the renderer (larger pulses and dots).

## Source metadata

Nodes and events can include `sourceRef` (for example `package:my_app/auth.dart:42:5`). Desktop can open these locations in an IDE; DevTools keeps the menu disabled until a native bridge exists.
