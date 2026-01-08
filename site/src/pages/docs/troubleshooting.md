---
layout: ../../layouts/DocsLayout.astro
title: "Troubleshooting"
description: "Common issues, permissions, and performance tips."
---

# Troubleshooting

## No data in DevTools

- Confirm `Uyava.initialize()` runs before the app starts.
- Run the app in debug or profile mode (VM Service must be available).
- Ensure the Uyava extension is selected in DevTools.
- Verify your graph snapshot uses unique IDs.

## Desktop cannot connect

- Paste the VM Service URI exactly as shown in your terminal.
- Confirm the app is running with VM Service enabled (debug/profile).
- If you are behind a firewall or VM, ensure the URI is reachable.

## Filters hide everything

- Clear the filters and check the graph again.
- Invalid regex or mask patterns emit diagnostics and are ignored.
- Remember that focus only affects the Journal, not the graph.

## Diagnostics warnings

- `nodes.duplicate_id` means the last payload wins.
- `edges.dangling_*` means an edge referenced a missing node and was dropped.
- `nodes.invalid_color` or `nodes.invalid_shape` indicates invalid styling.

Use the Diagnostics Docs button to see the exact fix.

## .uyava logs are missing

- For SDK logging, ensure `directoryPath` is valid and writable.
- On macOS sandboxed builds, logs may be stored under the container temp folder.
- Use `Uyava.exportCurrentArchive()` to force a sealed file for sharing.

## Performance tips

- Collapse parent groups to reduce visual noise.
- Use severity filters for incident triage.
- Enable sampling in file logging to reduce volume.
