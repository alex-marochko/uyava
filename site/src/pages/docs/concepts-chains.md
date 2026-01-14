---
layout: ../../layouts/DocsLayout.astro
title: "Event Chains"
description: "Follow causality with event chains and replay."
---

# Event Chains

Event chains describe multi-step flows (login, checkout, onboarding). Uyava tracks attempts in real time and surfaces progress in the Chains panel.

## Define a chain

```dart
Uyava.defineEventChain(
  id: 'auth.login_flow',
  label: 'Login flow',
  tags: ['auth'],
  steps: const [
    UyavaEventChainStep(stepId: 'open', nodeId: 'ui.login'),
    UyavaEventChainStep(stepId: 'submit', nodeId: 'logic.auth'),
    UyavaEventChainStep(stepId: 'success', nodeId: 'logic.auth'),
  ],
);
```

Rules:

- `id` must be unique and stable.
- `tags` are required; at least one tag must be present.
- Step IDs must be unique within the chain.

## Advance a chain

Chain progress is driven by node events that embed a `chain` payload:

```dart
Uyava.emitNodeEvent(
  nodeId: 'logic.auth',
  message: 'Auth submitted',
  payload: {
    'chain': {'id': 'auth.login_flow', 'step': 'submit', 'attempt': 'a1'},
    'edgeId': 'ui.login->logic.auth',
  },
);
```

Notes:

- `attempt` is optional. When omitted, Uyava starts a new attempt at the first step.
- Invalid chain IDs or steps emit diagnostics (for example `chains.unknown_id`).
- The Chains panel shows active attempts as chips and keeps completed runs in history.

## Failure modes

Chains can fail in two ways:

- **Explicit failure status**: set `chain.status` to `failed`/`failure` (case-insensitive). This marks the attempt as failed immediately.
- **Out-of-order steps**: starting from a non-first step or skipping expected steps fails the attempt.

Example status-based failure:

```dart
Uyava.emitNodeEvent(
  nodeId: 'logic.auth',
  message: 'Auth failed',
  payload: {
    'chain': {
      'id': 'auth.login_flow',
      'step': 'success',
      'attempt': 'a1',
      'status': 'failed',
    },
  },
);
```

Additional notes:

- Unknown chain IDs/steps or mismatched node/edge identifiers are ignored with diagnostics (they do not increment failure totals).
- `expectedSeverity` is metadata for UI display and does not affect pass/fail logic.

## Replay behavior

Desktop Pro replays chain attempts alongside the timeline. This makes it easier to follow causal paths in large logs.
