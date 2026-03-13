---
layout: ../../layouts/DocsLayout.astro
title: "Getting Started"
description: "Learn what Uyava is and how to start exploring your app."
---

# Getting Started

Uyava is a developer tool for Flutter that turns architecture and runtime activity into a live 2D graph. You can use it in three ways:

- DevTools Extension (Free, open source): runs inside Flutter DevTools for live inspection.
- Desktop App (Free): same graph with better performance, IDE integration, and basic recording + preview.
- Desktop Pro (Paid upgrade): advanced replay controls for long sessions and deeper navigation of .uyava logs.

If you are new to Uyava, start with DevTools or the free desktop app and connect it to a running Flutter app.

## Real-world OSS example

If you want to see Uyava in a familiar open-source codebase, check the
[`localsend-uyava` fork](https://github.com/alex-marochko/localsend-uyava).
It shows Uyava integrated into LocalSend as a practical example of using the SDK
in a popular OSS Flutter project.

## Quick start for Flutter apps

1) Add the SDK:

```bash
flutter pub add uyava
```

2) Initialize Uyava and send a snapshot early:

```dart
import 'package:flutter/widgets.dart';
import 'package:uyava/uyava.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Uyava.initialize();

  Uyava.replaceGraph(
    nodes: const [
      UyavaNode(id: 'ui.login', type: 'screen', label: 'Login', tags: ['ui']),
      UyavaNode(id: 'logic.auth', type: 'service', label: 'Auth', tags: ['auth']),
    ],
    edges: const [
      UyavaEdge(id: 'ui.login->logic.auth', from: 'ui.login', to: 'logic.auth'),
    ],
  );

  runApp(const MyApp());
}
```

3) Emit runtime events:

```dart
Uyava.emitNodeEvent(
  nodeId: 'logic.auth',
  message: 'Sign in pressed',
  severity: UyavaSeverity.info,
);

Uyava.emitEdgeEvent(
  edge: 'ui.login->logic.auth',
  message: 'Auth request dispatched',
  severity: UyavaSeverity.info,
);
```

4) Optional: keep your usual console logs while using Uyava:

```dart
Uyava.enableConsoleLogging(
  config: UyavaConsoleLoggerConfig(minLevel: UyavaSeverity.info),
);
```

This mirrors Uyava events into the standard app console and does not replace DevTools/Desktop views.

## Connect a host

- DevTools: run your app in debug or profile, open Flutter DevTools, and select the Uyava extension tab. The extension listens to VM Service events, so it works without extra network setup.
- Desktop: launch the desktop app and paste the VM Service URI from your running app. The desktop host mirrors the same data model as DevTools.

## Fast path for AI coding agents

If you use Cursor, Copilot, Claude, or similar tools, share this page with your agent:

- [LLM Integration Spec (Agents)](/docs/llm-assistant)

It provides concentrated Uyava API patterns and guardrails so the agent can instrument your feature/code area without inventing SDK syntax.

## Next steps

- Review the UI workflow in [Quick Tour](/docs/quick-tour).
- Learn how filtering affects the graph, metrics, chains, and journal in [Filters, Focus, and Grouping](/docs/concepts-filtering).
- If you need offline replays, read [Recording and .uyava Logs](/docs/recording-logs).
- For API details, console mirroring options, and transport rules, see [SDK Integration](/docs/sdk-integration) and [Under the Hood](/docs/architecture).
