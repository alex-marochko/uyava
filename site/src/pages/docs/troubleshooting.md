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

## No Uyava output in app console

- Confirm `Uyava.enableConsoleLogging(...)` is called in app startup.
- Check `minLevel`: if too high, lower-severity events are intentionally hidden.
- Check `includeTypes` / `excludeTypes`: you may be filtering out all events.
- If you disabled logging earlier with `Uyava.disableConsoleLogging()`, re-enable it.
- For full config options, see [SDK Integration](/docs/sdk-integration).

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

## `.uyava` file does not open in Desktop

- Make sure you are testing with the latest Desktop build.
- Open the file from Desktop File mode (not only by double-click association).
- Check archive integrity:

```bash
gunzip -c session.uyava > /tmp/session.ndjson
```

- If decompression works but Desktop still fails to load the file, report the issue with platform + Desktop version.

## Performance tips

- Collapse parent groups to reduce visual noise.
- Avoid a single synthetic root parent for all nodes; split into meaningful top-level roots to reduce graph crowding.
- Use severity filters for incident triage.
- Enable sampling in file logging to reduce volume.
