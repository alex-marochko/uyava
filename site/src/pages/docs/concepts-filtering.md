---
layout: ../../layouts/DocsLayout.astro
title: "Filters, Focus, and Grouping"
description: "How filters affect the graph, journal, and panels."
---

# Filters, Focus, and Grouping

Uyava filters are local, fast, and deterministic. They update the visible graph, the journal feed, and the panel data without round trips.

## Filter inputs

The filter model includes:

- Search: substring, wildcard (mask), or regex.
- Tags: include or exclude tags using any or all logic.
- Nodes and edges: explicit include/exclude lists.
- Parent filter: show a subtree rooted at a specific node with a depth limit.
- Grouping: hide deep descendants while keeping parent summaries visible.
- Severity: atLeast, atMost, or exact for warn/error triage.

If a filter is invalid (for example a bad regex), Uyava emits a diagnostics entry and keeps the last valid filter.

## What filters affect

- Graph: nodes and edges that pass filters remain visible; hidden nodes are removed from layout.
- Metrics: metric cards are filtered by the active graph filter set.
- Event chains: chain snapshots are filtered the same way.
- Journal: events and diagnostics respect the same filter state.

Severity filtering is special: it gates the graph and journal, but metrics and event chains stay visible so aggregates remain trustworthy.

## Focus vs filters

Focus is a journal-only scoping tool. It does not hide graph elements; it highlights them and narrows the journal list so you can audit a subset.

- Use the graph context menu or journal toolbar to add focus items.
- Toggle whether the journal mirrors the main graph filter.
- Clear focus to restore the full journal list.

## Grouping and depth

Grouping can collapse deep hierarchies while keeping a stable overview. Uyava treats hidden descendants as part of the parent group and keeps event pulses on the visible ancestor when a group is collapsed.

## Auto-apply vs manual apply

Desktop and DevTools can run filters in two modes:

- Auto-apply: a short debounce applies changes as you type.
- Manual: apply and clear buttons give you explicit control.

Use auto-apply for exploration and manual apply for large graphs to avoid accidental heavy updates.
