# Uyava SDK

`uyava` is the host-side SDK that an application links into in order to stream
architecture graphs, lifecycle information, and runtime events to Uyava hosts
such as the Flutter DevTools extension or the desktop viewer. It collects graph
metadata in-process, normalizes payloads, and publishes structured events over
transport channels that the hosts subscribe to.

> **Note**
> The overall project vision, architecture constraints, and validation
> requirements are documented centrally in `AGENTS.md` and `TEST_PLAN.md` at the
> repo root. Review them before making significant changes.

## Getting Started

Add the SDK to your application:

```yaml
# pubspec.yaml
dependencies:
  uyava:
    path: ../../packages/uyava
```

Initialize Uyava as early as possible in `main()` so the DevTools extension or
other hosts can query the initial graph snapshot:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Uyava.initialize();
  runApp(const MyApp());
}
```

After initialization you can gradually describe your architecture and stream
runtime signals:

```dart
Uyava.addNode(
  const UyavaNode(
    id: 'auth.repository',
    type: 'repository',
    label: 'AuthRepository',
    tags: ['auth', 'repository'],
  ),
);

Uyava.addEdge(
  const UyavaEdge(
    id: 'auth.repo->auth.service',
    from: 'auth.repository',
    to: 'auth.service',
  ),
);

Uyava.emitNodeEvent(
  nodeId: 'auth.service',
  message: 'User signed in',
  severity: UyavaSeverity.info,
  payload: {'userId': '123'},
);

// Selective updates and removals
Uyava.patchNode('auth.service', {
  'label': 'Auth Service (patched)',
  'color': '#FF7043',
});

Uyava.patchEdge('auth.repo->auth.service', {
  'label': 'Repository → Service',
});

Uyava.removeEdge('auth.repo->auth.service');
Uyava.removeNode('auth.service');
```

The SDK enforces ID uniqueness, validates node styling (color, tags, shape), and
records graph diagnostics that hosts surface to the user.

`removeNode` automatically cascades to connected edges so you never emit
dangling references. `patchNode` and `patchEdge` accept partial payloads, apply
the shared normalization rules (tags, color, shape), and emit last-writer-wins
events that hosts merge incrementally without forcing a full graph reload.

## Transport Abstraction

Uyava 0.0.1 introduces a transport hub that routes every SDK event through
pluggable transports. The default transport publishes VM Service events, keeping
current DevTools behaviour intact. Additional transports can mirror the same
events to WebSocket gateways, local files, or custom sinks.

### Core Concepts

- `UyavaTransportEvent` — immutable envelope holding event type, payload, ISO
  timestamp, optional `sequenceId`, and a `scope` hint (`realtime`, `snapshot`,
  or `diagnostic`).
- `UyavaTransport` — base contract with `channel`, `accepts`, `send`, `flush`,
  and `dispose` hooks.
- `UyavaTransportHub` — orchestrates registered transports, swallowing
  individual failures so one bad transport cannot break the SDK.

The SDK ships with:

- `UyavaVmServiceTransport` — default implementation using
  `dart:developer.postEvent` with the standard `ext.uyava.event` kind.
- `UyavaWebSocketTransport` and `UyavaLocalFileTransport` — abstract bases you
  can extend to implement concrete WebSocket or NDJSON/file appenders that share
  the same channel identifiers.

### Registering Transports

Register transports before emitting events (ideally right after
`Uyava.initialize()`):

```dart
Uyava.registerTransport(
  MyWebSocketTransport(uri: Uri.parse('ws://localhost:8123/uyava')),
);

Uyava.registerTransport(
  MyFileTransport(path: '/tmp/session.uyava.jsonl'),
  replaceExisting: false,
);
```

Use `Uyava.unregisterTransport(channel)` to remove a transport and
`Uyava.shutdownTransports()` to flush and dispose every registered transport when
shutting down the app or test harness.

### Scoping Events

Hosts can inspect `UyavaTransportEvent.scope` to treat payloads differently:

- `realtime` — transient pulses such as `nodeEvent` or `edgeEvent`.
- `snapshot` — graph state mutations (`loadGraph`, `replaceGraph`).
- `diagnostic` — integrity diagnostics, lifecycle clears, and similar metadata.

Scopes help selective routing (e.g., persist only snapshots, ignore transient
pulses in batch exporters).

### File Logging Transport

Uyava ships a `UyavaFileTransport` for recording event streams to
gzip-compressed NDJSON archives (`*.uyava`). Configure and register it via
`Uyava.enableFileLogging`:

```dart
final transport = await Uyava.enableFileLogging(
  config: UyavaFileLoggerConfig(
    directoryPath: '/tmp/uyava-logs',
    maxFileSizeBytes: 32 * 1024 * 1024,
    maxDuration: const Duration(minutes: 30),
    maxFileCount: 5,
    realtimeSamplingRate: 0.5, // optional sampling
    redaction: const UyavaRedactionConfig(
      allowRawData: false,
      maskFields: <String>['payload.token'],
    ),
  ),
);
```

Key options:

- rotation & retention: `maxFileSizeBytes`, `maxDuration`, `maxFileCount`,
  `retainLatestOnly`;
- export housekeeping: `maxExportCount` caps how many sealed archives stay in
  `exports/`, while `maxExportTotalBytes` constrains the cumulative size so
  repeated "share" actions do not silently fill the user's disk;
- scope filtering: always persists `snapshot`/`diagnostic`, while
  `realtimeEnabled`, `realtimeSamplingRate`, and `realtimeBurstLimitPerSecond`
  control high-volume pulses; `includeTypes` / `excludeTypes` enable
  fine-grained routing;
- severity filtering: `minLevel` (default `trace`) drops `nodeEvent`/
  `edgeEvent` and other severity-tagged payloads below the configured
  threshold while still capturing higher-priority diagnostics;
- streaming journal: `streamingJournalEnabled` (default `false`) mirrors every
  record into a plain NDJSON companion (`streamingJournalFileName`, default
  `panic-tail-active.jsonl`) and flushes on
  `streamingJournalFlushInterval`. The worker promotes any orphaned journal from
  the previous run into a sealed `.uyava` archive before starting a fresh
  session, so hard kills still leave a readable snapshot;
- crash resilience: `crashSafePersistence` mirrors every panic record to a
  plain-text JSONL companion (`panicMirrorFileName`, default
  `panic-tail.jsonl`) and seals the active `.uyava` archive immediately after a
  fatal flush so crash tooling has a ready-to-send snapshot even if the process
  cannot reopen the gzip stream;
- redaction: `UyavaRedactionConfig` trims sensitive fields (mask/drop), toggles
  `rawData`, and exposes `customHandler` for app-specific sanitization.

Events dropped by sampling or burst protection emit aggregated diagnostic
records (`_control.aggregateRealtimeDiscard`) so replays remain aware of the
suppressed volume. `UyavaFileTransport` exposes asynchronous `flush` /
`dispose` hooks so callers can ensure buffers are persisted before shutdown.
The desktop host replays `.uyava` files to inspect captured sessions offline.
Subscribe to `Uyava.discardStatsStream` or poll `Uyava.latestDiscardStats` to
observe discard totals (per reason and in aggregate) while filters and
sampling are active.

`Uyava.exportCurrentArchive()` rotates the active file, copies the sealed
archive to `exports/`, and returns a `UyavaLogArchive` describing the snapshot
(path, size, timestamps). Use `Uyava.latestArchiveSnapshot()` when you need the
most recent sealed archive (exports included) without forcing a new rotation –
for example, to surface “share panic-tail” UI after a prior crash.
Export retention limits run after every copy (and once on startup) to delete
the oldest exports first while preserving the freshly shared archive.

`Uyava.cloneActiveArchive()` snapshots the in-progress archive without rotating
the worker. The clone lands in the same exports directory as manual shares, so
hosts can present “save latest log” affordances without interrupting the gzip
stream. Subscribe to `Uyava.archiveEvents` to receive a broadcast of every
sealed artifact (rotation, export, clone, panic seal, streaming journal
recovery) and mirror the list in real time inside your UI.

All heavy file IO (gzip, rotation, retention, exports) now runs inside a worker
isolate. The UI isolate only enqueues commands, so crash drills and high-volume
logging avoid frame jank. Panic mirroring performs a short synchronous append
to the JSONL companion before the worker completes the seal.

### Console logging

For lightweight visibility during development you can mirror all transport
events to stdout/stderr via `UyavaConsoleLogger`. Enable it once the SDK is
initialised:

```dart
final UyavaConsoleLogger logger = Uyava.enableConsoleLogging(
  config: UyavaConsoleLoggerConfig(
    minLevel: UyavaSeverity.info,
    colorMode: UyavaConsoleColorMode.auto, // auto-detects ANSI support
    includeTypes: const <String>{},        // optional allow-list
    excludeTypes: const <String>{},        // optional block-list
  ),
  diagnosticsStream: graphController.diagnosticsStream, // optional
);
```

The logger buffers up to `bufferCapacity` records (default 512) and flushes on a
short interval using drop-oldest eviction when the queue is full. Each record is
rendered as a compact line (`timestamp LEVEL type code [subjects] - message
key=value`) with optional ANSI colouring. Passing the core
`GraphController.diagnosticsStream` (when available) ensures integrity warnings reach the console
alongside transport events. When console output is no longer required call
`await Uyava.disableConsoleLogging()` to flush pending lines and detach from the
transport tap.

### Panic tail & global error handlers

`UyavaFileTransport` exposes `logRuntimeError`, and `UyavaBootstrap` wires it up to Flutter, platform, and zoned error hooks. When enabled, uncaught failures now persist a structured panic tail before control returns to the original handlers.

- Panic tails emit a `runtimeError` record (NDJSON line) with `timestamp`, `level`, `errorType`, `message`, `stackTrace`, `isFatal`, `source`, `platform`, process/isolates, zone description, and any harvested `FlutterErrorDetails` context.
- Handlers remain **opt-in**. Call `UyavaBootstrap.installGlobalErrorHandlers` once the file transport is ready and pass `UyavaGlobalErrorOptions` to decide which sources to wrap, whether to delegate to existing handlers, and the maximum flush timeout (default 500 ms). An optional isolate error listener (`enableIsolateErrors`) exposes `UyavaBootstrap.isolateErrorPort` and `attachIsolateErrorListener` so spawned isolates can forward uncaught failures; setting `captureCurrentIsolateErrors` guards the main isolate when apps skip `UyavaBootstrap.runZoned`, and `autoGuardZone` will auto-attach a listener + warning when no guarded zone is present. `UyavaBootstrap.runZoned` still provides the convenience wrapper around `runApp` for capturing asynchronous errors via `runZonedGuarded`.
- Each panic attempt triggers `transport.flush()` with the configured timeout; if flushing fails or times out, Uyava logs a warning but does not block the crash path. `UyavaBootstrap.runZoned` now awaits that flush before the error propagates so panic tails land reliably even during process teardown. Fatal propagation also raises a `ServicesBinding.exitApplication(AppExitType.cancelable)` request and falls back to a required exit; this gives hosts a single place (e.g. `AppLifecycleListener.onExitRequested`) to finish flushing transports before the process terminates.
- Crash-safe persistence (disabled by default) keeps a plain-text `panic-tail.jsonl`
  mirror in the logging directory and seals the gzip archive right after the
  panic flush. Enable it via `UyavaFileLoggerConfig.crashSafePersistence` when
  you need a readable fallback even if the process dies before the worker can
  reopen the compressed stream. Customize the mirror name/path with
  `panicMirrorFileName`.
- Streaming journaling (`streamingJournalEnabled`) keeps a continuously flushed
  NDJSON companion for the active session so forced kills still leave a
  readable trace. On startup the worker promotes any orphaned journal into a
  sealed `.uyava` archive before writing a fresh header, keeping the catalogue
  tidy and preserving the previous run.
- Breadcrumb buffering remains on the roadmap. Future iterations will add a `PanicTailPolicy` that appends the last N events; today the panic record focuses on terminal error metadata only.

API surface summary:
- `UyavaBootstrap.installGlobalErrorHandlers({ required UyavaFileTransport transport, UyavaGlobalErrorOptions options = const UyavaGlobalErrorOptions(), })` installs the shared hooks and returns a `UyavaGlobalErrorHandle` with `dispose()` to restore previous handlers.
- `UyavaBootstrap.runZoned(…)` wraps application entrypoints (`runApp`) to wire `runZonedGuarded`, capture uncaught async errors, and forward them to the shared handler before falling back to the original zone logic. The helper returns a `Future` that completes only after panic-tail logging finishes, so call sites should `await` it in `main()`.
- `UyavaGlobalErrorOptions` toggles individual sources (`enableFlutterError`, `enablePlatformDispatcher`, `enableZonedErrors`, `enableIsolateErrors`, `captureCurrentIsolateErrors`), controls bounded flushing (`flushTimeout`), and exposes behavioural flags such as `propagateToZone` (default `true`), `delegateOriginalHandlers` (default `true`), whether to emit diagnostics for non-fatal captures (`emitNonFatalDiagnostics`, default `true`), and `autoGuardZone` (attach isolate listener + warning when no runZoned wrapper exists).
- `PanicTailPolicy` will configure breadcrumb buffering in a later milestone; it is not yet available.

Example usage:

```dart
void main() async {
  final transport = await Uyava.enableFileLogging();

  await UyavaBootstrap.runZoned(
    () => runApp(const MyApp()),
    transport: transport,
    options: const UyavaGlobalErrorOptions(
      propagateToZone: true,
      delegateOriginalHandlers: true,
    ),
  );
}
```

These notes capture the current behaviour (panic record + bounded flush) and flag the remaining backlog item (breadcrumb buffering) so downstream hosts know what to expect as the feature evolves.

## Diagnostics

The SDK ships with graph integrity validation that surfaces issues via the
`graphDiagnostics` event. Diagnostics follow the policies enumerated in
`AGENTS.md` and mirror the severity table defined for the audit team. Connect a
host that listens to `UyavaTransportScope.diagnostic` events to display or store
those warnings and errors.

## Development

- Run `flutter analyze` from the repo root to keep all packages warning-free.
- Execute `melos run test` to run the shared test harness across packages.
- Format code using `dart format .` (2-space indent) before sending a change.

## License

This package is distributed under the terms of the MIT license. See `LICENSE`
for details.
