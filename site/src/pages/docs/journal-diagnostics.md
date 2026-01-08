---
layout: ../../layouts/DocsLayout.astro
title: "Journal and Diagnostics"
description: "Event history, diagnostics, and focus workflows."
---

# Journal and Diagnostics

The Journal panel is your live event timeline. Diagnostics surface data integrity issues and host warnings. Together they explain what happened and why the graph looks the way it does.

## Journal

The Journal tab lists node and edge events in time order.

- Each row shows the node or edge, severity, timestamp, and message.
- Event details expose payloads and source metadata when available.
- Auto-scroll keeps the latest activity visible during live sessions.

### Journal search

The search field performs a case-insensitive substring match across:

- message text
- node and edge IDs
- tags and severity
- diagnostic codes and subjects
- key/value pairs inside payloads

Empty results usually mean the filters or focus set excluded the events, not that the events are missing.

### Focus set

Focus narrows the journal to a subset without hiding the graph. Use the graph context menu or the journal toolbar to:

- add or remove focused nodes and edges
- reveal hidden items
- pause focus filtering temporarily
- toggle whether the journal mirrors the main graph filter

Focus is separate from the global filter. The graph always stays visible; focus only scopes the log view.

## Diagnostics

Diagnostics report integrity and validation issues. Typical examples:

- duplicate node or edge IDs
- invalid colors or shapes
- dangling edges (missing source or target)
- invalid filters (bad regex or unknown IDs)
- event chain mismatches (unknown chain or step)

Each entry shows a code and details. The inline Docs button opens a small reference panel explaining the diagnostic and how to fix it.

## Clearing the log

Use Clear log to reset the in-memory event and diagnostics lists. The graph state remains intact; only the journal history clears.
