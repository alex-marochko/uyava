---
layout: ../../layouts/DocsLayout.astro
title: "Session File Format (.uyava)"
description: "Complete wire format for Uyava replay files."
---

# Session File Format (.uyava)

This page defines the `.uyava` wire format for replay files.

## Container

- File extension: `.uyava`
- Content: NDJSON (`UTF-8`, one JSON object per line)
- Recommended order:
  1. `sessionHeader`
  2. event records
  3. optional marker records
- Desktop replay compatibility: `gzip` or plain NDJSON (`none`).

## Record kinds

Each NDJSON line is one record. Supported kinds:

- Header record: `type: "sessionHeader"` (or `recordType: "header"`)
- Event record: `recordType: "event"` (or omitted)
- Marker record: `recordType: "marker"` or `type: "_marker"`

If `recordType` is omitted and `type` is not `sessionHeader`/`_marker`, the line is treated as an event.

## Header record

Required:

- `type`: `"sessionHeader"`
- `sessionId`: string
- `startedAt`: ISO-8601 timestamp

Versioning:

- `formatVersion` (preferred) and `schemaVersion` (legacy alias) are both read
- current supported value: `1`
- values `> 1` are rejected by Desktop replay

Optional metadata:

- `compression`: `"gzip"` | `"none"` | `"zstd"` (for Desktop replay files, use `gzip` or `none`)
- `app`: `{ "name"?, "version"?, "build"? }`
- `platform`: `{ "os"?, "version"?, "timezone"? }`
- `reason`: string
- `redaction`: `{ redactionApplied, allowRawData?, maskFields?, dropFields?, tagsAllowList?, tagsDenyList? }`
- `hostMetadata`: object
- `recorder`: object

## Event envelope

Canonical shape:

```json
{
  "recordType": "event",
  "type": "replaceGraph",
  "timestamp": "2026-03-06T13:17:34.282591Z",
  "monotonicMicros": 22613,
  "scope": "realtime",
  "sequenceId": "optional",
  "payload": {}
}
```

Fields:

- `type` (required): event type string
- `payload` (required): event payload object
- `timestamp` (recommended): ISO-8601 timestamp
- `monotonicMicros` (recommended): microseconds since session start
  - legacy fallback: `timestampMicros`
  - if both are missing, value becomes `0`
- `scope` (optional): `snapshot` | `realtime` | `diagnostic`
- `sequenceId` (optional): string
- `redactedKeys` (optional): string[]
- `hostMetadata` (optional): object

## Graph payload contracts

### Node object (`nodes[]`, `addNode`, `patchNode.node`)

Required:

- `id`: string

Canonical/recommended:

- `type`: string (`"unknown"` if omitted)
- `label`: string (falls back to `id` if omitted/empty)

Optional:

- `description`: string
- `parentId`: string
- `tags`: string[]
- `tagsNormalized`: string[]
- `tagsCatalog`: string[]
- `color`: normalized hex color
- `colorPriorityIndex`: int
- `shape`: string
- `lifecycle`: `unknown | initialized | disposed`
- `initSource`: string

Modeling note: the format allows a single global root node, but this is discouraged for real graphs. A synthetic root with all nodes under it usually reduces readability and increases visual density. Prefer several meaningful top-level roots.

### Edge object (`edges[]`, `addEdge`, `patchEdge.edge`)

Required:

- `id`: string
- `source`: string (node id)
- `target`: string (node id)

Optional:

- `label`: string
- `description`: string
- `remapped`: boolean
- `bidirectional`: boolean

For graph snapshots/updates, use `source`/`target` (not `from`/`to`).

## Supported event types

### `replaceGraph`

Replaces graph state.

Payload:

- `nodes`: node[]
- `edges`: edge[]
- `metrics` (optional): metric definition[]
- `eventChains` (optional): event-chain definition[]
- `sourceId` / `sourceType` (optional): ingest metadata

### `loadGraph`

Merges graph data into current state.

Payload:

- `nodes` (optional): node[]
- `edges` (optional): edge[]

### `addNode`

Payload: single node object.

### `addEdge`

Payload: single edge object.

### `removeNode`

Payload:

- `id`: node id
- `cascadeEdgeIds` (optional): string[]

### `removeEdge`

Payload:

- `id`: edge id

### `patchNode`

Payload:

- `id` (recommended): node id
- `node`: full node object snapshot
- `changedKeys` (optional): string[]

### `patchEdge`

Payload:

- `id` (recommended): edge id
- `edge`: full edge object snapshot (with `source`/`target`)
- `changedKeys` (optional): string[]

### `edgeEvent` (and legacy alias `animation`)

Payload:

- `message`: non-empty string (required for render/journal)
- either:
  - `from` + `to`, or
  - `edge` (resolved to endpoints from known edges)
- `severity` (optional): `trace|debug|info|warn|error|fatal`
- `timestamp` (optional): ISO-8601
- `sourceRef` / `sourceId` / `sourceType` (optional)
- `isolateId` / `isolateName` / `isolateNumber` (optional)

### `nodeEvent`

Payload:

- `nodeId`: string (required)
- `message`: string (recommended; defaults to `"node event"` if missing/empty)
- `severity` (optional): `trace|debug|info|warn|error|fatal`
- `tags` (optional): string[]
- `timestamp` (optional): ISO-8601
- `sourceRef` / `sourceId` / `sourceType` (optional)
- `isolateId` / `isolateName` / `isolateNumber` (optional)
- `payload` (optional): object for nested data

Nested metric sample inside `nodeEvent.payload`:

```json
{
  "metric": {
    "id": "checkout_duration_ms",
    "value": 1529.0,
    "timestamp": "2026-03-06T13:17:35.813290Z"
  }
}
```

Nested event-chain progress inside `nodeEvent.payload`:

```json
{
  "chain": {
    "id": "checkout_flow",
    "step": "place_order",
    "attempt": "attempt-1",
    "status": "failed"
  },
  "edgeId": "e75"
}
```

Notes:

- chain object requires `id` and `step`
- `attempt` is optional
- failure is detected when status is `"failed"` or `"failure"`
- legacy fallback: if `chain.status` is missing, top-level `payload.status` is used

### `nodeLifecycle`

Payload:

- `nodeId`: string
- `state`: `initialized | disposed | unknown`

### `defineMetric`

Payload:

- `id`: string (required)
- `label` (optional)
- `description` (optional)
- `unit` (optional)
- `tags` (optional): string[]
- `tagsNormalized` (optional): string[]
- `aggregators` (optional): `last|min|max|sum|count`[]
  - defaults to `["last"]` if missing/invalid

### `defineEventChain`

Payload:

- `id`: string (required)
- at least one tag:
  - `tags`: string[] (preferred), or
  - `tag`: string (legacy)
- `label` (optional; defaults to `id`)
- `description` (optional)
- `tagsNormalized` (optional)
- `tagsCatalog` (optional)
- `steps`: step[] (required)

Step object:

- `stepId`: string (required)
- `nodeId`: string (required)
- `edgeId`: string (optional)
- `expectedSeverity`: `trace|debug|info|warn|error|fatal` (optional)

### `graphDiagnostics`

Payload:

- `code`: string (required)
- `level`: `info|warning|error` (required)
- `codeEnum` (optional)
- `nodeId` (optional)
- `edgeId` (optional)
- `context` (optional): object
- `timestamp` (optional): ISO-8601

### `clearDiagnostics`

Payload: empty object `{}` (recommended).

## Marker record (optional)

Marker shape:

```json
{
  "recordType": "marker",
  "type": "_marker",
  "id": "checkpoint-1",
  "label": "Payment failed",
  "timestamp": "2026-03-06T13:17:35.813365Z",
  "offsetMicros": 1553387,
  "kind": "error",
  "level": "warn",
  "meta": { "requestId": "r-42" }
}
```

Core marker fields:

- `id`
- `label`
- `timestamp`
- `offsetMicros`

## Minimal valid file

```json
{"type":"sessionHeader","formatVersion":1,"schemaVersion":1,"sessionId":"demo-001","startedAt":"2026-03-06T13:17:34.259978Z","compression":"none"}
{"recordType":"event","type":"replaceGraph","timestamp":"2026-03-06T13:17:34.282591Z","monotonicMicros":22613,"scope":"snapshot","payload":{"nodes":[{"id":"a","type":"screen","label":"A"}],"edges":[]}}
{"recordType":"event","type":"nodeEvent","timestamp":"2026-03-06T13:17:34.313886Z","monotonicMicros":53908,"scope":"realtime","payload":{"nodeId":"a","message":"opened","severity":"info"}}
```

## Validation checklist

1. NDJSON only: one JSON object per line.
2. Include exactly one `sessionHeader`.
3. Use `formatVersion: 1` (and `schemaVersion: 1` for compatibility).
4. Keep `monotonicMicros` non-negative and monotonic.
5. For graph edges in snapshots/updates use `source`/`target`.
6. For `edgeEvent`, include non-empty `message` and valid endpoints (`from`/`to` or resolvable `edge`).
7. Avoid a synthetic single global root parent for all nodes; prefer domain/feature top-level roots for better replay readability.
