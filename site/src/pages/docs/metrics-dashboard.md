---
layout: ../../layouts/DocsLayout.astro
title: "Metrics Dashboard"
description: "Define metrics, record samples, and read aggregates."
---

# Metrics Dashboard

Metrics turn raw numeric signals into quick context. Uyava aggregates samples and renders cards with Last, Min, Max, Sum, Count, and Avg values.

## Define metrics

Define metrics once at startup so hosts can label and group them:

```dart
Uyava.defineMetric(
  id: 'auth.latency_ms',
  label: 'Auth latency',
  description: 'Time to complete login',
  unit: 'ms',
  tags: ['auth', 'latency'],
  aggregators: [
    UyavaMetricAggregator.last,
    UyavaMetricAggregator.max,
    UyavaMetricAggregator.sum,
    UyavaMetricAggregator.count,
  ],
);
```

## Record samples

Metric samples are carried inside node events. Include a `metric` payload:

```dart
Uyava.emitNodeEvent(
  nodeId: 'logic.auth',
  message: 'Auth latency sample',
  severity: UyavaSeverity.info,
  payload: {
    'metric': {'id': 'auth.latency_ms', 'value': 180},
  },
);
```

Optional `timestamp` can be supplied inside the metric payload. The host uses the event severity for coloring and diagnostics.

## Reading the dashboard

- Full mode shows a card per metric with sparklines and key aggregates.
- Compact mode lists the same aggregates in a dense table.
- Pins keep important metrics at the top.

Metrics respect the active graph filter set. Severity filtering does not hide metric cards so aggregates remain trustworthy during triage.
