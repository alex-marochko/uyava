# Uyava

<p>
  <img src="https://raw.githubusercontent.com/alex-marochko/uyava/main/packages/uyava_devtools_extension/doc/assets/uyava_logo_with_text_universal.png" alt="Uyava logo" width="200" />
</p>

Visual event graph and debugging toolkit for Flutter apps.

Uyava turns runtime events into a live map of your app.

![Uyava DevTools graph screenshot](https://raw.githubusercontent.com/alex-marochko/uyava/main/packages/uyava_devtools_extension/doc/assets/devtools-screenshot.png)

It acts as:
- visual debugging tool
- living documentation of your architecture
- a new way to understand your app beyond traditional logs

What Uyava helps you see
- your app architecture in motion
- event chains and happy flows
- module lifecycle
- key app metrics
- relationships between components

Status: Public Beta.

## Uyava OSS Workspace

This repository contains the open-source Uyava modules:
- app-side SDK (`uyava`)
- protocol models (`uyava_protocol`)
- shared core/domain logic (`uyava_core`)
- shared Flutter UI (`uyava_ui`)
- DevTools extension (`uyava_devtools_extension`)
- example app (`uyava_example`)
- website/docs (`site/`)
- IDE launcher plugins (`tools/ide_plugins/`)

## Repository Layout

- `packages/uyava_protocol` — wire-format models, validation helpers, protocol constants.
- `packages/uyava_core` — graph domain/controller/services (depends on `uyava_protocol`).
- `packages/uyava_ui` — shared Flutter graph UI and panels (depends on `uyava_core` + `uyava_protocol`).
- `packages/uyava` — app-side SDK for emitting nodes/edges/events/metrics (depends on `uyava_protocol`).
- `packages/uyava_devtools_extension` — Flutter DevTools extension host UI (depends on `uyava_core` + `uyava_ui` + `uyava_protocol`).
- `examples/uyava_example` — integration/smoke demo app (depends on `uyava`).
- `site/` — public website + docs.
- `tool/` — workspace scripts (`run_package_tests.sh`, version generation, DevTools build helper).

## Package Dependency Graph

```text
uyava_protocol
├─ uyava_core
│  └─ uyava_ui
├─ uyava
└─ uyava_devtools_extension (also depends on uyava_core + uyava_ui)

uyava_example -> uyava
```

## Prerequisites

- Flutter beta channel (workspace SDK constraint is currently `^3.10.0-75.1.beta`).
- Dart SDK that ships with the matching Flutter toolchain.

## Quick Start

From repo root:

```bash
dart pub get
dart run melos run test
```

The `test` script auto-selects `dart test` vs `flutter test` per package.

## DevTools Extension Build

Build and copy extension assets into `packages/uyava/extension/devtools`:

```bash
dart run melos run build_devtools_extension
```

Equivalent direct command:

```bash
bash tool/build_devtools_extension.sh
```

## Version Bumps

Version constants are generated from package `pubspec.yaml` versions:

```bash
# default target in OSS is devtools
dart run tool/generate_extension_versions.dart

# explicit target
dart run tool/generate_extension_versions.dart devtools
```

This updates:
- `packages/uyava_devtools_extension/lib/src/version.g.dart`

## CI

GitHub Actions workflow:
- `.github/workflows/packages_ci.yml`

It runs workspace dependency resolution and package tests for `packages/**` and `examples/**`.
