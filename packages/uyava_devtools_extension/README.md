# Uyava DevTools Extension (Internal)

This package contains the Flutter DevTools extension UI for Uyava.

It is **not published directly** to pub.dev (`publish_to: none`).
End users should add only `uyava`:

```bash
flutter pub add uyava
```

The built web extension bundle from this package is copied into:
`packages/uyava/extension/devtools/`

That bundled output is what gets shipped with the `uyava` package.

## Purpose

- Host UI for graph, journal, diagnostics, metrics, and chains in DevTools.
- Reads Uyava SDK events through VM Service.
- Serves as the source project for generating the web extension assets.

## Build And Sync Workflow

Run from repository root:

```bash
bash tool/build_devtools_extension.sh
```

What the script does:

1. Syncs extension version from `uyava_devtools_extension/pubspec.yaml` to
   `uyava/extension/devtools/config.yaml`.
2. Regenerates extension version constants.
3. Builds web assets for this package.
4. Copies built assets into `packages/uyava/extension/devtools`.

After running it, verify that `packages/uyava/extension/devtools/build/` is
present and updated.

## Publish Model

- `uyava_devtools_extension`: internal package, not published.
- `uyava`: public package, includes the extension bundle under
  `extension/devtools/build`.

Before publishing `uyava`, run:

```bash
cd packages/uyava
dart pub publish --dry-run
```

The file list must include `extension/devtools/build/*`.

## Platform Notes

- Build scripts are Bash-based.
- On Windows, use WSL or Git Bash for `bash tool/build_devtools_extension.sh`.

## Source Docs

User-facing docs are on the site:

- https://uyava.io/docs/getting-started
- https://uyava.io/docs/sdk-integration
- https://uyava.io/docs/recording-logs

## License

MIT. See [LICENSE](LICENSE).
