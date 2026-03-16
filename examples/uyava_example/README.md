# Uyava Example App

This Flutter app exercises the Uyava SDK and provides quick manual scenarios for
verifying graph integrations during development.

## Running

```bash
cd examples/uyava_example
flutter run -d chrome   # or another supported device
```

Launch the Uyava DevTools extension or the desktop host and connect it to the
app to visualise updates in real time.

### File logging (desktop & mobile)

- On platforms with `dart:io` (macOS/Windows/Linux, Android, iOS) the example
  enables `Uyava.enableFileLogging()` at startup and prints the directory path
  (system temp by default) where `.uyava` archives are written. Each file is
  gzip-compressed NDJSON.
- After closing the app you can inspect a log with
  `gunzip -c <file>.uyava > log.ndjson` and view the resulting JSON lines.
- The app registers an `AppLifecycleListener` so closing the window, quitting
  the process, or suspending the app on mobile flushes the archive before exit.
- For production apps you can provide a stable path via `path_provider`
  (documents/cache directories) instead of the temp directory shown here.
- Panic-tail crash logging is enabled by default (with crash-safe persistence): the example installs global error handlers once the file transport is ready, wraps startup in `UyavaBootstrap.runZoned`, and keeps a JSONL mirror (`panic-tail.jsonl`) next to the `.uyava` archive so the panic record survives even if the gzip stream cannot reopen. Breadcrumb buffering remains on the backlog, so current panic records focus on terminal error metadata.
- Streaming journaling is enabled alongside panic tails: every event is duplicated
  into `panic-tail-active.jsonl`, flushed roughly every 250 ms, and any orphaned
  journal from a previous crash is promoted into a sealed `.uyava` archive on
  startup before the new session begins.
- Use the "Panic-tail archives and live log" card (Wrong data tab) to:
  - stream archive metadata in real time via `Uyava.archiveEvents`
    (rotations, exports, clones, panic seals, recovered journals);
  - snapshot the active archive without rotation through
    `Uyava.cloneActiveArchive()` ("Clone active log" button);
  - export-&-email the latest archive via `Uyava.exportCurrentArchive()` while
    opening the platform share sheet with the `.uyava` attachment.
- Adjust the "Minimum log level filter" dropdown (Wrong data tab) to
  restart the file transport with a stricter severity threshold so low-priority
  pulses (`trace`/`debug`, etc.) stay out of exported panic-tail archives.

### Console logging (enabled by default)

The example enables `Uyava.enableConsoleLogging()` during startup so every
transport event is echoed to stdout with ANSI-coloured severities. This makes it
easy to observe graph mutations, targeted events, and diagnostics without having
DevTools open. The default configuration keeps `minLevel` at `info`, so `trace`
and `debug` pulses are suppressed unless you lower the threshold in code.

To customise the behaviour, tweak `UyavaConsoleLoggerConfig` in
`lib/main.dart`—for example, change the minimum level or toggle colours. If you
prefer a quiet terminal, call `await Uyava.disableConsoleLogging()` during your
own teardown path to stop forwarding events.

## What to Try

- **Feature toggles** – Enable/disable feature groups via the switches. The app
  recalculates the graph with `Uyava.replaceGraph`, keeping lifecycle presets in
  sync.
- **Incremental graph mutations** (new):
  - `Add Test Node A/B` – emits `addNode` from two different call sites.
  - `Link last test nodes` – adds an adhoc edge between the two most recent test
    nodes.
  - `Remove last test edge` / `Remove last test node` – calls `removeEdge` and
    `removeNode` (with cascade) to validate selective pruning.
  - `Patch Auth Service` – toggles `Uyava.patchNode` to recolor and tag the
    service.
  - `Patch Auth edge` – toggles `Uyava.patchEdge` to update the Repo → Service
    connection metadata.
- **Lifecycle presets** – Apply subtree lifecycle changes to confirm hosts dim
  nodes appropriately.
- **Targeted events** – Use the tab to emit node/edge events with different
  severities.
- **Event chains** – The authentication tab still lets you simulate the login
  flow, while checkout and profile update chains are now registered
  automatically on startup. Use the success/failure buttons for each chain to
  exercise the Chains panel filters without manual setup.
- **Metrics tab** – Register custom metrics, inspect the built-in demo series
  (latency, success rates, etc.), and emit samples attached to specific nodes
  to watch the DevTools/Desktop dashboards update in real time. The automatic
  generator will also stream realistic samples while animations run.
- **Diagnostics** – The “Wrong data” tab triggers integrity failures so you can
  observe the diagnostic stream inside the host UI. Duplicate node ids emit a
  `nodes.duplicate_id` warning on the first click; reuse the same id with
  different tags to surface the additional `nodes.conflicting_tags` entry. The
  duplicate edge ids scenario reports a single `edges.duplicate_id` warning for
  the last writer.
- **Error hooks & panic-tail drills** – Use the Error hooks section in “Wrong
  data” to toggle isolate error forwarding, capture current-isolate async
  errors without `runZoned`, and enable/disable non-fatal diagnostics. Buttons
  cover “Spawn isolate crash”, “Async throw (no guard)”, overriding
  `FlutterError.onError` with `presentError`, and a non-fatal FlutterError
  path. The panel also shows the last panic-tail diagnostic (fatal flag +
  panic tail stats) so you can verify coverage quickly.
- **Crash drills** – In the same tab you can press “Crash via Flutter error” or
  “Crash via async error” to force a real exception path. Each crash closes the
  app, so restart between buttons if you want to exercise both flows. The
  example toggles the handlers back to delegating/propagating so the app runs
  the `ServicesBinding.exitApplication(AppExitType.cancelable)` handshake,
  flushes the panic tail (including the `panic-tail.jsonl` mirror) during
  `onExitRequested`, and then terminates. Use these to validate end-to-end
  crash capture and confirm that the next launch upgrades any lingering
  `panic-tail-active.jsonl` into a recovered `.uyava` snapshot.
- **Send panic-tail archive** – Press "Send log via email" to rotate the
  current archive, attach it to the default mail client via the platform share
  sheet, and share the panic-tail snapshot without restarting the app.

## Tests

```bash
flutter test examples/uyava_example/test/widget_test.dart
```

Use `melos run test` from the repo root to run the full suite across packages;
the command executes both `test/` and `integration_test/` suites for Flutter
targets.

When running the integration suite on macOS in sandboxed environments, pin the
environment so Flutter uses repo-local caches and temporary directories:

```bash
export HOME="$REPO_ROOT"
export PUB_CACHE="$REPO_ROOT/.tmp/.pub-cache"
export TMPDIR="$REPO_ROOT/.tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
export DART_DISABLE_ANALYTICS=true
flutter test -d macos integration_test/logging_clone_discard_test.dart
```

To target only the example app’s integration tests from this package directory:

```bash
cd examples/uyava_example
flutter test integration_test
```

### Integration scenarios

- `logging_export_test.dart` covers the export-and-share flow, including the live archive list refresh and mocked share sheet invocation.
- `logging_crash_recovery_test.dart` validates panic-tail recovery after a forced Flutter crash and ensures the recovered archive contains the panic payload.
- `logging_clone_discard_test.dart` scripts the “Clone active archive & discard stats” flow by lowering the minimum log level, generating suppressed pulses, asserting the discard counters in the Wrong data tab, cloning the active log, and verifying that the archive stream/UI reflect the cloned `.uyava` artifact.
