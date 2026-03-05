---
layout: ../../layouts/DocsLayout.astro
title: "Session File Format (.uyava)"
description: "NDJSON contract for manually generating Uyava replay archives."
---

# Session File Format (.uyava)

This page documents the `.uyava` session format so you can generate files manually (including via scripts or LLM agents) and open them in Uyava Desktop.

## Format at a glance

- File extension: `.uyava`
- Payload format: NDJSON (one JSON object per line, UTF-8)
- Recommended line order:
  1) `sessionHeader`
  2) event records
  3) optional marker records
- Compression for replay compatibility today: `gzip` or plain text (`none`)

## Minimal valid archive

```json
{"type":"sessionHeader","formatVersion":1,"schemaVersion":1,"sessionId":"demo-001","startedAt":"2026-03-04T12:00:00.000Z","compression":"none"}
{"recordType":"event","type":"replaceGraph","timestamp":"2026-03-04T12:00:00.100Z","monotonicMicros":100000,"scope":"snapshot","payload":{"nodes":[{"id":"screen.home","type":"screen","label":"Home"}],"edges":[]}}
{"recordType":"event","type":"nodeEvent","timestamp":"2026-03-04T12:00:00.250Z","monotonicMicros":250000,"scope":"realtime","payload":{"nodeId":"screen.home","message":"Home opened","severity":"info"}}
```

You can save this as plain text `demo.uyava`, or gzip it and keep the same extension.

## Header record (`sessionHeader`)

Required fields:

- `type`: must be `"sessionHeader"`
- `sessionId`: stable session identifier
- `startedAt`: ISO timestamp (UTC recommended)

Version fields:

- `formatVersion` and `schemaVersion` are both accepted
- Current supported format version is `1`
- Future unsupported versions are rejected by Desktop replay

Useful optional fields:

- `compression`: `"gzip"`, `"none"` (use these for Desktop replay compatibility)
- `app`: `{ "name", "version", "build" }`
- `platform`: `{ "os", "version", "timezone" }`
- `reason`
- `hostMetadata`
- `recorder`
- `redaction`

## Event record

Canonical event line:

```json
{"recordType":"event","type":"nodeEvent","timestamp":"2026-03-04T12:00:01.000Z","monotonicMicros":1000000,"scope":"realtime","payload":{"nodeId":"auth.cubit","message":"Sign in pressed","severity":"info"}}
```

Expected fields:

- `type`: event type (`replaceGraph`, `nodeEvent`, `edgeEvent`, etc.)
- `timestamp`: ISO timestamp
- `payload`: JSON object

Strongly recommended:

- `monotonicMicros`: integer offset from session start in microseconds
- `scope`: `snapshot`, `realtime`, or `diagnostic`
- `sequenceId`: stable ordering hint when needed

Compatibility notes:

- If `recordType` is omitted, the line is still treated as an event (unless `type` is `sessionHeader` or `_marker`)
- `timestampMicros` is accepted as a legacy fallback when `monotonicMicros` is missing
- If `monotonicMicros` is missing, replay falls back to `0`, which collapses timeline accuracy

## Marker record (optional)

Markers appear on replay timeline and can highlight errors/checkpoints.

```json
{"recordType":"marker","type":"_marker","id":"m1","label":"API timeout","timestamp":"2026-03-04T12:00:01.500Z","offsetMicros":1500000,"kind":"error","level":"warn","meta":{"requestId":"r-42"}}
```

Core fields:

- `id`
- `label`
- `timestamp`
- `offsetMicros`

## Recommended event types for practical replay

- `replaceGraph`: publish a graph snapshot first (nodes/edges)
- `nodeEvent`: node-level runtime messages
- `edgeEvent`: directed interaction messages between nodes
- `nodeLifecycle`: initialized/disposed state changes
- `defineMetric` and metric samples in payloads
- `defineEventChain`: multi-step flow definitions

## Compression and conversion

Create plain NDJSON first, then optionally gzip:

```bash
gzip -c demo.ndjson > demo.uyava
```

Desktop replay currently auto-detects gzip by file signature and also supports plain-text NDJSON files with `.uyava` extension.

## Validation checklist

1. One JSON object per line (no top-level array).
2. Include exactly one `sessionHeader` line and place it first.
3. Use ISO timestamps (`YYYY-MM-DDTHH:mm:ss.sssZ`).
4. Keep `monotonicMicros` non-negative and monotonically increasing.
5. For `nodeEvent` and `edgeEvent`, include meaningful non-empty `message` in payload.

## Troubleshooting

- Error `Missing sessionHeader`: header record is absent or malformed.
- Replay opens with many warnings: one or more NDJSON lines are invalid JSON.
- Timeline looks flat/jumpy: missing or incorrect `monotonicMicros`.

For capture/export flow and host behavior, see [Recording and .uyava Logs](/docs/recording-logs).
