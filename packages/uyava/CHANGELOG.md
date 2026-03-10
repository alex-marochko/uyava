## Unreleased

## 0.2.1-beta.1

- feat: add transport hub with pluggable transports and scoped event routing.
- docs: document the SDK transport API and usage.
- feat: support remove/patch node & edge mutations with diagnostics.
- refactor: reuse shared `dedupeById` validation helpers for node/edge merges to
  align duplicate diagnostics with `uyava_core`.
- fix: fatal error propagation now triggers the platform exit handshake so
  panic-tail logging flushes before the process terminates.
- feat: expose `Uyava.exportCurrentArchive` with rotate-and-export support for
  file transports.
- feat: add `minLevel` to `UyavaFileLoggerConfig` to filter low-severity
  payloads before writing archives.
- feat: move `UyavaFileTransport` IO to a worker isolate and add
  `crashSafePersistence` / `panicMirrorFileName` for panic-tail mirroring plus
  `Uyava.latestArchiveSnapshot()` for post-crash retrieval.
- feat: add streaming journal support via
  `UyavaFileLoggerConfig.streamingJournalEnabled` (`panic-tail-active.jsonl`)
  with automatic recovery into sealed `.uyava` archives on startup.
- feat: add export directory quotas (`maxExportCount`,
  `maxExportTotalBytes`) so repeated shares prune the oldest archives
  automatically.
- feat: surface discard statistics through `UyavaDiscardStats`,
  `Uyava.discardStatsStream`, and `Uyava.latestDiscardStats` so hosts can track
  filtered events in real time.
- feat: expose `Uyava.cloneActiveArchive` and the `Uyava.archiveEvents` stream
  so hosts can clone active panic-tail logs without rotation and react to
  rotation/export/clone/panic events in real time; the example app now mirrors
  the stream and offers a “clone active log” workflow.

## 0.0.1

- Initial release scaffold.
