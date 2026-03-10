# Uyava Protocol

`uyava_protocol` is a pure Dart package with shared wire-level contracts for
Uyava SDK/hosts. It contains canonical event type names, payload models,
normalization helpers, validation helpers, and session-file contract types for
`.uyava` record/replay logs.

## What is in this package

- Canonical event/type enums:
  - `UyavaEventTypes`
  - `UyavaSeverity`
  - `UyavaLifecycleState`
  - filter/metric enums (`UyavaFilter*`, `UyavaMetricAggregator`)
- Wire payload models:
  - graph: `UyavaGraphNodePayload`, `UyavaGraphEdgePayload`
  - runtime events: `UyavaGraphNodeEventPayload`, `UyavaGraphEdgeEventPayload`
  - diagnostics: `UyavaGraphDiagnosticPayload`
  - metrics/chains/filters: `UyavaMetricDefinitionPayload`,
    `UyavaMetricSamplePayload`, `UyavaEventChainDefinitionPayload`,
    `UyavaGraphFilterCommandPayload`
  - replay wrapper: `UyavaReplayEnvelopePayload`
- Session archive contract (`.uyava`): `UyavaSessionHeader`,
  `UyavaSessionEventRecord`, `UyavaSessionMarkerRecord`,
  `UyavaSessionControlRecord`, `UyavaSessionFormatAdapter`
- Data normalization and validation helpers used across SDK/hosts.

## Usage

```dart
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  final nodeResult = UyavaGraphNodePayload.sanitize({
    'id': 'auth.service',
    'type': 'service',
    'label': 'Auth Service',
    'tags': ['Auth', 'backend'],
    'color': '#ff00aa',
    'shape': 'hexagon',
  });

  final edgeResult = UyavaGraphEdgePayload.sanitize({
    'id': 'auth.service->auth.repo',
    'source': 'auth.service',
    'target': 'auth.repo',
  });

  if (!nodeResult.isValid || !edgeResult.isValid) {
    throw StateError('Invalid graph payload');
  }

  final header = UyavaSessionHeader(
    sessionId: 'sess-001',
    startedAt: DateTime.now().toUtc(),
    appName: 'Uyava Example',
    appVersion: '0.2.0',
  );

  final parsed = UyavaSessionFormatAdapter().parseHeader(
    Map<String, dynamic>.from(header.toJson()),
  );
  assert(parsed.sessionId == 'sess-001');
}
```

## Notes

- This package is intentionally Flutter-free and UI-agnostic.
- Snapshot edge fields are canonicalized as `source` / `target`.
- `publish_to: none` means the package is currently workspace-internal.

## Related docs

- Session file format: https://uyava.io/docs/session-file-format
- SDK integration reference: https://uyava.io/docs/sdk-integration
- Architecture overview: https://uyava.io/docs/architecture
- Repository: https://github.com/alex-marochko/uyava

## License

MIT — see `LICENSE`.
