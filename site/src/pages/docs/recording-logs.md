---
layout: ../../layouts/DocsLayout.astro
title: "Recording and .uyava Logs"
description: "Record sessions, export logs, and replay offline."
---

# Recording and .uyava Logs

Uyava logs use the `.uyava` extension. Each file is a gzip-compressed NDJSON stream with a session header followed by event records.

You can inspect a file locally with:

```bash
gunzip -c session.uyava > session.ndjson
```

## Desktop recording

Desktop can record live sessions and save `.uyava` archives for replay.

Workflow:

1) Connect to a live VM Service session.
2) Start recording from the Record/Replay bar.
3) Save the recording to finalize a `.uyava` file.
4) Switch to File mode to replay the saved log.

Recording uses a ring buffer so long sessions remain manageable. Defaults:

- window duration: 5 minutes
- window size: 50 MB (pre-compression)

Older events are dropped as needed, and the UI shows drop counts so you know when the buffer trimmed.

### Where files are saved

Desktop saves recordings to a default directory. The app prefers:

- the last used recording folder
- the sandbox temp folder (when sandboxed)
- the configured output directory (if set)
- the system temp directory

After saving, the app can reveal the current recording in your file explorer.

## SDK file logging (record in your app)

To capture `.uyava` logs from your own app, enable file logging in the SDK:

```dart
import 'package:path_provider/path_provider.dart';
import 'package:uyava/uyava.dart';

Future<void> startLogging() async {
  final dir = await getApplicationDocumentsDirectory();
  await Uyava.enableFileLogging(
    config: UyavaFileLoggerConfig(
      directoryPath: dir.path,
      maxFileSizeBytes: 32 * 1024 * 1024,
      maxDuration: const Duration(minutes: 30),
      maxFileCount: 5,
      realtimeSamplingRate: 1.0,
      minLevel: UyavaSeverity.trace,
    ),
  );
}
```

Important notes:

- `directoryPath` is required. Use `path_provider` to pick a stable path.
- Files are gzip-compressed NDJSON with a `.uyava` extension.
- A background worker handles rotation and compression to avoid UI jank.

### Exporting logs

Use the SDK helpers to export or snapshot logs without stopping recording:

```dart
final archive = await Uyava.exportCurrentArchive();
final snapshot = await Uyava.cloneActiveArchive();
```

Exports are copied into an `exports/` subfolder inside the logging directory.

### Crash-safe logs (panic tail)

File logging supports crash-safe persistence. Enable it to mirror the last error into `panic-tail.jsonl` and seal the current archive after a fatal error. This is useful for collecting logs from end users after a crash.

## Replay basics

Desktop can open `.uyava` files directly (double-click or File mode). The playback timeline supports speed changes and event markers, and Pro adds advanced seek controls for long sessions.
