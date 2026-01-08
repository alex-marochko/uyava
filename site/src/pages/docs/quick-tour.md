---
layout: ../../layouts/DocsLayout.astro
title: "Quick Tour"
description: "A walkthrough of the graph, panels, and daily workflow."
---

# Quick Tour

This tour follows the default DevTools and Desktop layouts. The UI is the same across hosts unless noted.

## 1) Graph viewport

- Nodes and edges form the live architecture map.
- Pan with drag, zoom with the wheel or pinch, and use the toolbar to fit or reset the viewport.
- Node and edge events animate as pulses and moving dots. High volume edges show a small badge with aggregated counts.
- Parent groups can be collapsed or expanded. Collapsing is instant and deterministic to keep visibility consistent.

## 2) Floating overlays

- Tag highlights legend (top-left) shows colored tags with counts.
- Grouping controls (top-right) toggle grouping depth and expansion without shifting the canvas.

## 3) Filters and search

Filters sit at the top. They control what you see on the graph and in the journal.

- Search supports substring, wildcard, and regex modes.
- Tag filters let you include or exclude tagged nodes and edges.
- Severity filtering can focus on warnings or errors without losing context.

See Filters, Focus, and Grouping for full behavior details.

## 4) Metrics dashboard

Metrics cards aggregate samples (Last, Min, Max, Sum, Count, Avg). The compact mode keeps large metric sets readable while still showing the aggregates.

## 5) Event chains

Chains show multi-step flows such as login or checkout. Each chain shows its current step and a history of attempts. Use pins to keep the most important chains at the top.

## 6) Journal and diagnostics

- The Journal tab lists runtime events with timestamps and severity.
- The Diagnostics tab shows integrity warnings (duplicate IDs, dangling edges, invalid colors).
- The focus toolbar lets you narrow the journal to a selected set without hiding the graph.

## 7) Desktop-specific record/replay

Desktop adds a Record/Replay bar:

- Record in Live mode, then save a .uyava log.
- Switch to File mode to replay a saved log with playback controls.
- Recent recordings appear in the open list, and the app can reveal the current log in your file explorer.

Read Recording and .uyava Logs for details.
